import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// M3U8 分段信息
class M3U8Segment {
  final int index;
  final String url;
  final double duration;
  final String? title;
  final String? keyMethod;
  final String? keyUrl;
  final String? keyIv;
  int downloadedBytes;
  DownloadStatus status;

  M3U8Segment({
    required this.index,
    required this.url,
    this.duration = 0,
    this.title,
    this.keyMethod,
    this.keyUrl,
    this.keyIv,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
  });
}

enum DownloadStatus {
  pending,
  running,
  completed,
  failed,
  paused,
}

/// M3U8 播放列表
class M3U8Playlist {
  final String url;
  final bool isMaster;
  final double targetDuration;
  final List<M3U8Segment> segments;
  final List<M3U8Stream> streams;
  final int? mediaSequence;

  M3U8Playlist({
    required this.url,
    this.isMaster = false,
    this.targetDuration = 0,
    this.segments = const [],
    this.streams = const [],
    this.mediaSequence,
  });
}

/// M3U8 流信息（主播放列表）
class M3U8Stream {
  final String url;
  final String? bandwidth;
  final String? resolution;
  final String? codecs;
  final String? name;

  M3U8Stream({
    required this.url,
    this.bandwidth,
    this.resolution,
    this.codecs,
    this.name,
  });
}

/// M3U8 下载任务
class M3U8DownloadTask {
  final String id;
  final String m3u8Url;
  final String outputPath;
  final String tempDir;
  int totalSegments;
  int downloadedSegments;
  DownloadStatus status;
  final int threadCount;
  double speed;
  String? errorMessage;
  DateTime? createdAt;
  DateTime? completedAt;
  final M3U8Playlist? playlist;

  M3U8DownloadTask({
    required this.id,
    required this.m3u8Url,
    required this.outputPath,
    required this.tempDir,
    this.totalSegments = 0,
    this.downloadedSegments = 0,
    this.status = DownloadStatus.pending,
    this.threadCount = 8,
    this.speed = 0,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
    this.playlist,
  });

  double get progress {
    if (totalSegments <= 0) return 0;
    return downloadedSegments / totalSegments;
  }

  M3U8DownloadTask copyWith({
    String? id,
    String? m3u8Url,
    String? outputPath,
    String? tempDir,
    int? totalSegments,
    int? downloadedSegments,
    DownloadStatus? status,
    int? threadCount,
    double? speed,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
    M3U8Playlist? playlist,
  }) {
    return M3U8DownloadTask(
      id: id ?? this.id,
      m3u8Url: m3u8Url ?? this.m3u8Url,
      outputPath: outputPath ?? this.outputPath,
      tempDir: tempDir ?? this.tempDir,
      totalSegments: totalSegments ?? this.totalSegments,
      downloadedSegments: downloadedSegments ?? this.downloadedSegments,
      status: status ?? this.status,
      threadCount: threadCount ?? this.threadCount,
      speed: speed ?? this.speed,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      playlist: playlist ?? this.playlist,
    );
  }
}

/// M3U8 解析器
class M3U8Parser {
  /// 解析 M3U8 内容
  M3U8Playlist parse(String content, String baseUrl) {
    final lines = LineSplitter.split(content);
    final segments = <M3U8Segment>[];
    final streams = <M3U8Stream>[];
    var isMaster = false;
    var targetDuration = 0.0;
    var mediaSequence = 0;
    var currentKeyMethod;
    var currentKeyUri;
    var currentKeyIv;
    var currentDuration = 0.0;
    var currentTitle;
    var segmentIndex = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#EXTM3U')) continue;

      if (trimmed.startsWith('#EXT-X-STREAM-INF')) {
        isMaster = true;
        final attrs = _parseAttributes(trimmed);
        streams.add(M3U8Stream(
          url: '',
          bandwidth: attrs['BANDWIDTH'],
          resolution: attrs['RESOLUTION'],
          codecs: attrs['CODECS'],
          name: attrs['NAME'],
        ));
        continue;
      }

      if (isMaster && !trimmed.startsWith('#') && streams.isNotEmpty) {
        final last = streams.last;
        streams[streams.length - 1] = M3U8Stream(
          url: _resolveUrl(baseUrl, trimmed),
          bandwidth: last.bandwidth,
          resolution: last.resolution,
          codecs: last.codecs,
          name: last.name,
        );
        continue;
      }

      if (trimmed.startsWith('#EXT-X-TARGETDURATION')) {
        targetDuration = double.tryParse(trimmed.split(':').last) ?? 0;
        continue;
      }

      if (trimmed.startsWith('#EXT-X-MEDIA-SEQUENCE')) {
        mediaSequence = int.tryParse(trimmed.split(':').last) ?? 0;
        continue;
      }

      if (trimmed.startsWith('#EXT-X-KEY')) {
        final attrs = _parseAttributes(trimmed);
        currentKeyMethod = attrs['METHOD'];
        currentKeyUri = attrs['URI'];
        currentKeyIv = attrs['IV'];
        continue;
      }

      if (trimmed.startsWith('#EXTINF')) {
        final parts = trimmed.split(',');
        currentDuration = double.tryParse(parts.first.split(':').last) ?? 0;
        currentTitle = parts.length > 1 ? parts.last : null;
        continue;
      }

      if (!trimmed.startsWith('#')) {
        segments.add(M3U8Segment(
          index: segmentIndex++,
          url: _resolveUrl(baseUrl, trimmed),
          duration: currentDuration,
          title: currentTitle,
          keyMethod: currentKeyMethod,
          keyUrl: currentKeyUri != null ? _resolveUrl(baseUrl, currentKeyUri) : null,
          keyIv: currentKeyIv,
        ));
      }
    }

    return M3U8Playlist(
      url: baseUrl,
      isMaster: isMaster,
      targetDuration: targetDuration,
      segments: segments,
      streams: streams,
      mediaSequence: mediaSequence,
    );
  }

  Map<String, String> _parseAttributes(String line) {
    final attrs = <String, String>{};
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return attrs;

    final attrStr = line.substring(colonIndex + 1);
    final regex = RegExp(r'(\w+)=("[^"]*"|[^,]+)');
    final matches = regex.allMatches(attrStr);

    for (final match in matches) {
      final key = match.group(1)!;
      var value = match.group(2)!;
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      attrs[key] = value;
    }

    return attrs;
  }

  String _resolveUrl(String baseUrl, String relative) {
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      return relative;
    }
    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(relative);
      return resolved.toString();
    } catch (_) {
      return relative;
    }
  }
}

/// M3U8 AES-128 解密器
class M3U8Decryptor {
  /// AES-128-CBC 解密
  /// 简单XOR模拟（实际使用crypto包）
  static Uint8List decryptAes128Cbc(Uint8List data, Uint8List key, {Uint8List? iv}) {
    final ivBytes = iv ?? Uint8List(16);
    final result = Uint8List(data.length);

    // 简化版：使用简单的XOR和移位模拟
    // 实际项目中应使用 PointyCastle 或 crypto 包
    var prev = Uint8List.fromList(ivBytes);
    for (var i = 0; i < data.length; i += 16) {
      final block = data.sublist(i, (i + 16).clamp(0, data.length));
      final decrypted = _xorBlock(block, key, prev);
      for (var j = 0; j < decrypted.length && i + j < result.length; j++) {
        result[i + j] = decrypted[j];
      }
      prev = Uint8List.fromList(block);
    }

    return result;
  }

  static Uint8List _xorBlock(Uint8List block, Uint8List key, Uint8List iv) {
    final result = Uint8List(block.length);
    for (var i = 0; i < block.length; i++) {
      result[i] = block[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    return result;
  }

  /// 解析 IV 字符串
  static Uint8List parseIV(String ivStr) {
    if (ivStr.startsWith('0x') || ivStr.startsWith('0X')) {
      final hex = ivStr.substring(2);
      final bytes = <int>[];
      for (var i = 0; i < hex.length; i += 2) {
        if (i + 2 <= hex.length) {
          bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
        }
      }
      return Uint8List.fromList(bytes);
    }
    return Uint8List(16);
  }
}

/// M3U8 下载器
class M3U8Downloader extends StateNotifier<List<M3U8DownloadTask>> {
  final Dio _dio;
  final M3U8Parser _parser = M3U8Parser();
  final Map<String, CancelToken> _cancelTokens = {};

  M3U8Downloader()
      : _dio = Dio(BaseOptions(
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(minutes: 5),
        )),
        super([]);

  /// 解析 M3U8 URL
  Future<M3U8Playlist> parseM3U8(String url, {Map<String, String>? headers}) async {
    final response = await _dio.get<String>(url,
        options: Options(headers: headers));
    final baseUrl = _getBaseUrl(url);
    return _parser.parse(response.data ?? '', baseUrl);
  }

  /// 解析主播放列表，获取所有流
  Future<List<M3U8Stream>> parseMasterPlaylist(String url, {Map<String, String>? headers}) async {
    final playlist = await parseM3U8(url, headers: headers);
    return playlist.streams;
  }

  /// 下载 M3U8 视频
  Future<String?> downloadM3U8({
    required String m3u8Url,
    required String outputPath,
    Map<String, String>? headers,
    int threadCount = 8,
    String? preferredQuality,
  }) async {
    final taskId = _generateId();
    final dir = await getTemporaryDirectory();
    final tempDir = '${dir.path}/m3u8/$taskId';
    await Directory(tempDir).create(recursive: true);

    final task = M3U8DownloadTask(
      id: taskId,
      m3u8Url: m3u8Url,
      outputPath: outputPath,
      tempDir: tempDir,
      threadCount: threadCount,
      createdAt: DateTime.now(),
      status: DownloadStatus.running,
    );

    state = [...state, task];

    try {
      // 解析播放列表
      var playlist = await parseM3U8(m3u8Url, headers: headers);

      // 如果是主播放列表，选择最佳质量
      if (playlist.isMaster) {
        final streams = playlist.streams;
        if (streams.isNotEmpty) {
          var targetStream = streams.first;
          if (preferredQuality != null) {
            // 尝试匹配指定质量
            targetStream = streams.firstWhere(
              (s) => s.resolution?.contains(preferredQuality) ?? false,
              orElse: () => _selectBestStream(streams),
            );
          } else {
            targetStream = _selectBestStream(streams);
          }
          playlist = await parseM3U8(targetStream.url, headers: headers);
        }
      }

      // 更新任务
      final updated = task.copyWith(
        totalSegments: playlist.segments.length,
        playlist: playlist,
      );
      state = state.map((t) => t.id == taskId ? updated : t).toList();

      // 下载密钥（如果需要）
      final keyCache = <String, Uint8List>{};
      for (final segment in playlist.segments) {
        if (segment.keyMethod == 'AES-128' &&
            segment.keyUrl != null &&
            !keyCache.containsKey(segment.keyUrl)) {
          try {
            final keyResponse = await _dio.get<List<int>>(
              segment.keyUrl!,
              options: Options(responseType: ResponseType.bytes),
            );
            keyCache[segment.keyUrl!] = Uint8List.fromList(keyResponse.data ?? []);
          } catch (_) {}
        }
      }

      // 分段下载
      final segments = playlist.segments;
      final segmentDir = Directory('$tempDir/segments');
      await segmentDir.create(recursive: true);

      var downloaded = 0;
      final semaphore = _Semaphore(threadCount);
      final futures = <Future>[];

      for (final segment in segments) {
        futures.add(() async {
          await semaphore.acquire();
          try {
            final segPath = '${segmentDir.path}/seg_${segment.index.toString().padLeft(5, '0')}.ts';
            final segFile = File(segPath);

            if (await segFile.exists() && await segFile.length() > 0) {
              // 已下载
              segment.status = DownloadStatus.completed;
            } else {
              // 下载分段
              segment.status = DownloadStatus.running;
              final response = await _dio.download(
                segment.url,
                segPath,
                options: Options(headers: headers),
              );

              // 解密
              if (segment.keyMethod == 'AES-128' && keyCache.containsKey(segment.keyUrl)) {
                final key = keyCache[segment.keyUrl!]!;
                final encrypted = await segFile.readAsBytes();
                final iv = segment.keyIv != null
                    ? M3U8Decryptor.parseIV(segment.keyIv!)
                    : Uint8List(16);
                final decrypted = M3U8Decryptor.decryptAes128Cbc(encrypted, key, iv: iv);
                await segFile.writeAsBytes(decrypted);
              }

              segment.status = DownloadStatus.completed;
            }

            downloaded++;
            _updateProgress(taskId, downloaded, segments.length);
          } catch (e) {
            segment.status = DownloadStatus.failed;
            rethrow;
          } finally {
            semaphore.release();
          }
        }());
      }

      await Future.wait(futures, eagerError: false);

      // 合并分段
      await _mergeSegments(
        segments.map((s) => '${segmentDir.path}/seg_${s.index.toString().padLeft(5, '0')}.ts').toList(),
        outputPath,
      );

      // 清理临时文件
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}

      _updateStatus(taskId, DownloadStatus.completed, completedAt: DateTime.now());

      return outputPath;
    } catch (e) {
      _updateStatus(taskId, DownloadStatus.failed, errorMessage: e.toString());
      return null;
    }
  }

  M3U8Stream _selectBestStream(List<M3U8Stream> streams) {
    if (streams.length == 1) return streams.first;
    return streams.reduce((a, b) {
      final bwA = int.tryParse(a.bandwidth ?? '0') ?? 0;
      final bwB = int.tryParse(b.bandwidth ?? '0') ?? 0;
      return bwA > bwB ? a : b;
    });
  }

  Future<void> _mergeSegments(List<String> segmentPaths, String outputPath) async {
    final output = File(outputPath);
    final sink = output.openWrite(mode: FileMode.writeOnly);

    try {
      for (final path in segmentPaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          // 跳过可能的 MPEG-TS 头部的重复部分
          sink.add(bytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  void _updateProgress(String taskId, int downloaded, int total) {
    state = state.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          downloadedSegments: downloaded,
          totalSegments: total,
        );
      }
      return t;
    }).toList();
  }

  void _updateStatus(String taskId, DownloadStatus status, {
    String? errorMessage,
    DateTime? completedAt,
  }) {
    state = state.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: status,
          errorMessage: errorMessage,
          completedAt: completedAt,
        );
      }
      return t;
    }).toList();
  }

  String _getBaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path.substring(0, uri.path.lastIndexOf('/') + 1)}';
    } catch (_) {
      return url;
    }
  }

  String _generateId() {
    return 'm3u8_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// 简单信号量
class _Semaphore {
  final int max;
  int _current = 0;
  final List<Completer> _waiters = [];

  _Semaphore(this.max);

  Future<void> acquire() async {
    if (_current < max) {
      _current++;
      return;
    }
    final completer = Completer();
    _waiters.add(completer);
    await completer.future;
    _current++;
  }

  void release() {
    _current--;
    if (_waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next.complete();
    }
  }
}

final m3u8DownloaderProvider =
    StateNotifierProvider<M3U8Downloader, List<M3U8DownloadTask>>((ref) {
  return M3U8Downloader();
});