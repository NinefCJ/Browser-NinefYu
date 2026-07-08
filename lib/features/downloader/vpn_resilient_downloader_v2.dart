import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vpn_resilience_center.dart';
import 'download_engine.dart';
import 'storage_monitor.dart';

/// 异常类型分类
enum ErrorType {
  tcpReset,
  connectionReset,
  sslHandshake,
  forbiddenByIp,
  connectionTimeout,
  readTimeout,
  dnsFailure,
  networkUnreachable,
  httpError,
  unknown,
}

/// 恢复策略
enum RecoveryStrategy {
  simpleRetry,
  sessionRecovery,
  ipChangeRecovery,
  sslHandshake,
  uaRotation,
  fullReset,
  abort,
}

/// 恢复结果
class RecoveryResult {
  final bool success;
  final RecoveryStrategy strategy;
  final int retryCount;
  final Duration duration;
  final String? message;
  final String? newIp;

  RecoveryResult({
    required this.success,
    required this.strategy,
    this.retryCount = 0,
    this.duration = Duration.zero,
    this.message,
    this.newIp,
  });
}

/// VPN 韧性下载处理器 V2
class VpnResilientDownloaderV2 {
  final Dio _dio;
  final VpnResilienceCenter _resilienceCenter;
  final StorageMonitor? _storageMonitor;
  final SpeedLimiter? _speedLimiter;

  final List<String> _userAgentPool = const [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',
  ];

  int _currentUAIndex = 0;
  int _totalRetries = 0;
  final DateTime _startTime = DateTime.now();

  VpnResilientDownloaderV2({
    required Dio dio,
    required VpnResilienceCenter resilienceCenter,
    StorageMonitor? storageMonitor,
    this._speedLimiter,
  })  : _dio = dio,
        _resilienceCenter = resilienceCenter,
        _storageMonitor = storageMonitor;

  /// 带 VPN 韧性的下载
  Future<RecoveryResult> downloadWithResilience({
    required DownloadTask task,
    required DownloadChunk chunk,
    required CancelToken cancelToken,
    required Function(int) onProgress,
  }) async {
    final config = _resilienceCenter.state.config;
    var retry = 0;
    var currentStrategy = RecoveryStrategy.simpleRetry;

    while (retry < config.maxRetryCount) {
      if (cancelToken.isCancelled) {
        return RecoveryResult(
          success: false,
          strategy: RecoveryStrategy.abort,
          retryCount: retry,
          message: '用户取消',
        );
      }

      try {
        await _downloadChunkWithRetry(
          task,
          chunk,
          cancelToken,
          onProgress,
          useUA: config.enableUaRotation ? _userAgentPool[_currentUAIndex] : null,
        );

        chunk.status = DownloadStatus.completed;
        return RecoveryResult(
          success: true,
          strategy: currentStrategy,
          retryCount: retry,
          duration: DateTime.now().difference(_startTime),
        );
      } catch (e) {
        retry++;
        _totalRetries++;

        final errorType = _classifyError(e);
        currentStrategy = _selectRecoveryStrategy(errorType, retry);

        // 记录恢复事件
        _resilienceCenter.state.recoveryHistory.add(
          RecoveryEvent(
            time: DateTime.now(),
            taskId: task.id,
            type: _errorToRecoveryType(errorType),
            result: RecoveryResult.inProgress as RecoveryResult,
            retryCount: retry,
            errorMessage: e.toString(),
          ),
        );

        switch (currentStrategy) {
          case RecoveryStrategy.simpleRetry:
            await _exponentialBackoff(retry, config.cooldownInitialMs);
            continue;

          case RecoveryStrategy.sessionRecovery:
            final recovered = await _trySessionRecovery(task);
            if (recovered) {
              retry = 0;
              await Future.delayed(Duration(milliseconds: config.cooldownInitialMs));
              continue;
            }
            await _exponentialBackoff(retry, config.cooldownInitialMs);
            continue;

          case RecoveryStrategy.ipChangeRecovery:
            await _waitForIpStability(config);
            retry = 0;
            continue;

          case RecoveryStrategy.sslHandshake:
            await Future.delayed(Duration(milliseconds: config.cooldownInitialMs * 2));
            continue;

          case RecoveryStrategy.uaRotation:
            _rotateUA();
            await Future.delayed(Duration(milliseconds: config.cooldownInitialMs ~/ 2));
            continue;

          case RecoveryStrategy.fullReset:
            await _fullReset(task);
            retry = 0;
            continue;

          case RecoveryStrategy.abort:
            chunk.status = DownloadStatus.failed;
            return RecoveryResult(
              success: false,
              strategy: RecoveryStrategy.abort,
              retryCount: retry,
              duration: DateTime.now().difference(_startTime),
              message: '超过最大重试次数',
            );
        }
      }
    }

    chunk.status = DownloadStatus.failed;
    return RecoveryResult(
      success: false,
      strategy: currentStrategy,
      retryCount: retry,
      duration: DateTime.now().difference(_startTime),
      message: '最大重试次数耗尽',
    );
  }

  /// 执行分块下载（带重试）
  Future<void> _downloadChunkWithRetry(
    DownloadTask task,
    DownloadChunk chunk,
    CancelToken cancelToken,
    Function(int) onProgress, {
    String? useUA,
  }) async {
    final headers = Map<String, String>.from(task.headers);
    if (useUA != null) {
      headers['User-Agent'] = useUA;
    }

    final start = chunk.startByte + chunk.downloadedBytes;
    final end = chunk.endByte;

    // 根据VPN状态调整超时
    final isVpn = _resilienceCenter.state.networkType == NetworkType.vpn;
    final connectTimeout = isVpn ? Duration(seconds: 60) : Duration(seconds: 30);
    final receiveTimeout = isVpn ? Duration(minutes: 2) : Duration(minutes: 1);

    final response = await _dio.download(
      task.url,
      (headers) {
        // 返回一个 IOSink 用于写入
        final file = File(chunk.tempPath!);
        return file.openWrite(mode: FileMode.append);
      },
      options: Options(
        headers: {
          ...headers,
          'Range': 'bytes=$start-$end',
        },
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.stream,
      ),
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        onProgress(received);
        _speedLimiter?.throttle(received);
        _storageMonitor?.guard(task.totalBytes, task.downloadedBytes);
      },
    );

    if (response.statusCode != 206 && response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  /// 错误分类
  ErrorType _classifyError(dynamic error) {
    if (error is! DioException) {
      return ErrorType.unknown;
    }

    final msg = error.toString().toLowerCase();

    // TCP 连接重置
    if (msg.contains('connection reset') ||
        msg.contains('broken pipe') ||
        msg.contains('connection was reset') ||
        msg.contains('reset by peer')) {
      return ErrorType.tcpReset;
    }

    // SSL 握手失败
    if (msg.contains('ssl') ||
        msg.contains('tls') ||
        msg.contains('handshake') ||
        msg.contains('certificate')) {
      return ErrorType.sslHandshake;
    }

    // 403 Forbidden（IP变更导致）
    if (error.response?.statusCode == 403) {
      return ErrorType.forbiddenByIp;
    }

    // 连接超时
    if (error.type == DioExceptionType.connectionTimeout) {
      return ErrorType.connectionTimeout;
    }

    // 读取超时
    if (error.type == DioExceptionType.receiveTimeout) {
      return ErrorType.readTimeout;
    }

    // DNS 解析失败
    if (msg.contains('dns') || msg.contains('name or service not known')) {
      return ErrorType.dnsFailure;
    }

    // 网络不可达
    if (msg.contains('network is unreachable') ||
        msg.contains('no internet') ||
        msg.contains('unable to connect')) {
      return ErrorType.networkUnreachable;
    }

    // HTTP 错误
    if (error.response != null) {
      return ErrorType.httpError;
    }

    return ErrorType.unknown;
  }

  /// 选择恢复策略
  RecoveryStrategy _selectRecoveryStrategy(ErrorType errorType, int retryCount) {
    final config = _resilienceCenter.state.config;
    if (retryCount >= config.maxRetryCount) {
      return RecoveryStrategy.abort;
    }

    switch (errorType) {
      case ErrorType.tcpReset:
      case ErrorType.connectionReset:
        if (config.enableSessionRecovery && retryCount >= 2) {
          return RecoveryStrategy.sessionRecovery;
        }
        return RecoveryStrategy.simpleRetry;

      case ErrorType.forbiddenByIp:
        if (config.enableSessionRecovery) {
          return RecoveryStrategy.sessionRecovery;
        }
        return RecoveryStrategy.uaRotation;

      case ErrorType.sslHandshake:
        if (retryCount >= 3) {
          return RecoveryStrategy.ipChangeRecovery;
        }
        return RecoveryStrategy.sslHandshake;

      case ErrorType.connectionTimeout:
      case ErrorType.readTimeout:
        if (retryCount >= 2 && _resilienceCenter.state.networkType == NetworkType.vpn) {
          return RecoveryStrategy.ipChangeRecovery;
        }
        return RecoveryStrategy.simpleRetry;

      case ErrorType.dnsFailure:
        return RecoveryStrategy.simpleRetry;

      case ErrorType.networkUnreachable:
        if (retryCount >= 3) {
          return RecoveryStrategy.fullReset;
        }
        return RecoveryStrategy.ipChangeRecovery;

      case ErrorType.httpError:
        return RecoveryStrategy.uaRotation;

      case ErrorType.unknown:
        if (retryCount >= 4) {
          return RecoveryStrategy.fullReset;
        }
        return RecoveryStrategy.simpleRetry;
    }
  }

  /// 指数退避等待
  Future<void> _exponentialBackoff(int retry, int initialMs) async {
    final maxBackoff = _resilienceCenter.state.config.cooldownMaxMs;
    final backoff = (initialMs * pow(2, retry.clamp(0, 5))).toInt();
    final waitTime = backoff.clamp(initialMs, maxBackoff);
    await Future.delayed(Duration(milliseconds: waitTime));
  }

  /// 尝试 Session 恢复
  Future<bool> _trySessionRecovery(DownloadTask task) async {
    try {
      // 发起 HEAD 请求重新获取 ETag 和文件信息
      final response = await _dio.head(
        task.url,
        options: Options(
          headers: task.headers,
          connectTimeout: Duration(seconds: 10),
        ),
      );

      final etag = response.headers.value('etag');
      final contentLength = response.headers.value('content-length');

      if (etag != null) {
        // ETag 存在，可能 session 已恢复
        // 更新任务的 ETag
        task.copyWith(etag: etag);
        if (contentLength != null) {
          task.copyWith(totalBytes: int.tryParse(contentLength) ?? task.totalBytes);
        }
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// 等待 IP 稳定
  Future<void> _waitForIpStability(VpnResilienceConfig config) async {
    // 等待 IP 变更冷却时间
    await Future.delayed(Duration(milliseconds: config.ipChangeCooldownMs));

    // 检查 IP 状态
    final status = await _resilienceCenter.checkVpnStatus();
    if (status == VpnConnectionState.connected) {
      return;
    }

    // 如果还不稳定，再等待一段时间
    await Future.delayed(Duration(milliseconds: config.cooldownMaxMs));
  }

  /// 完全重置连接
  Future<bool> _fullReset(DownloadTask task) async {
    // 关闭现有连接
    _dio.close(force: true);

    // 等待更长时间
    await Future.delayed(Duration(seconds: 5));

    // 重新探测 URL
    try {
      final response = await _dio.head(task.url);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// UA 轮换
  void _rotateUA() {
    _currentUAIndex = (_currentUAIndex + 1) % _userAgentPool.length;
  }

  String get currentUserAgent => _userAgentPool[_currentUAIndex];

  RecoveryType _errorToRecoveryType(ErrorType error) {
    switch (error) {
      case ErrorType.tcpReset:
      case ErrorType.connectionReset:
        return RecoveryType.tcpReset;
      case ErrorType.sslHandshake:
        return RecoveryType.sslHandshake;
      case ErrorType.forbiddenByIp:
        return RecoveryType.sessionRecovery;
      case ErrorType.connectionTimeout:
      case ErrorType.readTimeout:
        return RecoveryType.timeout;
      case ErrorType.dnsFailure:
        return RecoveryType.dnsFailure;
      case ErrorType.networkUnreachable:
        return RecoveryType.networkUnreachable;
      case ErrorType.httpError:
      case ErrorType.unknown:
        return RecoveryType.unknown;
    }
  }

  int get totalRetries => _totalRetries;
}

final vpnResilientDownloaderProvider = Provider<VpnResilientDownloaderV2>((ref) {
  final dio = Dio();
  final center = ref.read(vpnResilienceCenterProvider.notifier);
  return VpnResilientDownloaderV2(dio: dio, resilienceCenter: center);
});