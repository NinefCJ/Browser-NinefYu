import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式
enum AppThemeMode {
  light,
  dark,
  system,
  monet,
}

/// 搜索引擎
enum SearchEngine {
  google,
  bing,
  duckduckgo,
  baidu,
  sogou,
  custom,
}

/// 浏览器设置
class BrowserSettings {
  final AppThemeMode themeMode;
  final SearchEngine searchEngine;
  final String customSearchUrl;
  final String homepageUrl;
  final bool enableAdBlock;
  final bool enableUserScript;
  final bool enableVpnResilience;
  final bool enableDoNotTrack;
  final bool enableJavaScript;
  final bool enableCookie;
  final bool enableCache;
  final int downloadThreadCount;
  final int downloadMaxSpeed;
  final bool downloadWifiOnly;
  final bool downloadAutoResume;
  final String userAgent;
  final bool enablePrivacyLock;
  final String privacyLockPassword;
  final bool enableGesture;
  final bool enableQuickCommand;
  final bool enableStartupTask;
  final bool enableVideoController;
  final double defaultFontSize;
  final bool forceDarkMode;
  final bool enableReaderMode;
  final bool enableTranslation;

  const BrowserSettings({
    this.themeMode = AppThemeMode.system,
    this.searchEngine = SearchEngine.google,
    this.customSearchUrl = '',
    this.homepageUrl = 'about:blank',
    this.enableAdBlock = true,
    this.enableUserScript = true,
    this.enableVpnResilience = true,
    this.enableDoNotTrack = false,
    this.enableJavaScript = true,
    this.enableCookie = true,
    this.enableCache = true,
    this.downloadThreadCount = 4,
    this.downloadMaxSpeed = 0,
    this.downloadWifiOnly = false,
    this.downloadAutoResume = true,
    this.userAgent = '',
    this.enablePrivacyLock = false,
    this.privacyLockPassword = '',
    this.enableGesture = true,
    this.enableQuickCommand = true,
    this.enableStartupTask = false,
    this.enableVideoController = true,
    this.defaultFontSize = 16,
    this.forceDarkMode = false,
    this.enableReaderMode = true,
    this.enableTranslation = false,
  });

  BrowserSettings copyWith({
    AppThemeMode? themeMode,
    SearchEngine? searchEngine,
    String? customSearchUrl,
    String? homepageUrl,
    bool? enableAdBlock,
    bool? enableUserScript,
    bool? enableVpnResilience,
    bool? enableDoNotTrack,
    bool? enableJavaScript,
    bool? enableCookie,
    bool? enableCache,
    int? downloadThreadCount,
    int? downloadMaxSpeed,
    bool? downloadWifiOnly,
    bool? downloadAutoResume,
    String? userAgent,
    bool? enablePrivacyLock,
    String? privacyLockPassword,
    bool? enableGesture,
    bool? enableQuickCommand,
    bool? enableStartupTask,
    bool? enableVideoController,
    double? defaultFontSize,
    bool? forceDarkMode,
    bool? enableReaderMode,
    bool? enableTranslation,
  }) {
    return BrowserSettings(
      themeMode: themeMode ?? this.themeMode,
      searchEngine: searchEngine ?? this.searchEngine,
      customSearchUrl: customSearchUrl ?? this.customSearchUrl,
      homepageUrl: homepageUrl ?? this.homepageUrl,
      enableAdBlock: enableAdBlock ?? this.enableAdBlock,
      enableUserScript: enableUserScript ?? this.enableUserScript,
      enableVpnResilience: enableVpnResilience ?? this.enableVpnResilience,
      enableDoNotTrack: enableDoNotTrack ?? this.enableDoNotTrack,
      enableJavaScript: enableJavaScript ?? this.enableJavaScript,
      enableCookie: enableCookie ?? this.enableCookie,
      enableCache: enableCache ?? this.enableCache,
      downloadThreadCount: downloadThreadCount ?? this.downloadThreadCount,
      downloadMaxSpeed: downloadMaxSpeed ?? this.downloadMaxSpeed,
      downloadWifiOnly: downloadWifiOnly ?? this.downloadWifiOnly,
      downloadAutoResume: downloadAutoResume ?? this.downloadAutoResume,
      userAgent: userAgent ?? this.userAgent,
      enablePrivacyLock: enablePrivacyLock ?? this.enablePrivacyLock,
      privacyLockPassword: privacyLockPassword ?? this.privacyLockPassword,
      enableGesture: enableGesture ?? this.enableGesture,
      enableQuickCommand: enableQuickCommand ?? this.enableQuickCommand,
      enableStartupTask: enableStartupTask ?? this.enableStartupTask,
      enableVideoController: enableVideoController ?? this.enableVideoController,
      defaultFontSize: defaultFontSize ?? this.defaultFontSize,
      forceDarkMode: forceDarkMode ?? this.forceDarkMode,
      enableReaderMode: enableReaderMode ?? this.enableReaderMode,
      enableTranslation: enableTranslation ?? this.enableTranslation,
    );
  }
}

class SettingsService extends StateNotifier<BrowserSettings> {
  static const String _prefix = 'browser_';

  SettingsService() : super(const BrowserSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    state = BrowserSettings(
      themeMode: AppThemeMode.values[prefs.getInt('${_prefix}themeMode') ?? 2],
      searchEngine: SearchEngine.values[prefs.getInt('${_prefix}searchEngine') ?? 0],
      customSearchUrl: prefs.getString('${_prefix}customSearchUrl') ?? '',
      homepageUrl: prefs.getString('${_prefix}homepageUrl') ?? 'about:blank',
      enableAdBlock: prefs.getBool('${_prefix}enableAdBlock') ?? true,
      enableUserScript: prefs.getBool('${_prefix}enableUserScript') ?? true,
      enableVpnResilience: prefs.getBool('${_prefix}enableVpnResilience') ?? true,
      enableDoNotTrack: prefs.getBool('${_prefix}enableDoNotTrack') ?? false,
      enableJavaScript: prefs.getBool('${_prefix}enableJavaScript') ?? true,
      enableCookie: prefs.getBool('${_prefix}enableCookie') ?? true,
      enableCache: prefs.getBool('${_prefix}enableCache') ?? true,
      downloadThreadCount: prefs.getInt('${_prefix}downloadThreadCount') ?? 4,
      downloadMaxSpeed: prefs.getInt('${_prefix}downloadMaxSpeed') ?? 0,
      downloadWifiOnly: prefs.getBool('${_prefix}downloadWifiOnly') ?? false,
      downloadAutoResume: prefs.getBool('${_prefix}downloadAutoResume') ?? true,
      userAgent: prefs.getString('${_prefix}userAgent') ?? '',
      enablePrivacyLock: prefs.getBool('${_prefix}enablePrivacyLock') ?? false,
      privacyLockPassword: prefs.getString('${_prefix}privacyLockPassword') ?? '',
      enableGesture: prefs.getBool('${_prefix}enableGesture') ?? true,
      enableQuickCommand: prefs.getBool('${_prefix}enableQuickCommand') ?? true,
      enableStartupTask: prefs.getBool('${_prefix}enableStartupTask') ?? false,
      enableVideoController: prefs.getBool('${_prefix}enableVideoController') ?? true,
      defaultFontSize: prefs.getDouble('${_prefix}defaultFontSize') ?? 16,
      forceDarkMode: prefs.getBool('${_prefix}forceDarkMode') ?? false,
      enableReaderMode: prefs.getBool('${_prefix}enableReaderMode') ?? true,
      enableTranslation: prefs.getBool('${_prefix}enableTranslation') ?? false,
    );
  }

  Future<void> updateSettings(BrowserSettings newSettings) async {
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('${_prefix}themeMode', newSettings.themeMode.index);
    await prefs.setInt('${_prefix}searchEngine', newSettings.searchEngine.index);
    await prefs.setString('${_prefix}customSearchUrl', newSettings.customSearchUrl);
    await prefs.setString('${_prefix}homepageUrl', newSettings.homepageUrl);
    await prefs.setBool('${_prefix}enableAdBlock', newSettings.enableAdBlock);
    await prefs.setBool('${_prefix}enableUserScript', newSettings.enableUserScript);
    await prefs.setBool('${_prefix}enableVpnResilience', newSettings.enableVpnResilience);
    await prefs.setBool('${_prefix}enableDoNotTrack', newSettings.enableDoNotTrack);
    await prefs.setBool('${_prefix}enableJavaScript', newSettings.enableJavaScript);
    await prefs.setBool('${_prefix}enableCookie', newSettings.enableCookie);
    await prefs.setBool('${_prefix}enableCache', newSettings.enableCache);
    await prefs.setInt('${_prefix}downloadThreadCount', newSettings.downloadThreadCount);
    await prefs.setInt('${_prefix}downloadMaxSpeed', newSettings.downloadMaxSpeed);
    await prefs.setBool('${_prefix}downloadWifiOnly', newSettings.downloadWifiOnly);
    await prefs.setBool('${_prefix}downloadAutoResume', newSettings.downloadAutoResume);
    await prefs.setString('${_prefix}userAgent', newSettings.userAgent);
    await prefs.setBool('${_prefix}enablePrivacyLock', newSettings.enablePrivacyLock);
    await prefs.setString('${_prefix}privacyLockPassword', newSettings.privacyLockPassword);
    await prefs.setBool('${_prefix}enableGesture', newSettings.enableGesture);
    await prefs.setBool('${_prefix}enableQuickCommand', newSettings.enableQuickCommand);
    await prefs.setBool('${_prefix}enableStartupTask', newSettings.enableStartupTask);
    await prefs.setBool('${_prefix}enableVideoController', newSettings.enableVideoController);
    await prefs.setDouble('${_prefix}defaultFontSize', newSettings.defaultFontSize);
    await prefs.setBool('${_prefix}forceDarkMode', newSettings.forceDarkMode);
    await prefs.setBool('${_prefix}enableReaderMode', newSettings.enableReaderMode);
    await prefs.setBool('${_prefix}enableTranslation', newSettings.enableTranslation);
  }

  void update({
    AppThemeMode? themeMode,
    SearchEngine? searchEngine,
    String? customSearchUrl,
    String? homepageUrl,
    bool? enableAdBlock,
    bool? enableUserScript,
    bool? enableVpnResilience,
    bool? enableDoNotTrack,
    bool? enableJavaScript,
    bool? enableCookie,
    bool? enableCache,
    int? downloadThreadCount,
    int? downloadMaxSpeed,
    bool? downloadWifiOnly,
    bool? downloadAutoResume,
    String? userAgent,
    bool? enablePrivacyLock,
    String? privacyLockPassword,
    bool? enableGesture,
    bool? enableQuickCommand,
    bool? enableStartupTask,
    bool? enableVideoController,
    double? defaultFontSize,
    bool? forceDarkMode,
    bool? enableReaderMode,
    bool? enableTranslation,
  }) {
    updateSettings(state.copyWith(
      themeMode: themeMode,
      searchEngine: searchEngine,
      customSearchUrl: customSearchUrl,
      homepageUrl: homepageUrl,
      enableAdBlock: enableAdBlock,
      enableUserScript: enableUserScript,
      enableVpnResilience: enableVpnResilience,
      enableDoNotTrack: enableDoNotTrack,
      enableJavaScript: enableJavaScript,
      enableCookie: enableCookie,
      enableCache: enableCache,
      downloadThreadCount: downloadThreadCount,
      downloadMaxSpeed: downloadMaxSpeed,
      downloadWifiOnly: downloadWifiOnly,
      downloadAutoResume: downloadAutoResume,
      userAgent: userAgent,
      enablePrivacyLock: enablePrivacyLock,
      privacyLockPassword: privacyLockPassword,
      enableGesture: enableGesture,
      enableQuickCommand: enableQuickCommand,
      enableStartupTask: enableStartupTask,
      enableVideoController: enableVideoController,
      defaultFontSize: defaultFontSize,
      forceDarkMode: forceDarkMode,
      enableReaderMode: enableReaderMode,
      enableTranslation: enableTranslation,
    ));
  }

  ThemeMode get themeMode {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      case AppThemeMode.monet:
        return ThemeMode.system;
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsService, BrowserSettings>((ref) {
  return SettingsService();
});