import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题预设
class ThemePreset {
  final String name;
  final int primary;
  final int accent;
  final int background;
  final int surface;
  final int textPrimary;
  final int textSecondary;
  final String fontFamily;
  final double borderRadius;
  final double elevation;

  const ThemePreset({
    required this.name,
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    this.fontFamily = 'Roboto',
    this.borderRadius = 12,
    this.elevation = 4,
  });
}

class ThemePresets {
  static const List<ThemePreset> presets = [
    ThemePreset(
      name: '经典蓝',
      primary: 0xFF2196F3,
      accent: 0xFFFF9800,
      background: 0xFFFAFAFA,
      surface: 0xFFFFFFFF,
      textPrimary: 0xFF212121,
      textSecondary: 0xFF757575,
    ),
    ThemePreset(
      name: '暗夜紫',
      primary: 0xFF9C27B0,
      accent: 0xFF00BCD4,
      background: 0xFF121212,
      surface: 0xFF1E1E1E,
      textPrimary: 0xFFFFFFFF,
      textSecondary: 0xB3FFFFFF,
    ),
    ThemePreset(
      name: '森林绿',
      primary: 0xFF4CAF50,
      accent: 0xFF8BC34A,
      background: 0xFFF1F8E9,
      surface: 0xFFFFFFFF,
      textPrimary: 0xFF1B5E20,
      textSecondary: 0xFF558B2F,
    ),
    ThemePreset(
      name: '玫瑰红',
      primary: 0xFFE91E63,
      accent: 0xFFFFC107,
      background: 0xFFFFF8F8,
      surface: 0xFFFFFFFF,
      textPrimary: 0xFF880E4F,
      textSecondary: 0xFFC2185B,
    ),
    ThemePreset(
      name: '深海蓝',
      primary: 0xFF3F51B5,
      accent: 0xFF2196F3,
      background: 0xFF0A1929,
      surface: 0xFF132F4C,
      textPrimary: 0xFFFFFFFF,
      textSecondary: 0xB3E3F2FD,
    ),
    ThemePreset(
      name: '暖阳橙',
      primary: 0xFFFF5722,
      accent: 0xFFFF9800,
      background: 0xFFFFF3E0,
      surface: 0xFFFFFFFF,
      textPrimary: 0xFFBF360C,
      textSecondary: 0xFFE64A19,
    ),
    ThemePreset(
      name: '薄荷青',
      primary: 0xFF009688,
      accent: 0xFF4DB6AC,
      background: 0xFFE0F2F1,
      surface: 0xFFFFFFFF,
      textPrimary: 0xFF004D40,
      textSecondary: 0xFF00695C,
    ),
    ThemePreset(
      name: '极简白',
      primary: 0xFF607D8B,
      accent: 0xFF90A4AE,
      background: 0xFFFFFFFF,
      surface: 0xFFFAFAFA,
      textPrimary: 0xFF263238,
      textSecondary: 0xFF546E7A,
    ),
    ThemePreset(
      name: '酷黑',
      primary: 0xFF616161,
      accent: 0xFF9E9E9E,
      background: 0xFF000000,
      surface: 0xFF1A1A1A,
      textPrimary: 0xFFFFFFFF,
      textSecondary: 0xB3FFFFFF,
    ),
    ThemePreset(
      name: '樱花粉',
      primary: 0xFFF06292,
      accent: 0xFFF8BBD0,
      background: 0xFFFFF5F7,
      surface: 0xFFFFFFFF,
      textPrimary: 0xFF880E4F,
      textSecondary: 0xFFC2185B,
    ),
  ];

  static const List<String> themeNames = [
    '经典蓝', '暗夜紫', '森林绿', '玫瑰红', '深海蓝',
    '暖阳橙', '薄荷青', '极简白', '酷黑', '樱花粉',
  ];

  /// 生成莫奈调色板
  static List<Color> generateMonetPalette(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    return [
      hsl.withLightness(0.9).toColor(),
      hsl.withLightness(0.75).toColor(),
      hsl.withLightness(0.6).toColor(),
      hsl.withLightness(0.45).toColor(),
      hsl.withLightness(0.3).toColor(),
      hsl.withLightness(0.15).toColor(),
    ];
  }
}

/// 浏览器主题配置
class BrowserThemeConfig {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final AppThemeMode mode;
  final bool useMonet;
  final double borderRadius;
  final double elevation;
  final String fontFamily;
  final bool enableTransparentBar;
  final bool blurEffect;

  const BrowserThemeConfig({
    this.primaryColor = const Color(0xFF2196F3),
    this.accentColor = const Color(0xFFFF9800),
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.textPrimaryColor = const Color(0xFF212121),
    this.textSecondaryColor = const Color(0xFF757575),
    this.mode = AppThemeMode.system,
    this.useMonet = false,
    this.borderRadius = 12,
    this.elevation = 4,
    this.fontFamily = 'Roboto',
    this.enableTransparentBar = true,
    this.blurEffect = true,
  });

  BrowserThemeConfig copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    AppThemeMode? mode,
    bool? useMonet,
    double? borderRadius,
    double? elevation,
    String? fontFamily,
    bool? enableTransparentBar,
    bool? blurEffect,
  }) {
    return BrowserThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      mode: mode ?? this.mode,
      useMonet: useMonet ?? this.useMonet,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      fontFamily: fontFamily ?? this.fontFamily,
      enableTransparentBar: enableTransparentBar ?? this.enableTransparentBar,
      blurEffect: blurEffect ?? this.blurEffect,
    );
  }
}

enum AppThemeMode {
  light,
  dark,
  system,
  monet,
}

/// 护眼模式状态
class EyeCareMode {
  final bool enabled;
  final double warmth;
  final double brightness;
  final bool autoSchedule;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  EyeCareMode({
    this.enabled = false,
    this.warmth = 0.3,
    this.brightness = 0.8,
    this.autoSchedule = false,
    this.startTime = const TimeOfDay(hour: 20, minute: 0),
    this.endTime = const TimeOfDay(hour: 7, minute: 0),
  });

  EyeCareMode copyWith({
    bool? enabled,
    double? warmth,
    double? brightness,
    bool? autoSchedule,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return EyeCareMode(
      enabled: enabled ?? this.enabled,
      warmth: warmth ?? this.warmth,
      brightness: brightness ?? this.brightness,
      autoSchedule: autoSchedule ?? this.autoSchedule,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// 主题引擎
class ThemeEngineNotifier extends StateNotifier<BrowserThemeConfig> {
  EyeCareMode _eyeCareMode = EyeCareMode();
  int _currentPreset = 0;

  EyeCareMode get eyeCareMode => _eyeCareMode;
  int get currentPreset => _currentPreset;

  ThemeEngineNotifier() : super(const BrowserThemeConfig());

  /// 一键应用主题预设
  void applyPreset(int index, {bool isDark = false}) {
    if (index < 0 || index >= ThemePresets.presets.length) return;
    _currentPreset = index;
    final preset = ThemePresets.presets[index];
    state = state.copyWith(
      primaryColor: Color(preset.primary),
      accentColor: Color(preset.accent),
      backgroundColor: isDark ? const Color(0xFF121212) : Color(preset.background),
      surfaceColor: isDark ? const Color(0xFF1E1E1E) : Color(preset.surface),
      textPrimaryColor: isDark ? Colors.white : Color(preset.textPrimary),
      textSecondaryColor: isDark ? Colors.white70 : Color(preset.textSecondary),
      borderRadius: preset.borderRadius,
      elevation: preset.elevation,
      fontFamily: preset.fontFamily,
    );
  }

  /// 应用莫奈取色主题
  void applyMonet(Color seed) {
    final palette = ThemePresets.generateMonetPalette(seed);
    state = state.copyWith(
      primaryColor: palette[3],
      accentColor: palette[2],
      backgroundColor: palette[0].withOpacity(0.15),
      useMonet: true,
      mode: AppThemeMode.monet,
    );
  }

  /// 切换亮/暗模式
  void toggleDarkMode() {
    final isDark = state.mode == AppThemeMode.dark;
    state = state.copyWith(mode: isDark ? AppThemeMode.light : AppThemeMode.dark);
    applyPreset(_currentPreset, isDark: !isDark);
  }

  /// 设置主题模式
  void setMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// 设置主色调
  void setPrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
  }

  /// 设置强调色
  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
  }

  /// 设置圆角大小
  void setBorderRadius(double radius) {
    state = state.copyWith(borderRadius: radius.clamp(0, 24));
  }

  /// 设置字体
  void setFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
  }

  /// 切换护眼模式
  void toggleEyeCare() {
    _eyeCareMode = _eyeCareMode.copyWith(enabled: !_eyeCareMode.enabled);
    state = state.copyWith();
  }

  /// 设置护眼模式暖度
  void setEyeCareWarmth(double warmth) {
    _eyeCareMode = _eyeCareMode.copyWith(warmth: warmth.clamp(0, 1));
  }

  /// 设置护眼模式亮度
  void setEyeCareBrightness(double brightness) {
    _eyeCareMode = _eyeCareMode.copyWith(brightness: brightness.clamp(0.3, 1));
  }

  /// 切换自动护眼计划
  void toggleEyeCareAutoSchedule() {
    _eyeCareMode = _eyeCareMode.copyWith(autoSchedule: !_eyeCareMode.autoSchedule);
  }

  /// 生成主题数据
  ThemeData getThemeData({bool isDark = false}) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: state.primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : state.backgroundColor,
      cardColor: isDark ? const Color(0xFF1E1E1E) : state.surfaceColor,
      textTheme: base.textTheme.apply(
        fontFamily: state.fontFamily,
        bodyColor: isDark ? Colors.white : state.textPrimaryColor,
        displayColor: isDark ? Colors.white : state.textPrimaryColor,
      ),
    );
  }
}

final themeEngineProvider =
    StateNotifierProvider<ThemeEngineNotifier, BrowserThemeConfig>((ref) {
  return ThemeEngineNotifier();
});