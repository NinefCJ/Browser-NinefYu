import 'dart:io';

/// 磁盘监控器
class StorageMonitor {
  final Directory targetDir;
  final double reservePercent;
  final int reserveMinBytes;

  StorageMonitor({
    required this.targetDir,
    this.reservePercent = 0.1,
    this.reserveMinBytes = 100 * 1024 * 1024,
  });

  /// 获取磁盘总空间
  int get totalBytes {
    try {
      final stat = FileSystemEntity.statSync(targetDir.path);
      return stat.size;
    } catch (_) {
      return -1;
    }
  }

  /// 获取安全可用空间（保留部分空间给系统）
  int get safeAvailableBytes {
    try {
      final stat = FileSystemEntity.statSync(targetDir.path);
      final available = stat.size;
      final reserved = (available * reservePercent).toInt();
      final minReserve = reserved.clamp(reserveMinBytes, available);
      return (available - minReserve).clamp(0, available);
    } catch (_) {
      return -1;
    }
  }

  /// 获取实际可用空间
  int get availableBytes {
    try {
      final stat = FileSystemEntity.statSync(targetDir.path);
      return stat.size;
    } catch (_) {
      return -1;
    }
  }

  /// 检查空间是否足够
  bool hasEnoughSpace(int requiredBytes) {
    final available = safeAvailableBytes;
    if (available <= 0) return true;
    return available >= requiredBytes;
  }

  /// 下载过程中的空间保护
  /// 每 50MB 检查一次
  void guard(int totalBytes, int bytesWritten) {
    const checkInterval = 50 * 1024 * 1024;
    if (bytesWritten > 0 && bytesWritten % checkInterval < 16384) {
      final remaining = (totalBytes - bytesWritten).clamp(0, totalBytes);
      if (totalBytes > 0 && safeAvailableBytes < remaining) {
        throw StorageException('磁盘空间不足，剩余空间不足以完成下载');
      }
    }
  }

  /// 获取指定目录已使用空间
  int directorySize(Directory dir) {
    if (!dir.existsSync()) return 0;
    var total = 0;
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          total += entity.lengthSync();
        }
      }
    } catch (_) {}
    return total;
  }

  /// 格式化字节数为可读格式
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}

/// 速度限制器（令牌桶算法）
class SpeedLimiter {
  final int maxBytesPerSec;
  int _available = 0;
  DateTime _lastRefill = DateTime.now();
  int _totalThrottled = 0;

  SpeedLimiter(this.maxBytesPerSec);

  /// 节流控制
  Future<void> throttle(int bytes) async {
    if (maxBytesPerSec <= 0) return;

    _refill();

    while (_available < bytes) {
      final deficit = bytes - _available;
      final waitMs = (deficit * 1000 / maxBytesPerSec).ceil();
      await Future.delayed(Duration(milliseconds: waitMs));
      _refill();
    }

    _available -= bytes;
  }

  /// 补充令牌
  void _refill() {
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastRefill).inMilliseconds;
    if (elapsedMs > 0) {
      _available += (maxBytesPerSec * elapsedMs / 1000).toInt();
      _available = _available.clamp(0, maxBytesPerSec * 2);
      _lastRefill = now;
    }
  }

  /// 重置
  void reset() {
    _available = 0;
    _lastRefill = DateTime.now();
    _totalThrottled = 0;
  }

  /// 格式化速度
  static String formatSpeed(int bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = 0;
    double speed = bytesPerSec.toDouble();
    while (speed >= 1024 && i < suffixes.length - 1) {
      speed /= 1024;
      i++;
    }
    return '${speed.toStringAsFixed(2)} ${suffixes[i]}';
  }
}

/// 文件系统兼容工具
class FileSystemCompat {
  static const int fat32MaxFileSize = 4 * 1024 * 1024 * 1024; // 4GB

  /// 检查文件系统类型
  static Future<FileSystemType> detectFileSystem(String path) async {
    return FileSystemType.generic;
  }

  /// 生成分卷文件名
  static List<String> generateVolumeNames(String baseName, int count) {
    final names = <String>[];
    final dotIndex = baseName.lastIndexOf('.');
    String name;
    String ext;
    if (dotIndex > 0) {
      name = baseName.substring(0, dotIndex);
      ext = baseName.substring(dotIndex);
    } else {
      name = baseName;
      ext = '';
    }

    for (var i = 1; i <= count; i++) {
      names.add('$name.part${i.toString().padLeft(3, '0')}$ext');
    }
    return names;
  }

  /// 计算分卷数量
  static int calculateVolumeCount(int totalBytes, {int maxVolumeSize = fat32MaxFileSize}) {
    if (totalBytes <= maxVolumeSize) return 1;
    return (totalBytes / maxVolumeSize).ceil();
  }

  /// 合并分卷文件
  static Future<void> mergeVolumes(List<String> volumePaths, String outputPath) async {
    final output = File(outputPath);
    final sink = output.openWrite(mode: FileMode.writeOnly);

    try {
      for (final path in volumePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          sink.add(bytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// 分割文件为多卷
  static Future<void> splitFile(String inputPath, String outputDir, int maxVolumeSize) async {
    final input = File(inputPath);
    final totalSize = await input.length();
    final volumeCount = calculateVolumeCount(totalSize, maxVolumeSize: maxVolumeSize);

    final baseName = input.uri.pathSegments.last;
    final volumeNames = generateVolumeNames(baseName, volumeCount);

    final raf = await input.open();
    try {
      var offset = 0;
      for (var i = 0; i < volumeCount; i++) {
        final volumePath = '$outputDir/${volumeNames[i]}';
        final volumeFile = File(volumePath);
        final volumeSink = volumeFile.openWrite();

        var remaining = maxVolumeSize;
        const chunkSize = 8192;

        while (remaining > 0 && offset < totalSize) {
          final readSize = chunkSize < remaining ? chunkSize : remaining;
          final bytes = List<int>.filled(readSize, 0);
          final actualRead = await raf.readInto(bytes);
          if (actualRead <= 0) break;
          volumeSink.add(bytes.sublist(0, actualRead));
          offset += actualRead;
          remaining -= actualRead;
        }

        await volumeSink.close();
      }
    } finally {
      await raf.close();
    }
  }
}

enum FileSystemType {
  generic,
  fat32,
  ntfs,
  ext4,
  apfs,
}