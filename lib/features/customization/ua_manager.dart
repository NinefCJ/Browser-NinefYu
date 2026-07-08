import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UA预设
class UAPreset {
  final String name;
  final String description;
  final String userAgent;
  final String category;
  final String platform;

  const UAPreset({
    required this.name,
    required this.description,
    required this.userAgent,
    this.category = '浏览器',
    this.platform = 'Android',
  });
}

/// UA管理状态
class UAState {
  final String currentUA;
  final String currentPresetName;
  final bool enableCustomUA;
  final String customUA;
  final List<UAPreset> presets;
  final bool randomizeUA;
  final bool deviceSpoofing;
  final String spoofedDevice;

  UAState({
    this.currentUA = '',
    this.currentPresetName = 'Via 默认',
    this.enableCustomUA = false,
    this.customUA = '',
    this.presets = const [],
    this.randomizeUA = false,
    this.deviceSpoofing = false,
    this.spoofedDevice = '',
  });

  UAState copyWith({
    String? currentUA,
    String? currentPresetName,
    bool? enableCustomUA,
    String? customUA,
    List<UAPreset>? presets,
    bool? randomizeUA,
    bool? deviceSpoofing,
    String? spoofedDevice,
  }) {
    return UAState(
      currentUA: currentUA ?? this.currentUA,
      currentPresetName: currentPresetName ?? this.currentPresetName,
      enableCustomUA: enableCustomUA ?? this.enableCustomUA,
      customUA: customUA ?? this.customUA,
      presets: presets ?? this.presets,
      randomizeUA: randomizeUA ?? this.randomizeUA,
      deviceSpoofing: deviceSpoofing ?? this.deviceSpoofing,
      spoofedDevice: spoofedDevice ?? this.spoofedDevice,
    );
  }

  String get effectiveUA {
    if (enableCustomUA && customUA.isNotEmpty) return customUA;
    if (currentUA.isNotEmpty) return currentUA;
    return defaultUA;
  }

  static const String defaultUA =
      'Mozilla/5.0 (Linux; Android 14; zh-cn) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile Safari/537.36';
}

class UAManager extends StateNotifier<UAState> {
  UAManager() : super(UAState()) {
    _loadPresets();
  }

  void _loadPresets() {
    state = state.copyWith(
      presets: _allPresets,
      currentUA: _allPresets.first.userAgent,
    );
  }

  /// 完整UA预设列表
  final List<UAPreset> _allPresets = const [
    // 浏览器默认
    UAPreset(
      name: 'Via 默认',
      description: 'Via 浏览器默认UA',
      userAgent:
          'Mozilla/5.0 (Linux; Android 14; zh-cn) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile Safari/537.36',
      category: '浏览器',
      platform: 'Android',
    ),
    UAPreset(
      name: 'Chrome 安卓',
      description: 'Chrome for Android',
      userAgent:
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36',
      category: '浏览器',
      platform: 'Android',
    ),
    UAPreset(
      name: 'Firefox 安卓',
      description: 'Firefox for Android',
      userAgent:
          'Mozilla/5.0 (Android 14; Mobile; rv:121.0) Gecko/121.0 Firefox/121.0',
      category: '浏览器',
      platform: 'Android',
    ),
    UAPreset(
      name: 'Edge 安卓',
      description: 'Edge for Android',
      userAgent:
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 EdgA/120.0.2210.126',
      category: '浏览器',
      platform: 'Android',
    ),
    UAPreset(
      name: 'Opera 安卓',
      description: 'Opera for Android',
      userAgent:
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36 OPR/82.4.2254.67880',
      category: '浏览器',
      platform: 'Android',
    ),
    UAPreset(
      name: 'UC 浏览器',
      description: 'UC Browser 安卓版',
      userAgent:
          'Mozilla/5.0 (Linux; U; Android 14; zh-CN; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/15.1.0.1250 Mobile Safari/537.36',
      category: '浏览器',
      platform: 'Android',
    ),
    UAPreset(
      name: 'QQ 浏览器',
      description: 'QQ 浏览器安卓版',
      userAgent:
          'Mozilla/5.0 (Linux; Android 14; Pixel 8; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/90.0.4430.82 MQQBrowser/12.7 Mobile Safari/537.36',
      category: '浏览器',
      platform: 'Android',
    ),
    // 桌面浏览器
    UAPreset(
      name: 'Chrome Windows',
      description: 'Chrome 桌面版 (Windows)',
      userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      category: '桌面浏览器',
      platform: 'Windows',
    ),
    UAPreset(
      name: 'Chrome macOS',
      description: 'Chrome 桌面版 (macOS)',
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      category: '桌面浏览器',
      platform: 'macOS',
    ),
    UAPreset(
      name: 'Firefox Windows',
      description: 'Firefox 桌面版 (Windows)',
      userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
      category: '桌面浏览器',
      platform: 'Windows',
    ),
    UAPreset(
      name: 'Safari macOS',
      description: 'Safari 桌面版 (macOS)',
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
      category: '桌面浏览器',
      platform: 'macOS',
    ),
    UAPreset(
      name: 'Edge Windows',
      description: 'Edge 桌面版 (Windows)',
      userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.2210.121',
      category: '桌面浏览器',
      platform: 'Windows',
    ),
    // iOS浏览器
    UAPreset(
      name: 'Safari iPhone',
      description: 'Safari for iPhone (iOS 17)',
      userAgent:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',
      category: 'iOS浏览器',
      platform: 'iOS',
    ),
    UAPreset(
      name: 'Safari iPad',
      description: 'Safari for iPad (iOS 17)',
      userAgent:
          'Mozilla/5.0 (iPad; CPU OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',
      category: 'iOS浏览器',
      platform: 'iOS',
    ),
    UAPreset(
      name: 'Chrome iPhone',
      description: 'Chrome for iPhone',
      userAgent:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/120.0.6099.119 Mobile/15E148 Safari/604.1',
      category: 'iOS浏览器',
      platform: 'iOS',
    ),
    // 搜索引擎爬虫
    UAPreset(
      name: 'Googlebot',
      description: 'Google 爬虫',
      userAgent:
          'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
      category: '爬虫',
      platform: 'Bot',
    ),
    UAPreset(
      name: 'Bingbot',
      description: 'Bing 爬虫',
      userAgent:
          'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
      category: '爬虫',
      platform: 'Bot',
    ),
    UAPreset(
      name: '百度蜘蛛',
      description: '百度搜索爬虫',
      userAgent:
          'Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)',
      category: '爬虫',
      platform: 'Bot',
    ),
    // 其他设备
    UAPreset(
      name: 'HarmonyOS',
      description: '华为鸿蒙浏览器',
      userAgent:
          'Mozilla/5.0 (Linux; HarmonyOS 4.0; ANA-AN00) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/98.0.4758.85 HuaweiBrowser/12.1.1.301 Mobile Safari/537.36',
      category: '其他',
      platform: 'HarmonyOS',
    ),
    UAPreset(
      name: '小米浏览器',
      description: '小米自带浏览器',
      userAgent:
          'Mozilla/5.0 (Linux; U; Android 14; zh-cn; 23127PN0CC Build/UK1.231208.002) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/100.0.4896.127 MiuiBrowser/18.0.10 Mobile Safari/537.36',
      category: '其他',
      platform: 'Android',
    ),
  ];

  /// 设置当前UA
  void setUA(String ua) {
    state = state.copyWith(currentUA: ua);
  }

  /// 按名称切换UA
  void switchToPreset(String name) {
    final preset = state.presets.firstWhere(
      (p) => p.name == name,
      orElse: () => state.presets.first,
    );
    state = state.copyWith(
      currentUA: preset.userAgent,
      currentPresetName: preset.name,
      enableCustomUA: false,
    );
  }

  /// 设置自定义UA
  void setCustomUA(String ua) {
    state = state.copyWith(customUA: ua, enableCustomUA: true);
  }

  /// 启用/禁用自定义UA
  void toggleCustomUA() {
    state = state.copyWith(enableCustomUA: !state.enableCustomUA);
  }

  /// 启用/禁用随机UA
  void toggleRandomUA() {
    state = state.copyWith(randomizeUA: !state.randomizeUA);
  }

  /// 获取随机UA
  String getRandomUA() {
    final list = state.presets;
    final index = DateTime.now().microsecondsSinceEpoch % list.length;
    return list[index].userAgent;
  }

  /// 按分类获取预设
  List<UAPreset> getPresetsByCategory(String category) {
    return state.presets.where((p) => p.category == category).toList();
  }

  /// 获取所有分类
  List<String> get categories {
    return state.presets.map((p) => p.category).toSet().toList();
  }

  /// 设备型号生成
  List<String> get deviceModels => const [
    'Pixel 8 Pro',
    'Pixel 8',
    'Samsung Galaxy S24 Ultra',
    'Samsung Galaxy S24+',
    'Xiaomi 14 Ultra',
    'Xiaomi 14 Pro',
    'Huawei Mate 60 Pro+',
    'Huawei P60 Pro',
    'OPPO Find X7 Ultra',
    'vivo X100 Pro',
    'OnePlus 12',
    'iPhone 15 Pro Max',
    'iPhone 15 Pro',
    'iPad Pro 12.9',
  ];

  /// 生成指定设备的Chrome UA
  String generateDeviceUA(String deviceModel) {
    final device = deviceModel.replaceAll(' ', '%20');
    return 'Mozilla/5.0 (Linux; Android 14; $device) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36';
  }

  /// 搜索UA预设
  List<UAPreset> search(String query) {
    final q = query.toLowerCase();
    return state.presets.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.platform.toLowerCase().contains(q) ||
          p.userAgent.toLowerCase().contains(q);
    }).toList();
  }
}

final uaManagerProvider = StateNotifierProvider<UAManager, UAState>((ref) {
  return UAManager();
});