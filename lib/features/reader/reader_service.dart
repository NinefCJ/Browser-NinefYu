import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 阅读模式状态
class ReaderModeState {
  final bool isActive;
  final double fontSize;
  final double lineHeight;
  final double margin;
  final String fontFamily;
  final ReaderTheme theme;
  final bool justifyText;
  final bool invertImage;

  ReaderModeState({
    this.isActive = false,
    this.fontSize = 18,
    this.lineHeight = 1.8,
    this.margin = 40,
    this.fontFamily = 'serif',
    this.theme = ReaderTheme.light,
    this.justifyText = true,
    this.invertImage = false,
  });

  ReaderModeState copyWith({
    bool? isActive,
    double? fontSize,
    double? lineHeight,
    double? margin,
    String? fontFamily,
    ReaderTheme? theme,
    bool? justifyText,
    bool? invertImage,
  }) {
    return ReaderModeState(
      isActive: isActive ?? this.isActive,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      margin: margin ?? this.margin,
      fontFamily: fontFamily ?? this.fontFamily,
      theme: theme ?? this.theme,
      justifyText: justifyText ?? this.justifyText,
      invertImage: invertImage ?? this.invertImage,
    );
  }
}

enum ReaderTheme {
  light,
  dark,
  sepia,
  green,
  gray,
}

extension ReaderThemeExtension on ReaderTheme {
  String get bgColor {
    switch (this) {
      case ReaderTheme.light:
        return '#ffffff';
      case ReaderTheme.dark:
        return '#1a1a1a';
      case ReaderTheme.sepia:
        return '#f4ecd8';
      case ReaderTheme.green:
        return '#cce8cf';
      case ReaderTheme.gray:
        return '#e0e0e0';
    }
  }

  String get textColor {
    switch (this) {
      case ReaderTheme.light:
        return '#333333';
      case ReaderTheme.dark:
        return '#e0e0e0';
      case ReaderTheme.sepia:
        return '#5b4636';
      case ReaderTheme.green:
        return '#1a472a';
      case ReaderTheme.gray:
        return '#333333';
    }
  }
}

class ReaderService extends StateNotifier<ReaderModeState> {
  ReaderService() : super(ReaderModeState());

  void toggle() {
    state = state.copyWith(isActive: !state.isActive);
  }

  void enterMode() {
    state = state.copyWith(isActive: true);
  }

  void exitMode() {
    state = state.copyWith(isActive: false);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(12, 36));
  }

  void setLineHeight(double height) {
    state = state.copyWith(lineHeight: height.clamp(1.2, 2.5));
  }

  void setMargin(double margin) {
    state = state.copyWith(margin: margin.clamp(10, 100));
  }

  void setTheme(ReaderTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void setFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
  }

  void setJustifyText(bool value) {
    state = state.copyWith(justifyText: value);
  }

  void setInvertImage(bool value) {
    state = state.copyWith(invertImage: value);
  }

  void increaseFontSize() {
    setFontSize(state.fontSize + 1);
  }

  void decreaseFontSize() {
    setFontSize(state.fontSize - 1);
  }

  /// 生成阅读模式CSS
  String generateReaderCss() {
    return '''
    body {
      background-color: ${state.theme.bgColor} !important;
      color: ${state.theme.textColor} !important;
      font-family: ${state.fontFamily} !important;
      font-size: ${state.fontSize}px !important;
      line-height: ${state.lineHeight} !important;
      max-width: ${800 - state.margin * 2}px !important;
      margin: 0 auto !important;
      padding: ${state.margin}px !important;
      text-align: ${state.justifyText ? 'justify' : 'left'} !important;
    }
    ${state.invertImage ? 'img { filter: invert(1); }' : ''}
    a {
      color: ${state.theme == ReaderTheme.dark ? '#80a0ff' : '#0066cc'} !important;
    }
    h1, h2, h3, h4, h5, h6 {
      color: ${state.theme.textColor} !important;
      line-height: 1.4 !important;
    }
    .reader-content {
      max-width: 700px !important;
      margin: 0 auto !important;
    }
    ''';
  }
}

final readerServiceProvider =
    StateNotifierProvider<ReaderService, ReaderModeState>((ref) {
  return ReaderService();
});