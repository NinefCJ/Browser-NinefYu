import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 可屏蔽的页面组件
enum PageComponent {
  navigationBar,    // 底部导航栏
  topBar,           // 顶部地址栏
  progressBar,      // 进度条
  tabBar,           // 标签栏
  floatingAction,   // 悬浮按钮
  findInPage,       // 页面查找
  shareButton,      // 分享按钮
  bookmarkButton,   // 收藏按钮
  backButton,       // 后退按钮
  forwardButton,    // 前进按钮
  menuButton,       // 菜单按钮
  homeButton,       // 主页按钮
  tabsButton,       // 标签页按钮
  moreButton,       // 更多按钮
}

/// 组件屏蔽状态
class ComponentBlockState {
  final Map<PageComponent, bool> blockedComponents;
  final bool immersiveMode;
  final bool autoHideBars;
  final int autoHideDelay;
  final bool fullscreenMode;

  ComponentBlockState({
    Map<PageComponent, bool>? blockedComponents,
    this.immersiveMode = false,
    this.autoHideBars = false,
    this.autoHideDelay = 3000,
    this.fullscreenMode = false,
  }) : blockedComponents = blockedComponents ?? {};

  bool isBlocked(PageComponent component) {
    return blockedComponents[component] ?? false;
  }

  ComponentBlockState copyWith({
    Map<PageComponent, bool>? blockedComponents,
    bool? immersiveMode,
    bool? autoHideBars,
    int? autoHideDelay,
    bool? fullscreenMode,
  }) {
    return ComponentBlockState(
      blockedComponents: blockedComponents ?? this.blockedComponents,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      autoHideBars: autoHideBars ?? this.autoHideBars,
      autoHideDelay: autoHideDelay ?? this.autoHideDelay,
      fullscreenMode: fullscreenMode ?? this.fullscreenMode,
    );
  }
}

class ComponentBlockManager extends StateNotifier<ComponentBlockState> {
  ComponentBlockManager() : super(ComponentBlockState());

  /// 屏蔽/启用组件
  void toggleComponent(PageComponent component) {
    final newMap = Map<PageComponent, bool>.from(state.blockedComponents);
    newMap[component] = !(newMap[component] ?? false);
    state = state.copyWith(blockedComponents: newMap);
  }

  /// 设置组件状态
  void setComponentBlocked(PageComponent component, bool blocked) {
    final newMap = Map<PageComponent, bool>.from(state.blockedComponents);
    newMap[component] = blocked;
    state = state.copyWith(blockedComponents: newMap);
  }

  /// 切换沉浸模式
  void toggleImmersiveMode() {
    state = state.copyWith(immersiveMode: !state.immersiveMode);
    if (state.immersiveMode) {
      final newMap = Map<PageComponent, bool>.from(state.blockedComponents);
      newMap[PageComponent.topBar] = true;
      newMap[PageComponent.navigationBar] = true;
      state = state.copyWith(blockedComponents: newMap);
    }
  }

  /// 切换自动隐藏
  void toggleAutoHide() {
    state = state.copyWith(autoHideBars: !state.autoHideBars);
  }

  /// 设置自动隐藏延迟
  void setAutoHideDelay(int milliseconds) {
    state = state.copyWith(autoHideDelay: milliseconds.clamp(1000, 10000));
  }

  /// 切换全屏模式
  void toggleFullscreen() {
    state = state.copyWith(fullscreenMode: !state.fullscreenMode);
  }

  /// 应用预设布局
  void applyPreset(LayoutPreset preset) {
    final newMap = <PageComponent, bool>{};
    switch (preset) {
      case LayoutPreset.minimal:
        newMap[PageComponent.floatingAction] = true;
        newMap[PageComponent.shareButton] = true;
        newMap[PageComponent.bookmarkButton] = true;
        newMap[PageComponent.moreButton] = true;
        break;
      case LayoutPreset.immersive:
        newMap[PageComponent.topBar] = true;
        newMap[PageComponent.navigationBar] = true;
        newMap[PageComponent.tabBar] = true;
        break;
      case LayoutPreset.normal:
        newMap.clear();
        break;
      case LayoutPreset.reading:
        newMap[PageComponent.navigationBar] = true;
        newMap[PageComponent.floatingAction] = true;
        newMap[PageComponent.tabsButton] = true;
        break;
    }
    state = state.copyWith(blockedComponents: newMap);
  }

  /// 重置所有组件
  void resetAll() {
    state = ComponentBlockState();
  }
}

enum LayoutPreset {
  normal,
  minimal,
  immersive,
  reading,
}

extension LayoutPresetExtension on LayoutPreset {
  String get name {
    switch (this) {
      case LayoutPreset.normal:
        return '标准布局';
      case LayoutPreset.minimal:
        return '极简布局';
      case LayoutPreset.immersive:
        return '沉浸布局';
      case LayoutPreset.reading:
        return '阅读布局';
    }
  }

  String get description {
    switch (this) {
      case LayoutPreset.normal:
        return '显示所有组件';
      case LayoutPreset.minimal:
        return '隐藏部分按钮，界面更简洁';
      case LayoutPreset.immersive:
        return '隐藏上下栏，沉浸阅读';
      case LayoutPreset.reading:
        return '隐藏导航栏，专注阅读';
    }
  }
}

final componentBlockProvider =
    StateNotifierProvider<ComponentBlockManager, ComponentBlockState>((ref) {
  return ComponentBlockManager();
});