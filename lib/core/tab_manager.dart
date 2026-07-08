import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 浏览器标签页信息
class BrowserTab {
  final String id;
  final String title;
  final String url;
  final String? favicon;
  final bool isLoading;
  final double progress;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime? lastAccessed;

  BrowserTab({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.isLoading = false,
    this.progress = 0,
    this.isPrivate = false,
    DateTime? createdAt,
    this.lastAccessed,
  }) : createdAt = createdAt ?? DateTime.now();

  BrowserTab copyWith({
    String? id,
    String? title,
    String? url,
    String? favicon,
    bool? isLoading,
    double? progress,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? lastAccessed,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      favicon: favicon ?? this.favicon,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}

/// 标签页管理器
class TabManager extends StateNotifier<List<BrowserTab>> {
  int _currentIndex = 0;
  int _tabCounter = 0;

  TabManager() : super([]) {
    _initializeWithDefaultTab();
  }

  void _initializeWithDefaultTab() {
    final tab = BrowserTab(
      id: 'tab_${_tabCounter++}',
      title: '新标签页',
      url: 'about:blank',
    );
    state = [tab];
    _currentIndex = 0;
  }

  int get currentIndex => _currentIndex;

  BrowserTab? get currentTab {
    if (state.isEmpty || _currentIndex >= state.length) return null;
    return state[_currentIndex];
  }

  /// 新建标签页
  String newTab({String? url, String? title, bool isPrivate = false}) {
    final tab = BrowserTab(
      id: 'tab_${_tabCounter++}',
      title: title ?? (url == null || url == 'about:blank' ? '新标签页' : url),
      url: url ?? 'about:blank',
      isPrivate: isPrivate,
    );

    final newState = List<BrowserTab>.from(state);
    newState.insert(_currentIndex + 1, tab);
    state = newState;
    _currentIndex++;
    return tab.id;
  }

  /// 关闭标签页
  void closeTab(String tabId) {
    final index = state.indexWhere((t) => t.id == tabId);
    if (index == -1) return;

    final newState = List<BrowserTab>.from(state);
    newState.removeAt(index);

    if (newState.isEmpty) {
      // 关闭最后一个标签时，新建一个
      final tab = BrowserTab(
        id: 'tab_${_tabCounter++}',
        title: '新标签页',
        url: 'about:blank',
      );
      newState.add(tab);
      _currentIndex = 0;
    } else {
      if (_currentIndex >= index) {
        _currentIndex = (_currentIndex - 1).clamp(0, newState.length - 1);
      }
    }

    state = newState;
  }

  /// 切换标签页
  void switchToTab(int index) {
    if (index < 0 || index >= state.length) return;
    _currentIndex = index;
    state = List<BrowserTab>.from(state);
  }

  /// 更新标签页信息
  void updateTab(String tabId, {
    String? title,
    String? url,
    String? favicon,
    bool? isLoading,
    double? progress,
  }) {
    final index = state.indexWhere((t) => t.id == tabId);
    if (index == -1) return;

    final newState = List<BrowserTab>.from(state);
    newState[index] = newState[index].copyWith(
      title: title,
      url: url,
      favicon: favicon,
      isLoading: isLoading,
      progress: progress,
      lastAccessed: DateTime.now(),
    );
    state = newState;
  }

  /// 更新当前标签页
  void updateCurrentTab({
    String? title,
    String? url,
    String? favicon,
    bool? isLoading,
    double? progress,
  }) {
    final tab = currentTab;
    if (tab == null) return;
    updateTab(tab.id,
      title: title,
      url: url,
      favicon: favicon,
      isLoading: isLoading,
      progress: progress,
    );
  }

  /// 刷新当前标签页
  void refreshCurrentTab() {
    final tab = currentTab;
    if (tab == null) return;
    updateCurrentTab(isLoading: true, progress: 0);
  }

  /// 停止加载
  void stopCurrentTab() {
    final tab = currentTab;
    if (tab == null) return;
    updateCurrentTab(isLoading: false, progress: 0);
  }

  /// 关闭所有标签
  void closeAllTabs() {
    final tab = BrowserTab(
      id: 'tab_${_tabCounter++}',
      title: '新标签页',
      url: 'about:blank',
    );
    state = [tab];
    _currentIndex = 0;
  }

  /// 获取所有标签
  List<BrowserTab> get allTabs => List.unmodifiable(state);

  /// 标签数量
  int get tabCount => state.length;
}

final tabManagerProvider = StateNotifierProvider<TabManager, List<BrowserTab>>((ref) {
  return TabManager();
});