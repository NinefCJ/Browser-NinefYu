import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/settings_service.dart';
import 'core/tab_manager.dart';
import 'features/customization/theme_engine.dart';
import 'features/customization/customization_center_page.dart';
import 'features/downloader/download_manager_page.dart';
import 'features/downloader/vpn_resilience_monitor_page.dart';
import 'features/adblock/adblock_settings_page.dart';
import 'features/script/user_scripts_page.dart';

/// 浏览器主页面
class BrowserHomePage extends ConsumerStatefulWidget {
  const BrowserHomePage({super.key});

  @override
  ConsumerState<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends ConsumerState<BrowserHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  bool _showMenu = false;

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabManagerProvider);
    final tabManager = ref.read(tabManagerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final theme = ref.watch(themeEngineProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        elevation: theme.elevation,
        title: _buildUrlBar(tabManager),
        actions: [
          IconButton(
            icon: const Icon(Icons.tabs),
            tooltip: '标签页 (${tabState.length})',
            onPressed: () => _showTabDrawer(context, tabState, tabManager),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '菜单',
            onPressed: () => _showBottomMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          if (tabManager.currentTab?.isLoading ?? false)
            LinearProgressIndicator(
              value: tabManager.currentTab?.progress ?? 0,
              backgroundColor: Colors.transparent,
              minHeight: 2,
            ),
          // 主内容区
          Expanded(
            child: _buildBrowserContent(tabManager),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(tabManager),
    );
  }

  Widget _buildUrlBar(TabManager tabManager) {
    final currentTab = tabManager.currentTab;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '搜索或输入网址',
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (value) => _navigateToUrl(value, tabManager),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: _urlController.clear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildBrowserContent(TabManager tabManager) {
    final currentTab = tabManager.currentTab;

    if (currentTab == null || currentTab.url == 'about:blank') {
      return _buildHomePage(tabManager);
    }

    // 实际项目中这里是 WebView
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.web, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('正在加载: ${currentTab.url}'),
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildHomePage(TabManager tabManager) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷访问',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildQuickAccessGrid(tabManager),
          const SizedBox(height: 24),
          const Text(
            '功能中心',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(TabManager tabManager) {
    final sites = [
      {'name': 'Google', 'url': 'https://www.google.com', 'color': Colors.blue},
      {'name': 'GitHub', 'url': 'https://github.com', 'color': Colors.black87},
      {'name': '百度', 'url': 'https://www.baidu.com', 'color': Colors.blue},
      {'name': 'B站', 'url': 'https://www.bilibili.com', 'color': Colors.pink},
      {'name': '知乎', 'url': 'https://www.zhihu.com', 'color': Colors.blue},
      {'name': '微博', 'url': 'https://weibo.com', 'color': Colors.red},
      {'name': '淘宝', 'url': 'https://www.taobao.com', 'color': Colors.orange},
      {'name': '京东', 'url': 'https://www.jd.com', 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: sites.length,
      itemBuilder: (context, index) {
        final site = sites[index];
        return GestureDetector(
          onTap: () {
            tabManager.updateCurrentTab(url: site['url'] as String, isLoading: true);
            _urlController.text = site['url'] as String;
          },
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (site['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    site['name'].toString()[0],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: site['color'] as Color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(site['name'] as String, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'name': '下载管理', 'icon': Icons.download, 'color': Colors.blue, 'route': '/downloads'},
      {'name': 'VPN韧性', 'icon': Icons.vpn_lock, 'color': Colors.green, 'route': '/vpn'},
      {'name': '客制化', 'icon': Icons.palette, 'color': Colors.purple, 'route': '/customization'},
      {'name': '广告拦截', 'icon': Icons.block, 'color': Colors.red, 'route': '/adblock'},
      {'name': '脚本管理', 'icon': Icons.extension, 'color': Colors.orange, 'route': '/scripts'},
      {'name': '书签历史', 'icon': Icons.bookmark, 'color': Colors.teal, 'route': '/bookmarks'},
      {'name': '阅读模式', 'icon': Icons.chrome_reader_mode, 'color': Colors.brown, 'route': '/reader'},
      {'name': '隐私模式', 'icon': Icons.privacy_tip, 'color': Colors.grey, 'route': '/private'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return GestureDetector(
          onTap: () => _navigateTo(feature['route'] as String),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (feature['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature['icon'] as IconData, color: feature['color'] as Color),
              ),
              const SizedBox(height: 6),
              Text(feature['name'] as String, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(TabManager tabManager) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {},
            tooltip: '后退',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {},
            tooltip: '前进',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              tabManager.updateCurrentTab(url: 'about:blank', isLoading: false);
              _urlController.clear();
            },
            tooltip: '主页',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tabManager.refreshCurrentTab(),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showBottomMenu(context),
            tooltip: '菜单',
          ),
        ],
      ),
    );
  }

  void _navigateToUrl(String url, TabManager tabManager) {
    if (url.isEmpty) return;

    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        finalUrl = 'https://$url';
      } else {
        finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }

    tabManager.updateCurrentTab(
      url: finalUrl,
      title: url,
      isLoading: true,
      progress: 0,
    );
    _urlController.text = finalUrl;
  }

  void _showTabDrawer(BuildContext context, List<dynamic> tabs, TabManager manager) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('标签页 (${tabs.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        manager.newTab();
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: () {
                        manager.closeAllTabs();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabs[index] as dynamic;
                  final isCurrent = index == manager.currentIndex;
                  return ListTile(
                    leading: CircleAvatar(radius: 16, child: Text(tab.title[0])),
                    title: Text(tab.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(tab.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    trailing: isCurrent ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      manager.switchToTab(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('下载管理'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/downloads');
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_lock),
              title: const Text('VPN韧性监控'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/vpn');
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('客制化中心'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/customization');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('广告拦截'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/adblock');
              },
            ),
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('用户脚本'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/scripts');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('书签/历史'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('隐私模式'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('夜间模式'),
              onTap: () {
                ref.read(themeEngineProvider.notifier).toggleDarkMode();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String route) {
    Widget page;
    switch (route) {
      case '/downloads':
        page = const DownloadManagerPage();
        break;
      case '/vpn':
        page = const VpnResilienceMonitorPage();
        break;
      case '/customization':
        page = const CustomizationCenterPage();
        break;
      case '/adblock':
        page = const AdBlockSettingsPage();
        break;
      case '/scripts':
        page = const UserScriptsPage();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}