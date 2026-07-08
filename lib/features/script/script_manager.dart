import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_script_engine.dart';

/// 脚本仓库项
class ScriptRepositoryItem {
  final String id;
  final String name;
  final String description;
  final String author;
  final String? version;
  final String? category;
  final String downloadUrl;
  final String? homepageUrl;
  final int downloads;
  final double rating;
  final List<String> matches;
  final String? installUrl;
  final DateTime? updatedAt;
  final bool installed;

  ScriptRepositoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    this.version,
    this.category,
    required this.downloadUrl,
    this.homepageUrl,
    this.downloads = 0,
    this.rating = 0.0,
    this.matches = const [],
    this.installUrl,
    this.updatedAt,
    this.installed = false,
  });

  ScriptRepositoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? version,
    String? category,
    String? downloadUrl,
    String? homepageUrl,
    int? downloads,
    double? rating,
    List<String>? matches,
    String? installUrl,
    DateTime? updatedAt,
    bool? installed,
  }) {
    return ScriptRepositoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      version: version ?? this.version,
      category: category ?? this.category,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      homepageUrl: homepageUrl ?? this.homepageUrl,
      downloads: downloads ?? this.downloads,
      rating: rating ?? this.rating,
      matches: matches ?? this.matches,
      installUrl: installUrl ?? this.installUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      installed: installed ?? this.installed,
    );
  }
}

/// 脚本仓库分类
class ScriptCategory {
  final String id;
  final String name;
  final String icon;
  final int count;

  ScriptCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.count = 0,
  });
}

/// 内置脚本仓库
class BuiltInScriptRepository {
  static final List<ScriptCategory> categories = [
    ScriptCategory(id: 'all', name: '全部', icon: '📋'),
    ScriptCategory(id: 'adblock', name: '广告拦截', icon: '🚫'),
    ScriptCategory(id: 'tools', name: '实用工具', icon: '🔧'),
    ScriptCategory(id: 'social', name: '社交增强', icon: '💬'),
    ScriptCategory(id: 'video', name: '视频增强', icon: '🎬'),
    ScriptCategory(id: 'download', name: '下载辅助', icon: '⬇️'),
    ScriptCategory(id: 'appearance', name: '外观美化', icon: '🎨'),
    ScriptCategory(id: 'productivity', name: '效率提升', icon: '⚡'),
  ];

  static final List<ScriptRepositoryItem> scripts = [
    // 广告拦截
    ScriptRepositoryItem(
      id: 'adblock_plus',
      name: '广告拦截增强',
      description: '补充过滤规则难以拦截的广告，自动识别并隐藏广告元素',
      author: 'NinefYu',
      version: '1.2.0',
      category: 'adblock',
      downloadUrl: '',
      downloads: 12580,
      rating: 4.8,
      matches: ['*://*/*'],
    ),
    ScriptRepositoryItem(
      id: 'anti_popup',
      name: '弹窗克星',
      description: '自动关闭各种弹窗、登录提示、会员推广',
      author: 'NinefYu',
      version: '1.0.3',
      category: 'adblock',
      downloadUrl: '',
      downloads: 9870,
      rating: 4.7,
      matches: ['*://*/*'],
    ),

    // 实用工具
    ScriptRepositoryItem(
      id: 'auto_expand',
      name: '自动展开全文',
      description: '自动点击"展开全文""查看更多"按钮，不用手动点',
      author: 'NinefYu',
      version: '2.1.0',
      category: 'tools',
      downloadUrl: '',
      downloads: 15680,
      rating: 4.9,
      matches: ['*://*.baidu.com/*', '*://*.weibo.com/*', '*://*.zhihu.com/*'],
    ),
    ScriptRepositoryItem(
      id: 'shortcut_manager',
      name: '快捷键管理器',
      description: '自定义网页快捷键，支持常用操作的键盘快捷方式',
      author: 'NinefYu',
      version: '1.5.2',
      category: 'tools',
      downloadUrl: '',
      downloads: 7650,
      rating: 4.6,
      matches: ['*://*/*'],
    ),
    ScriptRepositoryItem(
      id: 'dark_mode_enhancer',
      name: '夜间模式增强',
      description: '为所有网站提供更舒适的夜间模式，保护眼睛',
      author: 'NinefYu',
      version: '3.0.0',
      category: 'appearance',
      downloadUrl: '',
      downloads: 21340,
      rating: 4.9,
      matches: ['*://*/*'],
    ),

    // 视频增强
    ScriptRepositoryItem(
      id: 'video_speed_controller',
      name: '视频倍速控制器',
      description: '支持任意视频网站倍速播放，0.25x 到 4x',
      author: 'NinefYu',
      version: '2.3.1',
      category: 'video',
      downloadUrl: '',
      downloads: 18760,
      rating: 4.8,
      matches: ['*://*.bilibili.com/*', '*://*.youtube.com/*', '*://*.youku.com/*'],
    ),
    ScriptRepositoryItem(
      id: 'video_screenshot',
      name: '视频截图工具',
      description: '一键截取视频画面，支持精确帧控制',
      author: 'NinefYu',
      version: '1.1.0',
      category: 'video',
      downloadUrl: '',
      downloads: 5430,
      rating: 4.5,
      matches: ['*://*.bilibili.com/*', '*://*.youtube.com/*'],
    ),

    // 下载辅助
    ScriptRepositoryItem(
      id: 'm3u8_sniffer',
      name: 'M3U8嗅探器',
      description: '自动检测页面中的m3u8视频地址，一键下载',
      author: 'NinefYu',
      version: '1.4.0',
      category: 'download',
      downloadUrl: '',
      downloads: 11250,
      rating: 4.7,
      matches: ['*://*/*'],
    ),
    ScriptRepositoryItem(
      id: 'image_batch_download',
      name: '图片批量下载',
      description: '一键下载页面所有图片，支持筛选尺寸和格式',
      author: 'NinefYu',
      version: '1.2.1',
      category: 'download',
      downloadUrl: '',
      downloads: 8760,
      rating: 4.6,
      matches: ['*://*/*'],
    ),

    // 社交增强
    ScriptRepositoryItem(
      id: 'social_cleaner',
      name: '社交平台净化',
      description: '隐藏热搜、推荐等干扰内容，专注阅读',
      author: 'NinefYu',
      version: '2.0.0',
      category: 'social',
      downloadUrl: '',
      downloads: 13450,
      rating: 4.8,
      matches: ['*://*.weibo.com/*', '*://*.zhihu.com/*', '*://*.douban.com/*'],
    ),

    // 效率提升
    ScriptRepositoryItem(
      id: 'auto_next_page',
      name: '自动翻页',
      description: '滚动到底部自动加载下一页，不用手动点分页',
      author: 'NinefYu',
      version: '1.3.0',
      category: 'productivity',
      downloadUrl: '',
      downloads: 9870,
      rating: 4.7,
      matches: ['*://*/*'],
    ),
    ScriptRepositoryItem(
      id: 'reader_mode_plus',
      name: '阅读模式增强',
      description: '提取文章正文，去除干扰元素，专注阅读',
      author: 'NinefYu',
      version: '2.2.0',
      category: 'productivity',
      downloadUrl: '',
      downloads: 16540,
      rating: 4.9,
      matches: ['*://*/*'],
    ),
    ScriptRepositoryItem(
      id: 'translate_helper',
      name: '翻译助手',
      description: '划词翻译，支持多语言，可配置翻译引擎',
      author: 'NinefYu',
      version: '1.6.0',
      category: 'productivity',
      downloadUrl: '',
      downloads: 14320,
      rating: 4.8,
      matches: ['*://*/*'],
    ),
  ];
}

/// 脚本管理器状态
class ScriptManagerState {
  final List<ScriptRepositoryItem> repository;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String searchQuery;
  final List<ScriptRepositoryItem> searchResults;

  ScriptManagerState({
    this.repository = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = 'all',
    this.searchQuery = '',
    this.searchResults = const [],
  });

  ScriptManagerState copyWith({
    List<ScriptRepositoryItem>? repository,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? searchQuery,
    List<ScriptRepositoryItem>? searchResults,
  }) {
    return ScriptManagerState(
      repository: repository ?? this.repository,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

/// 脚本管理器
class ScriptManager extends StateNotifier<ScriptManagerState> {
  final Dio _dio;
  final UserScriptEngine _scriptEngine;

  ScriptManager(this._dio, this._scriptEngine)
      : super(ScriptManagerState(repository: BuiltInScriptRepository.scripts));

  /// 按分类获取脚本
  List<ScriptRepositoryItem> getScriptsByCategory(String categoryId) {
    if (categoryId == 'all') {
      return state.repository;
    }
    return state.repository.where((s) => s.category == categoryId).toList();
  }

  /// 搜索脚本
  void searchScripts(String query) {
    if (query.isEmpty) {
      state = state.copyWith(searchQuery: '', searchResults: []);
      return;
    }

    final results = state.repository.where((script) {
      return script.name.toLowerCase().contains(query.toLowerCase()) ||
          script.description.toLowerCase().contains(query.toLowerCase()) ||
          script.author.toLowerCase().contains(query.toLowerCase());
    }).toList();

    state = state.copyWith(searchQuery: query, searchResults: results);
  }

  /// 安装脚本
  Future<UserScript?> installScript(String scriptId) async {
    final repoItem = state.repository.firstWhere((s) => s.id == scriptId);

    try {
      // 如果有下载URL，从远程下载脚本
      if (repoItem.downloadUrl.isNotEmpty) {
        final response = await _dio.get<String>(repoItem.downloadUrl,
            options: Options(responseType: ResponseType.plain));

        if (response.data != null) {
          final script = _scriptEngine.installFromSource(response.data!);
          _markInstalled(scriptId);
          return script;
        }
      }

      // 没有URL的话，生成一个示例脚本
      final demoSource = _generateDemoScript(repoItem);
      final script = _scriptEngine.installFromSource(demoSource);
      _markInstalled(scriptId);
      return script;
    } catch (e) {
      state = state.copyWith(errorMessage: '安装失败: $e');
      return null;
    }
  }

  void _markInstalled(String scriptId) {
    final updated = state.repository.map((s) {
      if (s.id == scriptId) {
        return s.copyWith(installed: true, downloads: s.downloads + 1);
      }
      return s;
    }).toList();
    state = state.copyWith(repository: updated);
  }

  /// 生成示例脚本代码
  String _generateDemoScript(ScriptRepositoryItem item) {
    final matchStr = item.matches.isNotEmpty
        ? item.matches.map((m) => '// @match        $m').join('\n')
        : '// @match        *://*/*';

    return '''
// ==UserScript==
// @name         ${item.name}
// @namespace    browser.ninefyu
// @version      ${item.version ?? '1.0.0'}
// @description  ${item.description}
// @author       ${item.author}
$matchStr
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // ${item.name} 已加载
    // 这是一个示例脚本，请根据需要修改
    console.log('[${item.name}] Script loaded');
})();
''';
  }

  /// 卸载脚本
  void uninstallScript(String scriptId) {
    _scriptEngine.removeScript(scriptId);

    final updated = state.repository.map((s) {
      if (s.id == scriptId) {
        return s.copyWith(installed: false);
      }
      return s;
    }).toList();
    state = state.copyWith(repository: updated);
  }

  /// 检查脚本更新
  Future<bool> checkForUpdates(String scriptId) async {
    // 实际实现中应比较版本号
    return false;
  }

  /// 刷新脚本仓库
  Future<void> refreshRepository() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 实际实现中从服务器获取最新脚本列表
      await Future.delayed(Duration(milliseconds: 500));

      // 更新已安装状态
      final installedIds = _scriptEngine.state.scripts.map((s) => s.id).toSet();
      final updated = state.repository.map((s) {
        return s.copyWith(installed: installedIds.contains(s.id));
      }).toList();

      state = state.copyWith(repository: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '刷新失败: $e',
      );
    }
  }

  /// 选择分类
  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategory: categoryId);
  }
}

final scriptManagerProvider =
    StateNotifierProvider<ScriptManager, ScriptManagerState>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
  ));
  final scriptEngine = ref.read(userScriptEngineProvider.notifier);
  return ScriptManager(dio, scriptEngine);
});