import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 启动任务类型
enum StartupTaskType {
  openUrl,
  openTabs,
  clearCache,
  clearHistory,
  setUa,
  setTheme,
  runScript,
  refreshBookmarks,
  checkUpdates,
  syncData,
}

/// 启动任务
class StartupTask {
  final String id;
  final String name;
  final StartupTaskType type;
  final bool enabled;
  final int order;
  final String? data;
  final bool runOnForeground;

  StartupTask({
    required this.id,
    required this.name,
    required this.type,
    this.enabled = true,
    this.order = 0,
    this.data,
    this.runOnForeground = true,
  });

  StartupTask copyWith({
    String? id,
    String? name,
    StartupTaskType? type,
    bool? enabled,
    int? order,
    String? data,
    bool? runOnForeground,
  }) {
    return StartupTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      data: data ?? this.data,
      runOnForeground: runOnForeground ?? this.runOnForeground,
    );
  }
}

/// 启动任务状态
class StartupTaskState {
  final List<StartupTask> tasks;
  final bool enabled;
  final bool showStartupProgress;
  final int startupDelay;
  final bool isRunning;
  final int currentTaskIndex;

  StartupTaskState({
    this.tasks = const [],
    this.enabled = false,
    this.showStartupProgress = true,
    this.startupDelay = 0,
    this.isRunning = false,
    this.currentTaskIndex = 0,
  });

  StartupTaskState copyWith({
    List<StartupTask>? tasks,
    bool? enabled,
    bool? showStartupProgress,
    int? startupDelay,
    bool? isRunning,
    int? currentTaskIndex,
  }) {
    return StartupTaskState(
      tasks: tasks ?? this.tasks,
      enabled: enabled ?? this.enabled,
      showStartupProgress: showStartupProgress ?? this.showStartupProgress,
      startupDelay: startupDelay ?? this.startupDelay,
      isRunning: isRunning ?? this.isRunning,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
    );
  }
}

class StartupTaskManager extends StateNotifier<StartupTaskState> {
  StartupTaskManager() : super(StartupTaskState()) {
    _loadDefaultTasks();
  }

  void _loadDefaultTasks() {
    final defaults = [
      StartupTask(id: 'task_clearcache', name: '清除缓存', type: StartupTaskType.clearCache, enabled: false, order: 1),
      StartupTask(id: 'task_refresh_bookmarks', name: '刷新书签', type: StartupTaskType.refreshBookmarks, enabled: true, order: 2),
      StartupTask(id: 'task_check_updates', name: '检查更新', type: StartupTaskType.checkUpdates, enabled: true, order: 3),
      StartupTask(id: 'task_homepage', name: '打开主页', type: StartupTaskType.openUrl, enabled: true, order: 4, data: 'about:blank'),
    ];
    state = state.copyWith(tasks: defaults);
  }

  /// 启用/禁用启动任务
  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  /// 切换任务启用状态
  void toggleTask(String taskId) {
    final newList = state.tasks.map((t) {
      if (t.id == taskId) return t.copyWith(enabled: !t.enabled);
      return t;
    }).toList();
    state = state.copyWith(tasks: newList);
  }

  /// 添加任务
  void addTask(StartupTask task) {
    final newList = List<StartupTask>.from(state.tasks);
    newList.add(task.copyWith(order: newList.length));
    state = state.copyWith(tasks: newList);
  }

  /// 移除任务
  void removeTask(String taskId) {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
    );
  }

  /// 重新排序
  void reorderTask(String taskId, int newOrder) {
    final tasks = List<StartupTask>.from(state.tasks);
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = tasks.removeAt(index);
    final insertIndex = newOrder.clamp(0, tasks.length);
    tasks.insert(insertIndex, task);

    for (var i = 0; i < tasks.length; i++) {
      tasks[i] = tasks[i].copyWith(order: i);
    }

    state = state.copyWith(tasks: tasks);
  }

  /// 执行启动任务
  Future<void> runStartupTasks() async {
    if (!state.enabled) return;

    final enabledTasks = state.tasks
        .where((t) => t.enabled)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    state = state.copyWith(isRunning: true, currentTaskIndex: 0);

    if (state.startupDelay > 0) {
      await Future.delayed(Duration(milliseconds: state.startupDelay));
    }

    for (var i = 0; i < enabledTasks.length; i++) {
      state = state.copyWith(currentTaskIndex: i);
      await _executeTask(enabledTasks[i]);
    }

    state = state.copyWith(isRunning: false);
  }

  Future<void> _executeTask(StartupTask task) async {
    switch (task.type) {
      case StartupTaskType.openUrl:
        break;
      case StartupTaskType.openTabs:
        break;
      case StartupTaskType.clearCache:
        break;
      case StartupTaskType.clearHistory:
        break;
      case StartupTaskType.setUa:
        break;
      case StartupTaskType.setTheme:
        break;
      case StartupTaskType.runScript:
        break;
      case StartupTaskType.refreshBookmarks:
        break;
      case StartupTaskType.checkUpdates:
        break;
      case StartupTaskType.syncData:
        break;
    }
  }

  /// 设置启动延迟
  void setStartupDelay(int milliseconds) {
    state = state.copyWith(startupDelay: milliseconds.clamp(0, 5000));
  }

  /// 切换启动进度显示
  void toggleShowProgress() {
    state = state.copyWith(showStartupProgress: !state.showStartupProgress);
  }
}

final startupTaskProvider =
    StateNotifierProvider<StartupTaskManager, StartupTaskState>((ref) {
  return StartupTaskManager();
});