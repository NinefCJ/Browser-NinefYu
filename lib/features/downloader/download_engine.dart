import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 下载状态
enum DownloadStatus {
  pending,
  running,
  paused,
  completed,
  failed,
  cancelled,
  merging,
  verifying,
}

/// 下载分块
class DownloadChunk {
  final int index;
  final int startByte;
  final int endByte;
  int downloadedBytes;
  DownloadStatus status;
  final String? tempPath;

  DownloadChunk({
    required this.index,
    required this.startByte,
    required this.endByte,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.tempPath,
  });

  bool get isComplete => downloadedBytes >= (endByte - startByte + 1);
}

/// 下载任务
class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final String filePath;
  final String tempDir;
  final Map<String, String> headers;
  int totalBytes;
  int downloadedBytes;
  DownloadStatus status;
  final int threadCount;
  int maxSpeedBytesPerSec;
  final List<DownloadChunk> chunks;
  String? etag;
  String? lastModified;
  String? hashExpected;
  String? hashActual;
  String? errorMessage;
  int retryCount;
  DateTime? createdAt;
  DateTime? completedAt;
  double speed;
  int _speedBytes = 0;
  DateTime _speedTime = DateTime.now();

  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    required this.tempDir,
    this.headers = const {},
    this.totalBytes = -1,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.threadCount = 4,
    this.maxSpeedBytesPerSec = 0,
    this.chunks = const [],
    this.etag,
    this.lastModified,
    this.hashExpected,
    this.hashActual,
    this.errorMessage,
    this.retryCount = 0,
    this.createdAt,
    this.completedAt,
    this.speed = 0,
  });

  double get progress {
    if (totalBytes <= 0) return 0;
    return downloadedBytes / totalBytes;
  }

  DownloadTask copyWith({
    String? id,
    String? url,
    String? fileName,
    String? filePath,
    String? tempDir,
    Map<String, String>? headers,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    int? threadCount,
    int? maxSpeedBytesPerSec,
    List<DownloadChunk>? chunks,
    String? etag,
    String? lastModified,
    String? hashExpected,
    String? hashActual,
    String? errorMessage,
    int? retryCount,
    DateTime? createdAt,
    DateTime? completedAt,
    double? speed,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      tempDir: tempDir ?? this.tempDir,
      headers: headers ?? this.headers,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      threadCount: threadCount ?? this.threadCount,
      maxSpeedBytesPerSec: maxSpeedBytesPerSec ?? this.maxSpeedBytesPerSec,
      chunks: chunks ?? this.chunks,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      hashExpected: hashExpected ?? this.hashExpected,
      hashActual: hashActual ?? this.hashActual,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      speed: speed ?? this.speed,
    );
  }
}

/// 下载引擎
class DownloadEngine extends StateNotifier<List<DownloadTask>> {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, Timer> _speedMonitors = {};
  int maxConcurrent = 3;
  int defaultThreadCount = 4;

  DownloadEngine()
      : _dio = Dio(BaseOptions(
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(minutes: 30),
          sendTimeout: Duration(minutes: 30),
        )),
        super([]);

  int get activeCount => state.where((t) => t.status == DownloadStatus.running).length;
  int get pendingCount => state.where((t) => t.status == DownloadStatus.pending).length;
  int get completedCount => state.where((t) => t.status == DownloadStatus.completed).length;

  /// 创建下载任务
  Future<DownloadTask> createTask(
    String url, {
    String? fileName,
    String? savePath,
    int? threadCount,
    Map<String, String>? headers,
  }) async {
    final id = _generateId();
    final dir = await getTemporaryDirectory();
    final tempDir = '${dir.path}/downloads/$id';
    await Directory(tempDir).create(recursive: true);

    final saveDir = savePath ?? (await _getDownloadDirectory()).path;
    final fname = fileName ?? _extractFileName(url);
    final filePath = '$saveDir/$fname';

    final task = DownloadTask(
      id: id,
      url: url,
      fileName: fname,
      filePath: filePath,
      tempDir: tempDir,
      headers: headers ?? {},
      threadCount: threadCount ?? defaultThreadCount,
      createdAt: DateTime.now(),
    );

    state = [...state, task];
    _scheduleNext();
    return task;
  }

  Future<Directory> _getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// 开始下载
  Future<void> startTask(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;
    if (task.status == DownloadStatus.running) return;

    if (activeCount >= maxConcurrent) {
      _updateTask(taskId, status: DownloadStatus.pending);
      return;
    }

    _updateTask(taskId, status: DownloadStatus.running);
    _startSpeedMonitor(taskId);

    try {
      // 先探测文件大小
      await _probeFileSize(taskId);

      // 获取更新后的任务
      final updatedTask = _getTask(taskId);
      if (updatedTask == null) return;

      if (updatedTask.totalBytes > 0 && updatedTask.threadCount > 1) {
        // 多线程分块下载
        await _multiThreadDownload(taskId);
      } else {
        // 单线程下载
        await _singleThreadDownload(taskId);
      }
    } catch (e) {
      _updateTask(taskId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    } finally {
      _stopSpeedMonitor(taskId);
      _scheduleNext();
    }
  }

  /// 暂停下载
  void pauseTask(String taskId) {
    _cancelTokens[taskId]?.cancel('paused');
    _cancelTokens.remove(taskId);
    _stopSpeedMonitor(taskId);
    _updateTask(taskId, status: DownloadStatus.paused);
  }

  /// 继续下载
  Future<void> resumeTask(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;
    if (task.status != DownloadStatus.paused) return;
    await startTask(taskId);
  }

  /// 取消下载
  Future<void> cancelTask(String taskId) async {
    _cancelTokens[taskId]?.cancel('cancelled');
    _cancelTokens.remove(taskId);
    _stopSpeedMonitor(taskId);

    // 删除临时文件
    final task = _getTask(taskId);
    if (task != null) {
      try {
        final tempDir = Directory(task.tempDir);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    }

    _updateTask(taskId, status: DownloadStatus.cancelled);
    _scheduleNext();
  }

  /// 重新下载
  Future<void> retryTask(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;

    // 清理临时文件
    try {
      final tempDir = Directory(task.tempDir);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}

    final resetTask = task.copyWith(
      status: DownloadStatus.pending,
      downloadedBytes: 0,
      chunks: [],
      errorMessage: null,
      retryCount: task.retryCount + 1,
      completedAt: null,
    );

    final newState = state.map((t) => t.id == taskId ? resetTask : t).toList();
    state = newState;

    await startTask(taskId);
  }

  /// 探测文件大小
  Future<void> _probeFileSize(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;

    try {
      final response = await _dio.head(
        task.url,
        options: Options(headers: task.headers),
      );

      final contentLength = response.headers.value('content-length');
      final totalBytes = int.tryParse(contentLength ?? '') ?? -1;
      final etag = response.headers.value('etag');
      final lastModified = response.headers.value('last-modified');

      _updateTask(
        taskId,
        totalBytes: totalBytes,
        etag: etag,
        lastModified: lastModified,
      );
    } catch (_) {
      // HEAD失败，使用单线程下载
    }
  }

  /// 多线程分块下载
  Future<void> _multiThreadDownload(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;

    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    // 创建分块
    final chunkSize = (task.totalBytes / task.threadCount).ceil();
    final chunks = <DownloadChunk>[];
    for (int i = 0; i < task.threadCount; i++) {
      final start = i * chunkSize;
      final end = (i == task.threadCount - 1) ? task.totalBytes - 1 : (start + chunkSize - 1);
      final chunk = DownloadChunk(
        index: i,
        startByte: start,
        endByte: end,
        tempPath: '${task.tempDir}/chunk_$i',
      );
      chunks.add(chunk);
    }

    _updateTask(taskId, chunks: chunks);

    // 检查已有进度（断点续传）
    for (final chunk in chunks) {
      final file = File(chunk.tempPath!);
      if (await file.exists()) {
        final size = await file.length();
        chunk.downloadedBytes = size;
        if (chunk.isComplete) {
          chunk.status = DownloadStatus.completed;
        }
      }
    }

    // 并发下载各分块
    final futures = chunks.where((c) => !c.isComplete).map((chunk) {
      return _downloadChunk(taskId, chunk, cancelToken);
    }).toList();

    await Future.wait(futures, eagerError: false);

    // 检查所有分块是否完成
    final updatedTask = _getTask(taskId);
    if (updatedTask == null) return;
    final allComplete = updatedTask.chunks.every((c) => c.isComplete);

    if (!allComplete) {
      throw Exception('部分分块下载失败');
    }

    // 合并分块
    _updateTask(taskId, status: DownloadStatus.merging);
    await _mergeChunks(taskId);

    // 校验
    if (updatedTask.hashExpected != null) {
      _updateTask(taskId, status: DownloadStatus.verifying);
    }

    // 清理临时文件
    try {
      await Directory(updatedTask.tempDir).delete(recursive: true);
    } catch (_) {}

    _updateTask(taskId,
      status: DownloadStatus.completed,
      completedAt: DateTime.now(),
      downloadedBytes: updatedTask.totalBytes,
    );
    _stopSpeedMonitor(taskId);
  }

  /// 下载单个分块
  Future<void> _downloadChunk(String taskId, DownloadChunk chunk, CancelToken cancelToken) async {
    final task = _getTask(taskId);
    if (task == null) return;

    final file = File(chunk.tempPath!);
    await file.create(recursive: true);
    final raf = await file.open(mode: FileMode.append);

    try {
      final start = chunk.startByte + chunk.downloadedBytes;
      final end = chunk.endByte;

      final response = await _dio.download(
        task.url,
        (headers) => file.openWrite(mode: FileMode.append),
        options: Options(
          headers: {
            ...task.headers,
            'Range': 'bytes=$start-$end',
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final actualReceived = received;
          _onChunkProgress(taskId, chunk.index, actualReceived);
        },
      );

      chunk.status = DownloadStatus.completed;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        chunk.status = DownloadStatus.paused;
      } else {
        chunk.status = DownloadStatus.failed;
        rethrow;
      }
    } finally {
      await raf.close();
    }
  }

  /// 分块进度更新
  void _onChunkProgress(String taskId, int chunkIndex, int bytes) {
    final task = _getTask(taskId);
    if (task == null) return;

    final newChunks = List<DownloadChunk>.from(task.chunks);
    if (chunkIndex < newChunks.length) {
      newChunks[chunkIndex] = newChunks[chunkIndex].copyWith(downloadedBytes: bytes);
    }

    final totalDownloaded = newChunks.fold<int>(0, (sum, c) => sum + c.downloadedBytes);
    _updateTask(taskId,
      chunks: newChunks,
      downloadedBytes: totalDownloaded,
    );

    // 更新速度
    final now = DateTime.now();
    final elapsed = now.difference(task._speedTime).inMilliseconds;
    if (elapsed >= 1000) {
      task._speedTime = now;
      task._speedBytes = totalDownloaded - task.downloadedBytes;
    }
  }

  /// 单线程下载
  Future<void> _singleThreadDownload(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;

    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    final file = File(task.filePath);
    await file.create(recursive: true);

    try {
      var downloaded = 0;
      if (await file.exists()) {
        downloaded = await file.length();
      }

      await _dio.download(
        task.url,
        task.filePath,
        options: Options(
          headers: {
            ...task.headers,
            if (downloaded > 0) 'Range': 'bytes=$downloaded-',
          },
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final totalDownloaded = downloaded + received;
          _updateTask(taskId,
            downloadedBytes: totalDownloaded,
            totalBytes: total > 0 ? total : task.totalBytes,
          );
        },
      );

      _updateTask(taskId,
        status: DownloadStatus.completed,
        completedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _updateTask(taskId, status: DownloadStatus.paused);
      } else {
        _updateTask(taskId,
          status: DownloadStatus.failed,
          errorMessage: e.message,
        );
        rethrow;
      }
    } finally {
      _cancelTokens.remove(taskId);
    }
  }

  /// 合并分块
  Future<void> _mergeChunks(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) return;

    final outputFile = File(task.filePath);
    await outputFile.create(recursive: true);
    final sink = outputFile.openWrite(mode: FileMode.writeOnly);

    try {
      for (final chunk in task.chunks) {
        final chunkFile = File(chunk.tempPath!);
        if (await chunkFile.exists()) {
          final bytes = await chunkFile.readAsBytes();
          sink.add(bytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// 速度监控
  void _startSpeedMonitor(String taskId) {
    _speedMonitors[taskId]?.cancel();
    _speedMonitors[taskId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final task = _getTask(taskId);
      if (task == null) {
        timer.cancel();
        _speedMonitors.remove(taskId);
        return;
      }
      // 速度计算在进度回调中处理，这里仅触发UI更新
      state = [...state];
    });
  }

  void _stopSpeedMonitor(String taskId) {
    _speedMonitors[taskId]?.cancel();
    _speedMonitors.remove(taskId);
  }

  /// 调度下一个待下载任务
  void _scheduleNext() {
    while (activeCount < maxConcurrent && pendingCount > 0) {
      final pendingTasks = state.where((t) => t.status == DownloadStatus.pending).toList();
      if (pendingTasks.isEmpty) break;
      startTask(pendingTasks.first.id);
    }
  }

  /// 获取任务
  DownloadTask? _getTask(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 更新任务
  void _updateTask(String id, {
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    List<DownloadChunk>? chunks,
    String? etag,
    String? lastModified,
    String? hashExpected,
    String? hashActual,
    String? errorMessage,
    int? retryCount,
    DateTime? completedAt,
    double? speed,
  }) {
    final newState = state.map((task) {
      if (task.id != id) return task;
      return task.copyWith(
        status: status,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        chunks: chunks,
        etag: etag,
        lastModified: lastModified,
        hashExpected: hashExpected,
        hashActual: hashActual,
        errorMessage: errorMessage,
        retryCount: retryCount,
        completedAt: completedAt,
        speed: speed,
      );
    }).toList();
    state = newState;
  }

  String _generateId() {
    return 'dl_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final name = path.split('/').last;
      if (name.isNotEmpty) return Uri.decodeComponent(name);
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取所有任务
  List<DownloadTask> get allTasks => List.unmodifiable(state);

  /// 按状态获取任务
  List<DownloadTask> getTasksByStatus(DownloadStatus status) {
    return state.where((t) => t.status == status).toList();
  }
}

/// 扩展 DownloadChunk 以添加 copyWith
extension DownloadChunkCopy on DownloadChunk {
  DownloadChunk copyWith({
    int? index,
    int? startByte,
    int? endByte,
    int? downloadedBytes,
    DownloadStatus? status,
    String? tempPath,
  }) {
    return DownloadChunk(
      index: index ?? this.index,
      startByte: startByte ?? this.startByte,
      endByte: endByte ?? this.endByte,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      tempPath: tempPath ?? this.tempPath,
    );
  }
}

final downloadEngineProvider = StateNotifierProvider<DownloadEngine, List<DownloadTask>>((ref) {
  return DownloadEngine();
});