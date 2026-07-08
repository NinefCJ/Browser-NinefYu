import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_script_engine.dart';
import 'script_manager.dart';

/// 用户脚本管理页面
class UserScriptsPage extends ConsumerStatefulWidget {
  const UserScriptsPage({super.key});

  @override
  ConsumerState<UserScriptsPage> createState() => _UserScriptsPageState();
}

class _UserScriptsPageState extends ConsumerState<UserScriptsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scriptState = ref.watch(userScriptEngineProvider);
    final scriptEngine = ref.read(userScriptEngineProvider.notifier);
    final repoState = ref.watch(scriptManagerProvider);
    final repoManager = ref.read(scriptManagerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户脚本'),
        actions: [
          Switch(
            value: scriptState.enabled,
            onChanged: (value) => scriptEngine.setEnabled(value),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '已安装'),
            Tab(text: '脚本仓库'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInstalledTab(scriptState, scriptEngine),
          _buildRepositoryTab(repoState, repoManager, scriptEngine),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScriptDialog(context, scriptEngine),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInstalledTab(UserScriptState state, UserScriptEngine engine) {
    if (state.scripts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无已安装的脚本'),
            SizedBox(height: 8),
            Text('点击右下角按钮添加新脚本', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.scripts.length,
      itemBuilder: (context, index) {
        final script = state.scripts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(script.metadata.name[0]),
            ),
            title: Text(script.metadata.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (script.metadata.description != null)
                  Text(
                    script.metadata.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'v${script.metadata.version ?? '1.0.0'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _runAtText(script.metadata.runAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: script.enabled,
              onChanged: (_) => engine.toggleScript(script.id),
            ),
            onTap: () => _showScriptDetail(context, script, engine),
          ),
        );
      },
    );
  }

  Widget _buildRepositoryTab(
    ScriptManagerState state,
    ScriptManager manager,
    UserScriptEngine engine,
  ) {
    final scripts = state.searchQuery.isNotEmpty
        ? state.searchResults
        : manager.getScriptsByCategory(state.selectedCategory);

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索脚本...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        manager.searchScripts('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: (value) => manager.searchScripts(value),
          ),
        ),
        // 分类
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: BuiltInScriptRepository.categories.map((cat) {
              final isSelected = state.selectedCategory == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${cat.icon} ${cat.name}'),
                  selected: isSelected,
                  onSelected: (_) => manager.selectCategory(cat.id),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        // 列表
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: scripts.length,
                  itemBuilder: (context, index) {
                    final item = scripts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(item.name[0]),
                        ),
                        title: Text(item.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(item.author, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(width: 12),
                                Icon(Icons.download, size: 12, color: Colors.grey),
                                Text(' ${item.downloads}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(width: 12),
                                Icon(Icons.star, size: 12, color: Colors.amber),
                                Text(' ${item.rating}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        trailing: item.installed
                            ? const Icon(Icons.check, color: Colors.green)
                            : FilledButton.tonal(
                                onPressed: () => _installScript(context, item, manager),
                                child: const Text('安装'),
                              ),
                        onTap: () => _showRepoItemDetail(context, item, manager, engine),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _runAtText(ScriptRunAt runAt) {
    switch (runAt) {
      case ScriptRunAt.documentStart:
        return '文档开始';
      case ScriptRunAt.documentEnd:
        return '文档加载';
      case ScriptRunAt.documentIdle:
        return '文档空闲';
    }
  }

  Future<void> _installScript(
    BuildContext context,
    ScriptRepositoryItem item,
    ScriptManager manager,
  ) async {
    final result = await manager.installScript(item.id);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('脚本 ${item.name} 已安装')),
      );
    }
  }

  void _showScriptDetail(
    BuildContext context,
    UserScript script,
    UserScriptEngine engine,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(script.metadata.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (script.metadata.description != null)
                Text(script.metadata.description!),
              const SizedBox(height: 12),
              Text('版本: v${script.metadata.version ?? '1.0.0'}'),
              if (script.metadata.author != null)
                Text('作者: ${script.metadata.author}'),
              Text('运行时机: ${_runAtText(script.metadata.runAt)}'),
              Text('运行次数: ${script.runCount}'),
              const SizedBox(height: 12),
              const Text('匹配网站:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...script.metadata.matches.map((m) => Text('  • $m')),
              if (script.metadata.grant.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('使用的 GM API:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...script.metadata.grant.map((g) => Text('  • $g')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              engine.removeScript(script.id);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditScriptDialog(context, script, engine);
            },
            icon: const Icon(Icons.edit),
            label: const Text('编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showRepoItemDetail(
    BuildContext context,
    ScriptRepositoryItem item,
    ScriptManager manager,
    UserScriptEngine engine,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description),
              const SizedBox(height: 12),
              Text('版本: v${item.version ?? '1.0.0'}'),
              Text('作者: ${item.author}'),
              Text('下载量: ${item.downloads}'),
              Text('评分: ${item.rating} ⭐'),
              const SizedBox(height: 12),
              const Text('匹配网站:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...item.matches.map((m) => Text('  • $m')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: item.installed
                ? null
                : () async {
                    Navigator.pop(context);
                    await _installScript(context, item, manager);
                  },
            icon: Icon(item.installed ? Icons.check : Icons.download),
            label: Text(item.installed ? '已安装' : '安装'),
          ),
        ],
      ),
    );
  }

  void _showAddScriptDialog(BuildContext context, UserScriptEngine engine) {
    final nameController = TextEditingController();
    final codeController = TextEditingController(text: '''// ==UserScript==
// @name         新脚本
// @namespace    browser.ninefyu
// @version      1.0.0
// @description  我的新脚本
// @match        *://*/*
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // 在这里写你的脚本
    console.log('Hello from my script!');
})();
''');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建脚本'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '脚本名称'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: TextField(
                  controller: codeController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '脚本代码',
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              engine.installFromSource(codeController.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditScriptDialog(
    BuildContext context,
    UserScript script,
    UserScriptEngine engine,
  ) {
    final codeController = TextEditingController(text: script.sourceCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 ${script.metadata.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SizedBox(
            height: 250,
            child: TextField(
              controller: codeController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '脚本代码',
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              engine.updateScript(script.id, codeController.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}