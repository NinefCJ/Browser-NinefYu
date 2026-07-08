import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_engine.dart';
import 'ua_manager.dart';
import 'component_block.dart';
import 'privacy_lock.dart';
import 'quick_commands.dart';
import 'startup_tasks.dart';
import 'video_controller.dart';

/// 客制化中心页面
class CustomizationCenterPage extends ConsumerStatefulWidget {
  const CustomizationCenterPage({super.key});

  @override
  ConsumerState<CustomizationCenterPage> createState() => _CustomizationCenterPageState();
}

class _CustomizationCenterPageState extends ConsumerState<CustomizationCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客制化中心'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: '主题'),
            Tab(icon: Icon(Icons.language), text: 'UA'),
            Tab(icon: Icon(Icons.visibility_off), text: '组件'),
            Tab(icon: Icon(Icons.lock), text: '隐私锁'),
            Tab(icon: Icon(Icons.flash_on), text: '快捷命令'),
            Tab(icon: Icon(Icons.tune), text: '更多'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThemeTab(),
          _buildUATab(),
          _buildComponentTab(),
          _buildPrivacyLockTab(),
          _buildQuickCommandTab(),
          _buildMoreTab(),
        ],
      ),
    );
  }

  Widget _buildThemeTab() {
    final theme = ref.watch(themeEngineProvider);
    final themeNotifier = ref.read(themeEngineProvider.notifier);

    return ListView(
      children: [
        const ListTile(title: Text('主题预设', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: ThemePresets.presets.length,
            itemBuilder: (context, index) {
              final preset = ThemePresets.presets[index];
              final isSelected = themeNotifier.currentPreset == index;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => themeNotifier.applyPreset(index),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(preset.primary),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(preset.accent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(preset.name, style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('深色模式'),
          trailing: Switch(
            value: theme.mode == AppThemeMode.dark,
            onChanged: (_) => themeNotifier.toggleDarkMode(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('莫奈取色'),
          subtitle: const Text('从网页取色生成主题'),
          trailing: Switch(
            value: theme.useMonet,
            onChanged: (v) {
              themeNotifier.applyMonet(theme.primaryColor);
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.rem),
          title: Text('圆角大小: ${theme.borderRadius.toInt()}'),
          subtitle: Slider(
            value: theme.borderRadius,
            min: 0,
            max: 24,
            onChanged: (v) => themeNotifier.setBorderRadius(v),
          ),
          trailing: null,
        ),
        const Divider(),
        const ListTile(title: Text('护眼模式', style: TextStyle(fontWeight: FontWeight.bold))),
        ListTile(
          leading: const Icon(Icons.eye),
          title: const Text('护眼模式'),
          trailing: Switch(
            value: themeNotifier.eyeCareMode.enabled,
            onChanged: (_) => themeNotifier.toggleEyeCare(),
          ),
        ),
        ListTile(
          title: Text('暖度: ${(themeNotifier.eyeCareMode.warmth * 100).toInt()}%'),
          subtitle: Slider(
            value: themeNotifier.eyeCareMode.warmth,
            onChanged: themeNotifier.eyeCareMode.enabled ? themeNotifier.setEyeCareWarmth : null,
          ),
        ),
        ListTile(
          title: Text('亮度: ${(themeNotifier.eyeCareMode.brightness * 100).toInt()}%'),
          subtitle: Slider(
            value: themeNotifier.eyeCareMode.brightness,
            min: 0.3,
            max: 1.0,
            onChanged: themeNotifier.eyeCareMode.enabled ? themeNotifier.setEyeCareBrightness : null,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('自动护眼'),
          subtitle: const Text('夜间自动开启'),
          trailing: Switch(
            value: themeNotifier.eyeCareMode.autoSchedule,
            onChanged: (_) => themeNotifier.toggleEyeCareAutoSchedule(),
          ),
        ),
      ],
    );
  }

  Widget _buildUATab() {
    final uaState = ref.watch(uaManagerProvider);
    final uaManager = ref.read(uaManagerProvider.notifier);
    final searchController = TextEditingController();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('当前UA: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(uaState.currentPresetName, style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    uaState.effectiveUA,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索UA...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('自定义UA'),
                selected: uaState.enableCustomUA,
                onSelected: (_) => uaManager.toggleCustomUA(),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('随机UA'),
                selected: uaState.randomizeUA,
                onSelected: (_) => uaManager.toggleRandomUA(),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: uaManager.categories.length,
            itemBuilder: (context, index) {
              final category = uaManager.categories[index];
              final presets = uaManager.getPresetsByCategory(category);
              return ExpansionTile(
                title: Text(category),
                subtitle: Text('${presets.length} 个'),
                children: presets.map((preset) {
                  final isSelected = uaState.currentPresetName == preset.name;
                  return ListTile(
                    title: Text(preset.name, style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                    subtitle: Text(preset.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () => uaManager.switchToPreset(preset.name),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComponentTab() {
    final compState = ref.watch(componentBlockProvider);
    final compManager = ref.read(componentBlockProvider.notifier);

    return ListView(
      children: [
        const ListTile(title: Text('布局预设', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            children: LayoutPreset.values.map((preset) {
              return ChoiceChip(
                label: Text(preset.name),
                selected: false,
                onSelected: (_) => compManager.applyPreset(preset),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('沉浸模式'),
          subtitle: const Text('隐藏上下栏'),
          trailing: Switch(
            value: compState.immersiveMode,
            onChanged: (_) => compManager.toggleImmersiveMode(),
          ),
        ),
        ListTile(
          title: const Text('自动隐藏栏'),
          subtitle: const Text('滚动时自动隐藏'),
          trailing: Switch(
            value: compState.autoHideBars,
            onChanged: (_) => compManager.toggleAutoHide(),
          ),
        ),
        const Divider(),
        const ListTile(title: Text('组件显示', style: TextStyle(fontWeight: FontWeight.bold))),
        SwitchListTile(
          title: const Text('顶部地址栏'),
          subtitle: const Text('topBar'),
          value: !compState.isBlocked(PageComponent.topBar),
          onChanged: (v) => compManager.setComponentBlocked(PageComponent.topBar, !v),
        ),
        SwitchListTile(
          title: const Text('底部导航栏'),
          subtitle: const Text('navigationBar'),
          value: !compState.isBlocked(PageComponent.navigationBar),
          onChanged: (v) => compManager.setComponentBlocked(PageComponent.navigationBar, !v),
        ),
        SwitchListTile(
          title: const Text('进度条'),
          subtitle: const Text('progressBar'),
          value: !compState.isBlocked(PageComponent.progressBar),
          onChanged: (v) => compManager.setComponentBlocked(PageComponent.progressBar, !v),
        ),
        SwitchListTile(
          title: const Text('标签栏'),
          subtitle: const Text('tabBar'),
          value: !compState.isBlocked(PageComponent.tabBar),
          onChanged: (v) => compManager.setComponentBlocked(PageComponent.tabBar, !v),
        ),
        SwitchListTile(
          title: const Text('悬浮按钮'),
          subtitle: const Text('floatingAction'),
          value: !compState.isBlocked(PageComponent.floatingAction),
          onChanged: (v) => compManager.setComponentBlocked(PageComponent.floatingAction, !v),
        ),
        TextButton(
          onPressed: () => compManager.resetAll(),
          child: const Text('重置布局'),
        ),
      ],
    );
  }

  Widget _buildPrivacyLockTab() {
    final lockState = ref.watch(privacyLockProvider);
    final lockService = ref.read(privacyLockProvider.notifier);

    return ListView(
      children: [
        SwitchListTile(
          title: const Text('隐私锁'),
          subtitle: const Text('启动或后台返回时需要验证'),
          value: lockState.enabled,
          onChanged: (v) {
            if (!v) lockService.disableLock();
          },
        ),
        if (lockState.enabled) ...[
          const Divider(),
          const ListTile(title: Text('解锁方式', style: TextStyle(fontWeight: FontWeight.bold))),
          RadioListTile<LockType>(
            title: const Text('PIN码'),
            value: LockType.pin,
            groupValue: lockState.lockType,
            onChanged: (v) => lockService.changeLockType(v!),
          ),
          RadioListTile<LockType>(
            title: const Text('图案解锁'),
            value: LockType.pattern,
            groupValue: lockState.lockType,
            onChanged: (v) => lockService.changeLockType(v!),
          ),
          RadioListTile<LockType>(
            title: const Text('指纹/面容'),
            value: LockType.biometric,
            groupValue: lockState.lockType,
            onChanged: (v) => lockService.changeLockType(v!),
          ),
          const Divider(),
          const ListTile(title: Text('锁定设置', style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(
            title: const Text('启动时锁定'),
            value: lockState.lockOnStartup,
            onChanged: (_) => lockService.toggleLockOnStartup(),
          ),
          SwitchListTile(
            title: const Text('后台自动锁定'),
            subtitle: Text('${lockState.lockTimeout} 秒后锁定'),
            value: lockState.lockOnBackground,
            onChanged: (_) => lockService.toggleLockOnBackground(),
          ),
          ListTile(
            title: Text('锁定超时: ${lockState.lockTimeout}秒'),
            subtitle: Slider(
              value: lockState.lockTimeout.toDouble(),
              min: 5,
              max: 300,
              divisions: 59,
              onChanged: (v) => lockService.setLockTimeout(v.toInt()),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('失败擦除数据'),
            subtitle: Text('${lockState.maxFailedAttempts}次失败后擦除'),
            value: lockState.wipeOnFail,
            secondary: const Icon(Icons.warning, color: Colors.red),
            onChanged: (_) => lockService.toggleWipeOnFail(),
          ),
          SwitchListTile(
            title: const Text('隐身模式'),
            subtitle: const Text('隐藏隐私锁图标'),
            value: lockState.stealthMode,
            secondary: const Icon(Icons.visibility_off),
            onChanged: (_) => lockService.toggleStealthMode(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickCommandTab() {
    final cmdState = ref.watch(quickCommandProvider);
    final cmdManager = ref.read(quickCommandProvider.notifier);

    return Column(
      children: [
        SwitchListTile(
          title: const Text('快捷命令'),
          subtitle: Text('触发键: ${cmdState.triggerKey}'),
          value: cmdState.enabled,
          onChanged: (_) => cmdManager.toggleEnabled(),
        ),
        const Divider(),
        const ListTile(title: Text('所有命令', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: ListView.builder(
            itemCount: cmdState.commands.length,
            itemBuilder: (context, index) {
              final cmd = cmdState.commands[index];
              return SwitchListTile(
                title: Text(cmd.name),
                subtitle: Text('${cmd.shortcut} - ${cmd.description}'),
                value: cmd.enabled,
                onChanged: (_) => cmdManager.toggleCommand(cmd.id),
                secondary: const Icon(Icons.keyboard_command_key),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoreTab() {
    final startupState = ref.watch(startupTaskProvider);
    final startupManager = ref.read(startupTaskProvider.notifier);
    final videoState = ref.watch(videoControllerProvider);
    final videoManager = ref.read(videoControllerProvider.notifier);

    return ListView(
      children: [
        const ListTile(title: Text('启动任务', style: TextStyle(fontWeight: FontWeight.bold))),
        SwitchListTile(
          title: const Text('启用启动任务'),
          value: startupState.enabled,
          onChanged: (_) => startupManager.toggleEnabled(),
        ),
        ...startupState.tasks.map((task) {
          return SwitchListTile(
            title: Text(task.name),
            subtitle: Text(task.type.displayName),
            value: task.enabled,
            onChanged: (_) => startupManager.toggleTask(task.id),
          );
        }).toList(),
        const Divider(),
        const ListTile(title: Text('视频控制器', style: TextStyle(fontWeight: FontWeight.bold))),
        SwitchListTile(
          title: const Text('启用视频增强'),
          subtitle: const Text('倍速、缩放、手势控制'),
          value: videoState.enabled,
          onChanged: (_) => videoManager.toggleEnabled(),
        ),
        ListTile(
          title: Text('播放速度: ${videoState.playbackRate}x'),
          subtitle: Slider(
            value: videoState.playbackRate,
            min: 0.25,
            max: 4.0,
            divisions: 15,
            onChanged: videoState.enabled ? videoManager.setPlaybackRate : null,
          ),
        ),
        SwitchListTile(
          title: const Text('悬浮按钮'),
          value: videoState.showFloatingButton,
          onChanged: videoState.enabled ? (_) => videoManager.toggleFloatingButton() : null,
        ),
        SwitchListTile(
          title: const Text('手势控制'),
          value: videoState.gestureControl,
          onChanged: videoState.enabled ? (_) => videoManager.toggleGestureControl() : null,
        ),
        SwitchListTile(
          title: const Text('双指缩放'),
          value: videoState.pinchToZoom,
          onChanged: videoState.enabled ? (_) => videoManager.togglePinchToZoom() : null,
        ),
        SwitchListTile(
          title: const Text('自动跳过片头'),
          subtitle: Text('跳过前${videoState.skipSeconds}秒'),
          value: videoState.autoSkipIntro,
          onChanged: videoState.enabled ? (_) => videoManager.toggleAutoSkipIntro() : null,
        ),
      ],
    );
  }
}