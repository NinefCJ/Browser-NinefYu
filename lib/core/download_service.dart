import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final Map<String, dynamic> extraInfo;

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
    this.extraInfo = const {},
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
    Map<String, dynamic>? extraInfo,
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
      extraInfo: extraInfo ?? this.extraInfo,
    );
  }
}

/// 下载服务接口
class DownloadService extends StateNotifier<List<DownloadTask>> {
  DownloadService() : super([]);

  int get activeCount =>
      state.where((t) => t.status == DownloadStatus.running).length;

  int get completedCount =>
      state.where((t) => t.status == DownloadStatus.completed).length;

  DownloadTask? getTask(String id) {
    return state.cast<DownloadTask?>().firstWhere(
      (t) => t!.id == id,
      orElse: () => null,
    );
  }
}

final downloadServiceProvider =
    StateNotifierProvider<DownloadService, List<DownloadTask>>((ref) {
  return DownloadService();
});