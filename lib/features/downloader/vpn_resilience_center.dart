import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// VPN 连接状态
enum VpnConnectionState {
  connected,
  switching,
  unstable,
  error,
  disconnected,
  unknown,
}

/// IP 变更记录
class IpChangeRecord {
  final String oldIp;
  final String newIp;
  final DateTime changedAt;
  final Duration duration;

  IpChangeRecord({
    required this.oldIp,
    required this.newIp,
    required this.changedAt,
    required this.duration,
  });
}

/// VPN 韧性配置
class VpnResilienceConfig {
  final int maxRetryCount;
  final int cooldownInitialMs;
  final int cooldownMaxMs;
  final int ipChangeCooldownMs;
  final int ipDetectIntervalMs;
  final bool autoPauseOnIpChange;
  final bool autoResumeOnStable;
  final bool enableSessionRecovery;
  final bool enableUaRotation;
  final int sessionRecoveryTimeoutMs;

  const VpnResilienceConfig({
    this.maxRetryCount = 8,
    this.cooldownInitialMs = 2000,
    this.cooldownMaxMs = 30000,
    this.ipChangeCooldownMs = 5000,
    this.ipDetectIntervalMs = 10000,
    this.autoPauseOnIpChange = true,
    this.autoResumeOnStable = true,
    this.enableSessionRecovery = true,
    this.enableUaRotation = true,
    this.sessionRecoveryTimeoutMs = 10000,
  });

  VpnResilienceConfig copyWith({
    int? maxRetryCount,
    int? cooldownInitialMs,
    int? cooldownMaxMs,
    int? ipChangeCooldownMs,
    int? ipDetectIntervalMs,
    bool? autoPauseOnIpChange,
    bool? autoResumeOnStable,
    bool? enableSessionRecovery,
    bool? enableUaRotation,
    int? sessionRecoveryTimeoutMs,
  }) {
    return VpnResilienceConfig(
      maxRetryCount: maxRetryCount ?? this.maxRetryCount,
      cooldownInitialMs: cooldownInitialMs ?? this.cooldownInitialMs,
      cooldownMaxMs: cooldownMaxMs ?? this.cooldownMaxMs,
      ipChangeCooldownMs: ipChangeCooldownMs ?? this.ipChangeCooldownMs,
      ipDetectIntervalMs: ipDetectIntervalMs ?? this.ipDetectIntervalMs,
      autoPauseOnIpChange: autoPauseOnIpChange ?? this.autoPauseOnIpChange,
      autoResumeOnStable: autoResumeOnStable ?? this.autoResumeOnStable,
      enableSessionRecovery: enableSessionRecovery ?? this.enableSessionRecovery,
      enableUaRotation: enableUaRotation ?? this.enableUaRotation,
      sessionRecoveryTimeoutMs: sessionRecoveryTimeoutMs ?? this.sessionRecoveryTimeoutMs,
    );
  }
}

/// 恢复事件
class RecoveryEvent {
  final DateTime time;
  final String taskId;
  final RecoveryType type;
  final RecoveryResult result;
  final int retryCount;
  final String? oldIp;
  final String? newIp;
  final String? errorMessage;

  RecoveryEvent({
    required this.time,
    required this.taskId,
    required this.type,
    required this.result,
    this.retryCount = 0,
    this.oldIp,
    this.newIp,
    this.errorMessage,
  });
}

enum RecoveryType {
  ipChange,
  tcpReset,
  sslHandshake,
  sessionRecovery,
  uaRotation,
  timeout,
  dnsFailure,
  networkUnreachable,
  unknown,
}

enum RecoveryResult {
  success,
  failed,
  inProgress,
  skipped,
}

/// 网络类型
enum NetworkType {
  wifi,
  mobile,
  ethernet,
  vpn,
  none,
  unknown,
}

/// VPN 韧性中心状态
class VpnResilienceState {
  final VpnConnectionState connectionState;
  final String? currentIp;
  final String? lastIp;
  final NetworkType networkType;
  final VpnResilienceConfig config;
  final List<IpChangeRecord> ipChangeHistory;
  final List<RecoveryEvent> recoveryHistory;
  final int totalIpChanges;
  final int totalRecoverySuccess;
  final int totalRecoveryFailed;
  final bool isMonitoring;
  final DateTime? lastStateChange;
  final String? errorMessage;

  VpnResilienceState({
    this.connectionState = VpnConnectionState.unknown,
    this.currentIp,
    this.lastIp,
    this.networkType = NetworkType.unknown,
    this.config = const VpnResilienceConfig(),
    this.ipChangeHistory = const [],
    this.recoveryHistory = const [],
    this.totalIpChanges = 0,
    this.totalRecoverySuccess = 0,
    this.totalRecoveryFailed = 0,
    this.isMonitoring = false,
    this.lastStateChange,
    this.errorMessage,
  });

  double get recoveryRate {
    final total = totalRecoverySuccess + totalRecoveryFailed;
    if (total == 0) return 0;
    return totalRecoverySuccess / total;
  }

  int get recentIpChanges {
    final oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
    return ipChangeHistory.where((r) => r.changedAt.isAfter(oneHourAgo)).length;
  }

  VpnResilienceState copyWith({
    VpnConnectionState? connectionState,
    String? currentIp,
    String? lastIp,
    NetworkType? networkType,
    VpnResilienceConfig? config,
    List<IpChangeRecord>? ipChangeHistory,
    List<RecoveryEvent>? recoveryHistory,
    int? totalIpChanges,
    int? totalRecoverySuccess,
    int? totalRecoveryFailed,
    bool? isMonitoring,
    DateTime? lastStateChange,
    String? errorMessage,
  }) {
    return VpnResilienceState(
      connectionState: connectionState ?? this.connectionState,
      currentIp: currentIp ?? this.currentIp,
      lastIp: lastIp ?? this.lastIp,
      networkType: networkType ?? this.networkType,
      config: config ?? this.config,
      ipChangeHistory: ipChangeHistory ?? this.ipChangeHistory,
      recoveryHistory: recoveryHistory ?? this.recoveryHistory,
      totalIpChanges: totalIpChanges ?? this.totalIpChanges,
      totalRecoverySuccess: totalRecoverySuccess ?? this.totalRecoverySuccess,
      totalRecoveryFailed: totalRecoveryFailed ?? this.totalRecoveryFailed,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      lastStateChange: lastStateChange ?? this.lastStateChange,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// VPN 韧性中心
class VpnResilienceCenter extends StateNotifier<VpnResilienceState> {
  final Dio _dio;
  Timer? _ipMonitorTimer;
  DateTime _lastIpCheck = DateTime.now();
  int _ipSourceIndex = 0;

  final List<String> _ipDetectUrls = const [
    'https://api.ipify.org',
    'https://ipapi.co/ip/',
    'https://ipinfo.io/ip',
    'https://ip.sb',
  ];

  VpnResilienceCenter(this._dio) : super(VpnResilienceState()) {
    _detectNetworkType();
  }

  /// 开始监控
  void startMonitoring() {
    if (state.isMonitoring) return;

    state = state.copyWith(isMonitoring: true);
    _startIpMonitor();
  }

  /// 停止监控
  void stopMonitoring() {
    _ipMonitorTimer?.cancel();
    _ipMonitorTimer = null;
    state = state.copyWith(isMonitoring: false);
  }

  /// IP 监控定时器
  void _startIpMonitor() {
    _ipMonitorTimer?.cancel();
    _ipMonitorTimer = Timer.periodic(
      Duration(milliseconds: state.config.ipDetectIntervalMs),
      (_) => _checkIpChange(),
    );
    // 立即检查一次
    _checkIpChange();
  }

  /// 检测当前 IP
  Future<String?> _detectCurrentIp() async {
    for (var i = 0; i < _ipDetectUrls.length; i++) {
      final url = _ipDetectUrls[(_ipSourceIndex + i) % _ipDetectUrls.length];
      try {
        final response = await _dio.get<String>(
          url,
          options: Options(
            receiveTimeout: Duration(seconds: 5),
            sendTimeout: Duration(seconds: 5),
          ),
        );
        _ipSourceIndex = (_ipSourceIndex + i) % _ipDetectUrls.length;
        final ip = response.data?.trim();
        if (ip != null && ip.isNotEmpty && _isValidIp(ip)) {
          return ip;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  bool _isValidIp(String ip) {
    final ipv4 = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    return ipv4.hasMatch(ip);
  }

  /// 检测 IP 变更
  Future<void> _checkIpChange() async {
    final newIp = await _detectCurrentIp();
    if (newIp == null) return;

    final oldIp = state.currentIp;
    if (oldIp != null && oldIp != newIp) {
      // IP 变化了
      final record = IpChangeRecord(
        oldIp: oldIp,
        newIp: newIp,
        changedAt: DateTime.now(),
        duration: DateTime.now().difference(_lastIpCheck),
      );

      final history = List<IpChangeRecord>.from(state.ipChangeHistory);
      history.insert(0, record);
      if (history.length > 100) history.removeLast();

      state = state.copyWith(
        lastIp: oldIp,
        currentIp: newIp,
        connectionState: VpnConnectionState.switching,
        ipChangeHistory: history,
        totalIpChanges: state.totalIpChanges + 1,
        lastStateChange: DateTime.now(),
      );

      // IP 变更时的处理
      _onIpChanged(oldIp, newIp);

      // 等待稳定后更新状态
      Future.delayed(Duration(milliseconds: state.config.ipChangeCooldownMs), () {
        if (state.connectionState == VpnConnectionState.switching) {
          state = state.copyWith(
            connectionState: VpnConnectionState.connected,
            lastStateChange: DateTime.now(),
          );
        }
      });
    } else {
      // IP 未变化
      if (state.connectionState == VpnConnectionState.unknown) {
        state = state.copyWith(
          currentIp: newIp,
          connectionState: VpnConnectionState.connected,
          lastStateChange: DateTime.now(),
        );
      } else {
        state = state.copyWith(currentIp: newIp);
      }
    }

    _lastIpCheck = DateTime.now();
  }

  /// IP 变更处理
  void _onIpChanged(String oldIp, String newIp) {
    // 记录恢复事件
    final event = RecoveryEvent(
      time: DateTime.now(),
      taskId: 'system',
      type: RecoveryType.ipChange,
      result: RecoveryResult.inProgress,
      oldIp: oldIp,
      newIp: newIp,
    );
    _addRecoveryEvent(event);
  }

  /// 检测网络类型
  Future<NetworkType> _detectNetworkType() async {
    // 简化实现，通过网络接口特征判断
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('utun') ||
            name.contains('ppp') ||
            name.contains('vpn')) {
          state = state.copyWith(networkType: NetworkType.vpn);
          return NetworkType.vpn;
        }
        if (name.contains('wlan') || name.contains('en') || name.contains('wifi')) {
          state = state.copyWith(networkType: NetworkType.wifi);
          return NetworkType.wifi;
        }
        if (name.contains('rmnet') || name.contains('eth')) {
          state = state.copyWith(networkType: NetworkType.mobile);
          return NetworkType.mobile;
        }
      }
    } catch (_) {}
    state = state.copyWith(networkType: NetworkType.unknown);
    return NetworkType.unknown;
  }

  /// 检查 VPN 连接状态
  Future<VpnConnectionState> checkVpnStatus() async {
    await _detectNetworkType();
    if (state.networkType == NetworkType.vpn) {
      final ip = await _detectCurrentIp();
      if (ip != null) {
        return VpnConnectionState.connected;
      } else {
        return VpnConnectionState.unstable;
      }
    }
    return VpnConnectionState.disconnected;
  }

  /// 记录恢复事件
  void _addRecoveryEvent(RecoveryEvent event) {
    final history = List<RecoveryEvent>.from(state.recoveryHistory);
    history.insert(0, event);
    if (history.length > 200) history.removeLast();

    int success = state.totalRecoverySuccess;
    int failed = state.totalRecoveryFailed;
    if (event.result == RecoveryResult.success) success++;
    if (event.result == RecoveryResult.failed) failed++;

    state = state.copyWith(
      recoveryHistory: history,
      totalRecoverySuccess: success,
      totalRecoveryFailed: failed,
    );
  }

  /// 更新配置
  void updateConfig(VpnResilienceConfig newConfig) {
    state = state.copyWith(config: newConfig);
    if (state.isMonitoring) {
      _startIpMonitor();
    }
  }

  /// 切换配置项
  void setConfig({
    int? maxRetryCount,
    int? cooldownInitialMs,
    int? cooldownMaxMs,
    int? ipChangeCooldownMs,
    int? ipDetectIntervalMs,
    bool? autoPauseOnIpChange,
    bool? autoResumeOnStable,
    bool? enableSessionRecovery,
    bool? enableUaRotation,
  }) {
    state = state.copyWith(
      config: state.config.copyWith(
        maxRetryCount: maxRetryCount,
        cooldownInitialMs: cooldownInitialMs,
        cooldownMaxMs: cooldownMaxMs,
        ipChangeCooldownMs: ipChangeCooldownMs,
        ipDetectIntervalMs: ipDetectIntervalMs,
        autoPauseOnIpChange: autoPauseOnIpChange,
        autoResumeOnStable: autoResumeOnStable,
        enableSessionRecovery: enableSessionRecovery,
        enableUaRotation: enableUaRotation,
      ),
    );
  }

  /// 手动触发 IP 检测
  Future<String?> forceIpCheck() async {
    final ip = await _detectCurrentIp();
    if (ip != null) {
      state = state.copyWith(currentIp: ip);
    }
    return ip;
  }

  /// 清理历史记录
  void clearHistory() {
    state = state.copyWith(
      ipChangeHistory: [],
      recoveryHistory: [],
      totalIpChanges: 0,
      totalRecoverySuccess: 0,
      totalRecoveryFailed: 0,
    );
  }

  @override
  void dispose() {
    _ipMonitorTimer?.cancel();
    super.dispose();
  }
}

final vpnResilienceCenterProvider =
    StateNotifierProvider<VpnResilienceCenter, VpnResilienceState>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));
  return VpnResilienceCenter(dio);
});