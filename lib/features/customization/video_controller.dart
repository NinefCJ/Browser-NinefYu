import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 视频倍速控制器状态
class VideoControllerState {
  final bool enabled;
  final double playbackRate;
  final double volume;
  final bool forceFullscreen;
  final bool autoSkipIntro;
  final int skipSeconds;
  final bool rememberSettings;
  final List<double> speedPresets;
  final bool showFloatingButton;
  final double floatingButtonOpacity;
  final bool gestureControl;
  final bool pinchToZoom;
  final double zoomLevel;
  final bool rotateLock;
  final int rotation;

  VideoControllerState({
    this.enabled = true,
    this.playbackRate = 1.0,
    this.volume = 1.0,
    this.forceFullscreen = false,
    this.autoSkipIntro = false,
    this.skipSeconds = 90,
    this.rememberSettings = true,
    this.speedPresets = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0],
    this.showFloatingButton = true,
    this.floatingButtonOpacity = 0.8,
    this.gestureControl = true,
    this.pinchToZoom = true,
    this.zoomLevel = 1.0,
    this.rotateLock = false,
    this.rotation = 0,
  });

  VideoControllerState copyWith({
    bool? enabled,
    double? playbackRate,
    double? volume,
    bool? forceFullscreen,
    bool? autoSkipIntro,
    int? skipSeconds,
    bool? rememberSettings,
    List<double>? speedPresets,
    bool? showFloatingButton,
    double? floatingButtonOpacity,
    bool? gestureControl,
    bool? pinchToZoom,
    double? zoomLevel,
    bool? rotateLock,
    int? rotation,
  }) {
    return VideoControllerState(
      enabled: enabled ?? this.enabled,
      playbackRate: playbackRate ?? this.playbackRate,
      volume: volume ?? this.volume,
      forceFullscreen: forceFullscreen ?? this.forceFullscreen,
      autoSkipIntro: autoSkipIntro ?? this.autoSkipIntro,
      skipSeconds: skipSeconds ?? this.skipSeconds,
      rememberSettings: rememberSettings ?? this.rememberSettings,
      speedPresets: speedPresets ?? this.speedPresets,
      showFloatingButton: showFloatingButton ?? this.showFloatingButton,
      floatingButtonOpacity: floatingButtonOpacity ?? this.floatingButtonOpacity,
      gestureControl: gestureControl ?? this.gestureControl,
      pinchToZoom: pinchToZoom ?? this.pinchToZoom,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      rotateLock: rotateLock ?? this.rotateLock,
      rotation: rotation ?? this.rotation,
    );
  }
}

class VideoControllerService extends StateNotifier<VideoControllerState> {
  VideoControllerService() : super(VideoControllerState());

  /// 启用/禁用
  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  /// 设置播放速度
  void setPlaybackRate(double rate) {
    state = state.copyWith(playbackRate: rate.clamp(0.25, 16.0));
  }

  /// 增加速度
  void increaseSpeed() {
    final rates = state.speedPresets;
    final currentIndex = rates.indexWhere((r) => r >= state.playbackRate);
    final nextIndex = (currentIndex + 1).clamp(0, rates.length - 1);
    setPlaybackRate(rates[nextIndex]);
  }

  /// 减小速度
  void decreaseSpeed() {
    final rates = state.speedPresets;
    final currentIndex = rates.indexWhere((r) => r >= state.playbackRate);
    final prevIndex = (currentIndex - 1).clamp(0, rates.length - 1);
    setPlaybackRate(rates[prevIndex]);
  }

  /// 设置音量
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 2.0));
  }

  /// 切换全屏
  void toggleFullscreen() {
    state = state.copyWith(forceFullscreen: !state.forceFullscreen);
  }

  /// 切换自动跳过片头
  void toggleAutoSkipIntro() {
    state = state.copyWith(autoSkipIntro: !state.autoSkipIntro);
  }

  /// 设置跳过秒数
  void setSkipSeconds(int seconds) {
    state = state.copyWith(skipSeconds: seconds.clamp(30, 300));
  }

  /// 切换悬浮按钮
  void toggleFloatingButton() {
    state = state.copyWith(showFloatingButton: !state.showFloatingButton);
  }

  /// 设置悬浮按钮透明度
  void setFloatingOpacity(double opacity) {
    state = state.copyWith(floatingButtonOpacity: opacity.clamp(0.1, 1.0));
  }

  /// 切换手势控制
  void toggleGestureControl() {
    state = state.copyWith(gestureControl: !state.gestureControl);
  }

  /// 切换双指缩放
  void togglePinchToZoom() {
    state = state.copyWith(pinchToZoom: !state.pinchToZoom);
  }

  /// 设置缩放级别
  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(0.5, 5.0));
  }

  /// 放大
  void zoomIn() {
    setZoomLevel(state.zoomLevel + 0.25);
  }

  /// 缩小
  void zoomOut() {
    setZoomLevel(state.zoomLevel - 0.25);
  }

  /// 重置缩放
  void resetZoom() {
    state = state.copyWith(zoomLevel: 1.0);
  }

  /// 切换旋转锁定
  void toggleRotateLock() {
    state = state.copyWith(rotateLock: !state.rotateLock);
  }

  /// 旋转90度
  void rotate90() {
    final newRotation = (state.rotation + 90) % 360;
    state = state.copyWith(rotation: newRotation);
  }

  /// 添加速度预设
  void addSpeedPreset(double speed) {
    final presets = List<double>.from(state.speedPresets);
    if (!presets.contains(speed)) {
      presets.add(speed);
      presets.sort();
      state = state.copyWith(speedPresets: presets);
    }
  }

  /// 移除速度预设
  void removeSpeedPreset(double speed) {
    final presets = List<double>.from(state.speedPresets);
    presets.remove(speed);
    if (presets.length >= 2) {
      state = state.copyWith(speedPresets: presets);
    }
  }

  /// 生成视频控制器JS代码
  String generateInjectionJs() {
    return '''
(function() {
  if (window.__videoControllerInjected) return;
  window.__videoControllerInjected = true;

  var currentRate = ${state.playbackRate};
  var currentVolume = ${state.volume};
  var videos = document.querySelectorAll('video');

  function applySettings(video) {
    video.playbackRate = currentRate;
    video.volume = currentVolume;
  }

  videos.forEach(function(v) {
    applySettings(v);
    v.addEventListener('loadedmetadata', function() {
      applySettings(v);
    });
  });

  var observer = new MutationObserver(function() {
    document.querySelectorAll('video:not([data-vc-inited])').forEach(function(v) {
      v.setAttribute('data-vc-inited', '1');
      applySettings(v);
    });
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });

  ${state.autoSkipIntro ? '''
  function checkIntro() {
    var video = document.querySelector('video');
    if (video && video.currentTime < ${state.skipSeconds} && video.duration > ${state.skipSeconds}) {
      video.currentTime = ${state.skipSeconds};
    }
  }
  setTimeout(checkIntro, 2000);
  ''' : ''}
})();
''';
  }
}

final videoControllerProvider =
    StateNotifierProvider<VideoControllerService, VideoControllerState>((ref) {
  return VideoControllerService();
});