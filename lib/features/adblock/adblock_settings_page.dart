import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adblock_engine.dart';
import 'subscription_manager.dart';

/// 广告过滤管理页面
class AdBlockSettingsPage extends ConsumerStatefulWidget {
  const AdBlockSettingsPage({super.key});

  @override
  ConsumerState<AdBlockSettingsPage> createState() => _AdBlockSettingsPageState();
}

class _AdBlockSettingsPageState extends ConsumerState<AdBlockSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adBlockState = ref.watch(adBlockEngineProvider);
    final adBlockEngine = ref.read(adBlockEngineProvider.notifier);
    final subState = ref.watch(subscriptionManagerProvider);
    final subManager = ref.read(subscriptionManagerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('广告过滤'),
        actions: [
          Switch(
            value: adBlockState.enabled,
            onChanged: (value) => adBlockEngine.setEnabled(value),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: '订阅规则'),
            Tab(text: '自定义规则'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(adBlockState, adBlockEngine),
          _buildSubscriptionsTab(subState, subManager),
          _buildCustomRulesTab(adBlockState, adBlockEngine),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdBlockState state, AdBlockEngine engine) {
    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('统计信息', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('已拦截', state.blockedCount.toString(), Colors.red),
                    _buildStatItem('规则数', state.rules.length.toString(), Colors.blue),
                    _buildStatItem(
                      '域名',
                      state.blockStats.length.toString(),
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => engine.clearStats(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清空统计'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最近拦截', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (state.recentBlocked.isEmpty)
                  const Center(
                    heightFactor: 2,
                    child: Text('暂无拦截记录'),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: state.recentBlocked.length > 20 ? 20 : state.recentBlocked.length,
                      itemBuilder: (context, index) {
                        final url = state.recentBlocked[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.block, color: Colors.red, size: 18),
                          title: Text(
                            url.length > 50 ? '${url.substring(0, 50)}...' : url,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('拦截域名 Top 10', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (state.blockStats.isEmpty)
                  const Center(heightFactor: 2, child: Text('暂无数据'))
                else
                  ..._getTopDomains(state.blockStats, 10).map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                          Text('${e.value}次', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  List<MapEntry<String, int>> _getTopDomains(Map<String, int> stats, int count) {
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  Widget _buildSubscriptionsTab(SubscriptionManagerState state, SubscriptionManager manager) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: state.subscriptions.length,
          itemBuilder: (context, index) {
            final sub = state.subscriptions[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(sub.name[0]),
              ),
              title: Text(sub.name),
              subtitle: Text(sub.description),
              trailing: Switch(
                value: sub.enabled,
                onChanged: (_) => manager.toggleSubscription(sub.id),
              ),
              onTap: () => _showSubscriptionDetail(context, sub, manager),
            );
          },
        ),
        if (state.isUpdating)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: state.isUpdating ? null : () => manager.updateAllSubscriptions(),
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomRulesTab(AdBlockState state, AdBlockEngine engine) {
    final customRules = state.rules.where((r) => r.source == 'custom').toList();

    return Stack(
      children: [
        ListView.builder(
          itemCount: customRules.length,
          itemBuilder: (context, index) {
            final rule = customRules[index];
            return ListTile(
              leading: Icon(
                rule.type == RuleType.urlBlock ? Icons.block :
                rule.type == RuleType.urlAllow ? Icons.check_circle :
                Icons.visibility_off,
                size: 20,
              ),
              title: Text(rule.pattern),
              subtitle: Text(_ruleTypeText(rule.type)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => engine.removeRule(rule.id),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddRuleDialog(context, engine),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  String _ruleTypeText(RuleType type) {
    switch (type) {
      case RuleType.urlBlock:
        return 'URL拦截';
      case RuleType.urlAllow:
        return 'URL白名单';
      case RuleType.cssHide:
        return 'CSS隐藏';
      case RuleType.cssAllow:
        return 'CSS白名单';
      case RuleType.scriptInject:
        return '脚本注入';
      case RuleType.headerModify:
        return '头修改';
    }
  }

  void _showSubscriptionDetail(
    BuildContext context,
    RuleSubscription sub,
    SubscriptionManager manager,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sub.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub.description),
            const SizedBox(height: 12),
            Text('规则数: ${sub.ruleCount ?? '--'}'),
            Text('最后更新: ${sub.lastUpdated ?? '从未更新'}'),
            Text('URL: ${sub.url}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () async {
              await manager.updateSubscription(sub.id);
              Navigator.pop(context);
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, AdBlockEngine engine) {
    final patternController = TextEditingController();
    var selectedType = RuleType.urlBlock;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加自定义规则'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RuleType>(
                value: selectedType,
                items: RuleType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(_ruleTypeText(type)),
                )).toList(),
                onChanged: (v) => setState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: '规则类型'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: patternController,
                decoration: const InputDecoration(
                  labelText: '规则内容',
                  hintText: '输入URL模式或CSS选择器',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                engine.addRule(AdBlockRule(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  type: selectedType,
                  pattern: patternController.text,
                  cssSelector: selectedType == RuleType.cssHide ? patternController.text : null,
                  source: 'custom',
                ));
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}