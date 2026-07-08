import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 快捷命令
class QuickCommand {
  final String id;
  final String name;
  final String shortcut;
  final String description;
  final CommandAction action;
  final String? url;
  final bool enabled;

  QuickCommand({
    required this.id,
    required this.name,
    required this.shortcut,
    this.description = '',
    required this.action,
    this.url,
    this.enabled = true,
  });

  QuickCommand copyWith({
    String? id,
    String? name,
    String? shortcut,
    String? description,
    CommandAction? action,
    String? url,
    bool? enabled,
  }) {
    return QuickCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      shortcut: shortcut ?? this.shortcut,
      description: description ?? this.description,
      action: action ?? this.action,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// 命令动作类型
enum CommandAction {
  openUrl,
  newTab,
  closeTab,
  reload,
  back,
  forward,
  home,
  findInPage,
  toggleAdBlock,
  toggleDarkMode,
  togglePrivateMode,
  toggleDesktopMode,
  screenshot,
  share,
  bookmark,
  search,
  translate,
  readMode,
  zoomIn,
  zoomOut,
  scrollTop,
  scrollBottom,
  fullscreen,
  quit,
}

extension CommandActionExtension on CommandAction {
  String get displayName {
    switch (this) {
      case CommandAction.openUrl: return '打开网址';
      case CommandAction.newTab: return '新建标签';
      case CommandAction.closeTab: return '关闭标签';
      case CommandAction.reload: return '刷新页面';
      case CommandAction.back: return '后退';
      case CommandAction.forward: return '前进';
      case CommandAction.home: return '回到主页';
      case CommandAction.findInPage: return '页面查找';
      case CommandAction.toggleAdBlock: return '切换广告拦截';
      case CommandAction.toggleDarkMode: return '切换夜间模式';
      case CommandAction.togglePrivateMode: return '切换隐私模式';
      case CommandAction.toggleDesktopMode: return '切换桌面模式';
      case CommandAction.screenshot: return '截图';
      case CommandAction.share: return '分享';
      case CommandAction.bookmark: return '收藏/取消';
      case CommandAction.search: return '搜索';
      case CommandAction.translate: return '翻译';
      case CommandAction.readMode: return '阅读模式';
      case CommandAction.zoomIn: return '放大';
      case CommandAction.zoomOut: return '缩小';
      case CommandAction.scrollTop: return '滚动到顶部';
      case CommandAction.scrollBottom: return '滚动到底部';
      case CommandAction.fullscreen: return '全屏';
      case CommandAction.quit: return '退出';
    }
  }
}

/// 快捷命令管理状态
class QuickCommandState {
  final List<QuickCommand> commands;
  final bool enabled;
  final String triggerKey;
  final int maxSuggestions;
  final List<String> recentCommands;

  QuickCommandState({
    this.commands = const [],
    this.enabled = true,
    this.triggerKey = ':',
    this.maxSuggestions = 8,
    this.recentCommands = const [],
  });

  QuickCommandState copyWith({
    List<QuickCommand>? commands,
    bool? enabled,
    String? triggerKey,
    int? maxSuggestions,
    List<String>? recentCommands,
  }) {
    return QuickCommandState(
      commands: commands ?? this.commands,
      enabled: enabled ?? this.enabled,
      triggerKey: triggerKey ?? this.triggerKey,
      maxSuggestions: maxSuggestions ?? this.maxSuggestions,
      recentCommands: recentCommands ?? this.recentCommands,
    );
  }
}

class QuickCommandManager extends StateNotifier<QuickCommandState> {
  QuickCommandManager() : super(QuickCommandState()) {
    _loadDefaultCommands();
  }

  void _loadDefaultCommands() {
    final defaults = [
      QuickCommand(id: 'cmd_reload', name: '刷新', shortcut: 'r', action: CommandAction.reload, description: '刷新当前页面'),
      QuickCommand(id: 'cmd_back', name: '后退', shortcut: 'b', action: CommandAction.back, description: '返回上一页'),
      QuickCommand(id: 'cmd_forward', name: '前进', shortcut: 'f', action: CommandAction.forward, description: '前进到下一页'),
      QuickCommand(id: 'cmd_newtab', name: '新标签', shortcut: 't', action: CommandAction.newTab, description: '打开新标签页'),
      QuickCommand(id: 'cmd_closetab', name: '关闭标签', shortcut: 'c', action: CommandAction.closeTab, description: '关闭当前标签'),
      QuickCommand(id: 'cmd_home', name: '主页', shortcut: 'h', action: CommandAction.home, description: '回到主页'),
      QuickCommand(id: 'cmd_find', name: '查找', shortcut: '/', action: CommandAction.findInPage, description: '在页面中查找'),
      QuickCommand(id: 'cmd_dark', name: '夜间模式', shortcut: 'd', action: CommandAction.toggleDarkMode, description: '切换夜间模式'),
      QuickCommand(id: 'cmd_private', name: '隐私模式', shortcut: 'p', action: CommandAction.togglePrivateMode, description: '切换隐私模式'),
      QuickCommand(id: 'cmd_adblock', name: '广告拦截', shortcut: 'ad', action: CommandAction.toggleAdBlock, description: '切换广告拦截'),
      QuickCommand(id: 'cmd_bookmark', name: '收藏', shortcut: 'star', action: CommandAction.bookmark, description: '添加/移除书签'),
      QuickCommand(id: 'cmd_share', name: '分享', shortcut: 's', action: CommandAction.share, description: '分享当前页面'),
      QuickCommand(id: 'cmd_screenshot', name: '截图', shortcut: 'ss', action: CommandAction.screenshot, description: '页面截图'),
      QuickCommand(id: 'cmd_reader', name: '阅读模式', shortcut: 'read', action: CommandAction.readMode, description: '进入阅读模式'),
      QuickCommand(id: 'cmd_translate', name: '翻译', shortcut: 'tr', action: CommandAction.translate, description: '翻译当前页面'),
      QuickCommand(id: 'cmd_fullscreen', name: '全屏', shortcut: 'fs', action: CommandAction.fullscreen, description: '全屏浏览'),
      QuickCommand(id: 'cmd_top', name: '回到顶部', shortcut: 'top', action: CommandAction.scrollTop, description: '滚动到页面顶部'),
      QuickCommand(id: 'cmd_bottom', name: '回到底部', shortcut: 'bot', action: CommandAction.scrollBottom, description: '滚动到页面底部'),
      QuickCommand(id: 'cmd_zoomin', name: '放大', shortcut: '+', action: CommandAction.zoomIn, description: '放大页面'),
      QuickCommand(id: 'cmd_zoomout', name: '缩小', shortcut: '-', action: CommandAction.zoomOut, description: '缩小页面'),
      QuickCommand(id: 'cmd_desktop', name: '桌面模式', shortcut: 'pc', action: CommandAction.toggleDesktopMode, description: '切换桌面/移动模式'),
    ];
    state = state.copyWith(commands: defaults);
  }

  /// 搜索命令
  List<QuickCommand> search(String query) {
    if (query.isEmpty) {
      return state.commands.where((c) => c.enabled).take(state.maxSuggestions).toList();
    }

    final q = query.toLowerCase();
    return state.commands
        .where((c) =>
            c.enabled &&
            (c.name.toLowerCase().contains(q) ||
                c.shortcut.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) {
        final aStarts = a.shortcut.startsWith(q) || a.name.toLowerCase().startsWith(q);
        final bStarts = b.shortcut.startsWith(q) || b.name.toLowerCase().startsWith(q);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return 0;
      });
  }

  /// 执行命令
  void execute(String commandId) {
    // 记录最近使用
    final recent = List<String>.from(state.recentCommands);
    recent.remove(commandId);
    recent.insert(0, commandId);
    if (recent.length > 10) recent.removeLast();
    state = state.copyWith(recentCommands: recent);
  }

  /// 添加自定义命令
  void addCommand(QuickCommand command) {
    final newList = List<QuickCommand>.from(state.commands);
    newList.add(command);
    state = state.copyWith(commands: newList);
  }

  /// 移除命令
  void removeCommand(String id) {
    state = state.copyWith(
      commands: state.commands.where((c) => c.id != id).toList(),
    );
  }

  /// 切换命令启用状态
  void toggleCommand(String id) {
    final newList = state.commands.map((c) {
      if (c.id == id) return c.copyWith(enabled: !c.enabled);
      return c;
    }).toList();
    state = state.copyWith(commands: newList);
  }

  /// 启用/禁用快捷命令
  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  /// 设置触发键
  void setTriggerKey(String key) {
    state = state.copyWith(triggerKey: key);
  }
}

final quickCommandProvider =
    StateNotifierProvider<QuickCommandManager, QuickCommandState>((ref) {
  return QuickCommandManager();
});