import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vpn_resilience_center.dart';

/// VPN 韧性监控页面
class VpnResilienceMonitorPage extends ConsumerStatefulWidget {
  const VpnResilienceMonitorPage({super.key});

  @override
  ConsumerState<VpnResilienceMonitorPage> createState() =>
      _VpnResilienceMonitorPageState();
}

class _VpnResilienceMonitorPageState
    extends ConsumerState<VpnResilienceMonitorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 启动监控
    Future.microtask(() {
      ref.read(vpnResilienceCenterProvider.notifier).startMonitoring();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vpnResilienceCenterProvider);
    final notifier = ref.read(vpnResilienceCenterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN 韧性监控'),
        actions: [
          IconButton(
            icon: Icon(state.isMonitoring ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (state.isMonitoring) {
                notifier.stopMonitoring();
              } else {
                notifier.startMonitoring();
              }
            },
            tooltip: state.isMonitoring ? '暂停监控' : '开始监控',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.forceIpCheck(),
            tooltip: '检测IP',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '状态'),
            Tab(text: '历史'),
            Tab(text: '配置'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(state, notifier),
          _buildHistoryTab(state),
          _buildConfigTab(state, notifier),
        ],
      ),
    );
  }

  Widget _buildStatusTab(VpnResilienceState state, VpnResilienceCenter notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 连接状态卡片
        _buildStatusCard(state),
        const SizedBox(height: 16),
        // IP 信息
        _buildIpInfoCard(state),
        const SizedBox(height: 16),
        // 统计信息
        _buildStatsCard(state),
        const SizedBox(height: 16),
        // 快捷操作
        _buildQuickActions(state, notifier),
      ],
    );
  }

  Widget _buildStatusCard(VpnResilienceState state) {
    final statusColor = _getStatusColor(state.connectionState);
    final statusIcon = _getStatusIcon(state.connectionState);
    final statusText = _getStatusText(state.connectionState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.2),
              ),
              child: Icon(statusIcon, size: 40, color: statusColor),
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor),
            ),
            const SizedBox(height: 4),
            Text(
              '网络类型: ${_networkTypeText(state.networkType)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (state.lastStateChange != null) ...[
              const SizedBox(height: 8),
              Text(
                '最后变更: ${_formatTime(state.lastStateChange!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIpInfoCard(VpnResilienceState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IP 信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.public, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('当前 IP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        state.currentIp ?? '检测中...',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('上次 IP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        state.lastIp ?? '无',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700], fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(VpnResilienceState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('统计信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('IP 变更', state.totalIpChanges.toString(), Colors.orange),
                _buildStatItem('恢复成功', state.totalRecoverySuccess.toString(), Colors.green),
                _buildStatItem('恢复失败', state.totalRecoveryFailed.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('恢复成功率'),
                Text(
                  '${(state.recoveryRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: state.recoveryRate >= 0.8 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: state.recoveryRate,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                state.recoveryRate >= 0.8 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('近1小时 IP 变更'),
                Text('${state.recentIpChanges} 次', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuickActions(VpnResilienceState state, VpnResilienceCenter notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快捷操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(Icons.refresh, '检测IP', () => notifier.forceIpCheck()),
                _buildActionButton(Icons.delete_sweep, '清理历史', () => notifier.clearHistory()),
                _buildActionButton(Icons.vpn_lock, 'VPN状态', () => notifier.checkVpnStatus()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(VpnResilienceState state) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'IP变更记录'),
              Tab(text: '恢复事件'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildIpChangeHistory(state),
                _buildRecoveryHistory(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpChangeHistory(VpnResilienceState state) {
    if (state.ipChangeHistory.isEmpty) {
      return const Center(child: Text('暂无 IP 变更记录'));
    }
    return ListView.builder(
      itemCount: state.ipChangeHistory.length,
      itemBuilder: (context, index) {
        final record = state.ipChangeHistory[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.swap_horiz, size: 18)),
          title: Row(
            children: [
              Expanded(
                child: Text(record.oldIp,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    textAlign: TextAlign.right),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: Text(record.newIp,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    )),
              ),
            ],
          ),
          subtitle: Text(
            '${_formatDateTime(record.changedAt)} · 持续 ${record.duration.inSeconds}秒',
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _buildRecoveryHistory(VpnResilienceState state) {
    if (state.recoveryHistory.isEmpty) {
      return const Center(child: Text('暂无恢复事件'));
    }
    return ListView.builder(
      itemCount: state.recoveryHistory.length,
      itemBuilder: (context, index) {
        final event = state.recoveryHistory[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getResultColor(event.result),
            child: Icon(_getResultIcon(event.result), size: 18, color: Colors.white),
          ),
          title: Text(_recoveryTypeText(event.type)),
          subtitle: Text(
            '${_formatDateTime(event.time)} · 第${event.retryCount}次重试',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: event.errorMessage != null
              ? Tooltip(message: event.errorMessage, child: const Icon(Icons.error_outline, color: Colors.red))
              : null,
        );
      },
    );
  }

  Widget _buildConfigTab(VpnResilienceState state, VpnResilienceCenter notifier) {
    final config = state.config;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('重试配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('最大重试次数'),
          subtitle: Slider(
            value: config.maxRetryCount.toDouble(),
            min: 2,
            max: 16,
            divisions: 14,
            label: '${config.maxRetryCount} 次',
            onChanged: (v) => notifier.setConfig(maxRetryCount: v.toInt()),
          ),
          trailing: Text('${config.maxRetryCount}'),
        ),
        ListTile(
          title: const Text('初始冷却时间'),
          subtitle: Text('${config.cooldownInitialMs ~/ 1000} 秒'),
          trailing: const SizedBox(width: 100),
        ),
        Slider(
          value: config.cooldownInitialMs.toDouble(),
          min: 1000,
          max: 5000,
          divisions: 8,
          label: '${config.cooldownInitialMs ~/ 1000}s',
          onChanged: (v) => notifier.setConfig(cooldownInitialMs: v.toInt()),
        ),
        ListTile(
          title: const Text('最大冷却时间'),
          subtitle: Text('${config.cooldownMaxMs ~/ 1000} 秒'),
        ),
        Slider(
          value: config.cooldownMaxMs.toDouble(),
          min: 10000,
          max: 60000,
          divisions: 10,
          label: '${config.cooldownMaxMs ~/ 1000}s',
          onChanged: (v) => notifier.setConfig(cooldownMaxMs: v.toInt()),
        ),
        const Divider(),
        const Text('IP 检测', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('IP 变更冷却'),
          subtitle: Text('${config.ipChangeCooldownMs ~/ 1000} 秒'),
        ),
        Slider(
          value: config.ipChangeCooldownMs.toDouble(),
          min: 3000,
          max: 15000,
          divisions: 12,
          label: '${config.ipChangeCooldownMs ~/ 1000}s',
          onChanged: (v) => notifier.setConfig(ipChangeCooldownMs: v.toInt()),
        ),
        ListTile(
          title: const Text('IP 检测间隔'),
          subtitle: Text('${config.ipDetectIntervalMs ~/ 1000} 秒'),
        ),
        Slider(
          value: config.ipDetectIntervalMs.toDouble(),
          min: 5000,
          max: 60000,
          divisions: 11,
          label: '${config.ipDetectIntervalMs ~/ 1000}s',
          onChanged: (v) => notifier.setConfig(ipDetectIntervalMs: v.toInt()),
        ),
        const Divider(),
        const Text('高级选项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('IP变更时自动暂停'),
          subtitle: const Text('检测到IP变化时自动暂停下载'),
          value: config.autoPauseOnIpChange,
          onChanged: (v) => notifier.setConfig(autoPauseOnIpChange: v),
        ),
        SwitchListTile(
          title: const Text('稳定后自动恢复'),
          subtitle: const Text('VPN稳定后自动恢复下载'),
          value: config.autoResumeOnStable,
          onChanged: (v) => notifier.setConfig(autoResumeOnStable: v),
        ),
        SwitchListTile(
          title: const Text('Session 恢复'),
          subtitle: const Text('IP变更后尝试恢复下载会话'),
          value: config.enableSessionRecovery,
          onChanged: (v) => notifier.setConfig(enableSessionRecovery: v),
        ),
        SwitchListTile(
          title: const Text('UA 轮换'),
          subtitle: const Text('403错误时自动更换User-Agent'),
          value: config.enableUaRotation,
          onChanged: (v) => notifier.setConfig(enableUaRotation: v),
        ),
      ],
    );
  }

  Color _getStatusColor(VpnConnectionState state) {
    switch (state) {
      case VpnConnectionState.connected:
        return Colors.green;
      case VpnConnectionState.switching:
        return Colors.orange;
      case VpnConnectionState.unstable:
        return Colors.yellow;
      case VpnConnectionState.error:
        return Colors.red;
      case VpnConnectionState.disconnected:
        return Colors.grey;
      case VpnConnectionState.unknown:
        return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(VpnConnectionState state) {
    switch (state) {
      case VpnConnectionState.connected:
        return Icons.vpn_lock;
      case VpnConnectionState.switching:
        return Icons.sync;
      case VpnConnectionState.unstable:
        return Icons.warning;
      case VpnConnectionState.error:
        return Icons.error;
      case VpnConnectionState.disconnected:
        return Icons.vpn_lock_off;
      case VpnConnectionState.unknown:
        return Icons.help_outline;
    }
  }

  String _getStatusText(VpnConnectionState state) {
    switch (state) {
      case VpnConnectionState.connected:
        return 'VPN 已连接';
      case VpnConnectionState.switching:
        return 'VPN 切换中';
      case VpnConnectionState.unstable:
        return '连接不稳定';
      case VpnConnectionState.error:
        return '连接错误';
      case VpnConnectionState.disconnected:
        return '未连接';
      case VpnConnectionState.unknown:
        return '检测中...';
    }
  }

  String _networkTypeText(NetworkType type) {
    switch (type) {
      case NetworkType.wifi:
        return 'Wi-Fi';
      case NetworkType.mobile:
        return '移动网络';
      case NetworkType.ethernet:
        return '以太网';
      case NetworkType.vpn:
        return 'VPN';
      case NetworkType.none:
        return '无网络';
      case NetworkType.unknown:
        return '未知';
    }
  }

  String _recoveryTypeText(RecoveryType type) {
    switch (type) {
      case RecoveryType.ipChange:
        return 'IP 变更';
      case RecoveryType.tcpReset:
        return 'TCP 连接重置';
      case RecoveryType.sslHandshake:
        return 'SSL 握手失败';
      case RecoveryType.sessionRecovery:
        return 'Session 恢复';
      case RecoveryType.uaRotation:
        return 'UA 轮换';
      case RecoveryType.timeout:
        return '连接超时';
      case RecoveryType.dnsFailure:
        return 'DNS 解析失败';
      case RecoveryType.networkUnreachable:
        return '网络不可达';
      case RecoveryType.unknown:
        return '未知错误';
    }
  }

  Color _getResultColor(dynamic result) {
    if (result is RecoveryResult) {
      switch (result) {
        case RecoveryResult.success:
          return Colors.green;
        case RecoveryResult.failed:
          return Colors.red;
        case RecoveryResult.inProgress:
          return Colors.orange;
        case RecoveryResult.skipped:
          return Colors.grey;
      }
    }
    return Colors.grey;
  }

  IconData _getResultIcon(dynamic result) {
    if (result is RecoveryResult) {
      switch (result) {
        case RecoveryResult.success:
          return Icons.check;
        case RecoveryResult.failed:
          return Icons.close;
        case RecoveryResult.inProgress:
          return Icons.hourglass_empty;
        case RecoveryResult.skipped:
          return Icons.skip_next;
      }
    }
    return Icons.help_outline;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}