import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 隐私模式状态
class PrivateModeState {
  final bool isActive;
  final int privateTabCount;
  final DateTime? activatedAt;
  final bool autoCloseOnExit;
  final bool blockThirdPartyCookies;
  final bool doNotTrack;

  PrivateModeState({
    this.isActive = false,
    this.privateTabCount = 0,
    this.activatedAt,
    this.autoCloseOnExit = true,
    this.blockThirdPartyCookies = true,
    this.doNotTrack = true,
  });

  PrivateModeState copyWith({
    bool? isActive,
    int? privateTabCount,
    DateTime? activatedAt,
    bool? autoCloseOnExit,
    bool? blockThirdPartyCookies,
    bool? doNotTrack,
  }) {
    return PrivateModeState(
      isActive: isActive ?? this.isActive,
      privateTabCount: privateTabCount ?? this.privateTabCount,
      activatedAt: activatedAt ?? this.activatedAt,
      autoCloseOnExit: autoCloseOnExit ?? this.autoCloseOnExit,
      blockThirdPartyCookies: blockThirdPartyCookies ?? this.blockThirdPartyCookies,
      doNotTrack: doNotTrack ?? this.doNotTrack,
    );
  }
}

class PrivateModeService extends StateNotifier<PrivateModeState> {
  PrivateModeService() : super(PrivateModeState());

  void enterPrivateMode() {
    state = state.copyWith(
      isActive: true,
      activatedAt: DateTime.now(),
    );
  }

  void exitPrivateMode() {
    // 清理所有隐私数据
    state = PrivateModeState(
      autoCloseOnExit: state.autoCloseOnExit,
      blockThirdPartyCookies: state.blockThirdPartyCookies,
      doNotTrack: state.doNotTrack,
    );
  }

  void toggle() {
    if (state.isActive) {
      exitPrivateMode();
    } else {
      enterPrivateMode();
    }
  }

  void incrementPrivateTab() {
    state = state.copyWith(privateTabCount: state.privateTabCount + 1);
  }

  void decrementPrivateTab() {
    state = state.copyWith(
      privateTabCount: (state.privateTabCount - 1).clamp(0, 999),
    );
  }

  void setAutoCloseOnExit(bool value) {
    state = state.copyWith(autoCloseOnExit: value);
  }

  void setBlockThirdPartyCookies(bool value) {
    state = state.copyWith(blockThirdPartyCookies: value);
  }

  void setDoNotTrack(bool value) {
    state = state.copyWith(doNotTrack: value);
  }
}

final privateModeProvider =
    StateNotifierProvider<PrivateModeService, PrivateModeState>((ref) {
  return PrivateModeService();
});