import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 隐私锁类型
enum LockType {
  none,
  pin,
  pattern,
  biometric,
  gesture,
}

/// 隐私锁状态
class PrivacyLockState {
  final bool enabled;
  final LockType lockType;
  final String? pinHash;
  final List<int>? pattern;
  final bool lockOnStartup;
  final bool lockOnBackground;
  final int lockTimeout;
  final bool isLocked;
  final int failedAttempts;
  final DateTime? lastUnlockTime;
  final bool wipeOnFail;
  final int maxFailedAttempts;
  final bool stealthMode;

  PrivacyLockState({
    this.enabled = false,
    this.lockType = LockType.pin,
    this.pinHash,
    this.pattern,
    this.lockOnStartup = true,
    this.lockOnBackground = true,
    this.lockTimeout = 30,
    this.isLocked = false,
    this.failedAttempts = 0,
    this.lastUnlockTime,
    this.wipeOnFail = false,
    this.maxFailedAttempts = 10,
    this.stealthMode = false,
  });

  PrivacyLockState copyWith({
    bool? enabled,
    LockType? lockType,
    String? pinHash,
    List<int>? pattern,
    bool? lockOnStartup,
    bool? lockOnBackground,
    int? lockTimeout,
    bool? isLocked,
    int? failedAttempts,
    DateTime? lastUnlockTime,
    bool? wipeOnFail,
    int? maxFailedAttempts,
    bool? stealthMode,
  }) {
    return PrivacyLockState(
      enabled: enabled ?? this.enabled,
      lockType: lockType ?? this.lockType,
      pinHash: pinHash ?? this.pinHash,
      pattern: pattern ?? this.pattern,
      lockOnStartup: lockOnStartup ?? this.lockOnStartup,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      lockTimeout: lockTimeout ?? this.lockTimeout,
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastUnlockTime: lastUnlockTime ?? this.lastUnlockTime,
      wipeOnFail: wipeOnFail ?? this.wipeOnFail,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      stealthMode: stealthMode ?? this.stealthMode,
    );
  }
}

class PrivacyLockService extends StateNotifier<PrivacyLockState> {
  PrivacyLockService() : super(PrivacyLockState());

  /// 设置PIN码
  Future<bool> setPin(String pin) async {
    final hash = _hashPin(pin);
    state = state.copyWith(
      enabled: true,
      lockType: LockType.pin,
      pinHash: hash,
      isLocked: true,
      failedAttempts: 0,
    );
    return true;
  }

  /// 验证PIN码
  bool verifyPin(String pin) {
    if (!state.enabled || state.lockType != LockType.pin) return true;

    final hash = _hashPin(pin);
    if (hash == state.pinHash) {
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lastUnlockTime: DateTime.now(),
      );
      return true;
    } else {
      final newFailed = state.failedAttempts + 1;
      state = state.copyWith(failedAttempts: newFailed);
      if (state.wipeOnFail && newFailed >= state.maxFailedAttempts) {
        _wipeData();
      }
      return false;
    }
  }

  /// 设置图案解锁
  Future<bool> setPattern(List<int> pattern) async {
    state = state.copyWith(
      enabled: true,
      lockType: LockType.pattern,
      pattern: pattern,
      isLocked: true,
      failedAttempts: 0,
    );
    return true;
  }

  /// 验证图案
  bool verifyPattern(List<int> pattern) {
    if (!state.enabled || state.lockType != LockType.pattern) return true;

    if (_listsEqual(pattern, state.pattern)) {
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lastUnlockTime: DateTime.now(),
      );
      return true;
    } else {
      final newFailed = state.failedAttempts + 1;
      state = state.copyWith(failedAttempts: newFailed);
      if (state.wipeOnFail && newFailed >= state.maxFailedAttempts) {
        _wipeData();
      }
      return false;
    }
  }

  /// 锁定
  void lock() {
    if (state.enabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  /// 解锁
  void unlock() {
    state = state.copyWith(
      isLocked: false,
      lastUnlockTime: DateTime.now(),
      failedAttempts: 0,
    );
  }

  /// 检查是否应该自动锁定
  bool shouldAutoLock() {
    if (!state.enabled || !state.lockOnBackground) return false;
    if (state.lastUnlockTime == null) return state.enabled;

    final elapsed = DateTime.now().difference(state.lastUnlockTime!).inSeconds;
    return elapsed >= state.lockTimeout;
  }

  /// 关闭隐私锁
  void disableLock() {
    state = state.copyWith(
      enabled: false,
      isLocked: false,
      pinHash: null,
      pattern: null,
      failedAttempts: 0,
    );
  }

  /// 更改锁定类型
  void changeLockType(LockType type) {
    state = state.copyWith(lockType: type);
  }

  /// 设置自动锁定超时
  void setLockTimeout(int seconds) {
    state = state.copyWith(lockTimeout: seconds.clamp(5, 300));
  }

  /// 切换启动锁定
  void toggleLockOnStartup() {
    state = state.copyWith(lockOnStartup: !state.lockOnStartup);
  }

  /// 切换后台锁定
  void toggleLockOnBackground() {
    state = state.copyWith(lockOnBackground: !state.lockOnBackground);
  }

  /// 切换失败擦除
  void toggleWipeOnFail() {
    state = state.copyWith(wipeOnFail: !state.wipeOnFail);
  }

  /// 切换隐身模式
  void toggleStealthMode() {
    state = state.copyWith(stealthMode: !state.stealthMode);
  }

  /// 设置最大失败次数
  void setMaxFailedAttempts(int count) {
    state = state.copyWith(maxFailedAttempts: count.clamp(3, 20));
  }

  String _hashPin(String pin) {
    // 简单的哈希（实际项目中应使用crypto库）
    var hash = 0;
    for (var i = 0; i < pin.length; i++) {
      hash = ((hash << 5) - hash) + pin.codeUnitAt(i);
      hash |= 0;
    }
    return hash.toRadixString(16);
  }

  bool _listsEqual(List<int>? a, List<int>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _wipeData() {
    // 擦除所有隐私数据
    state = state.copyWith(isLocked: true);
    // 实际实现中应清除历史、书签、缓存等
  }
}

final privacyLockProvider =
    StateNotifierProvider<PrivacyLockService, PrivacyLockState>((ref) {
  return PrivacyLockService();
});