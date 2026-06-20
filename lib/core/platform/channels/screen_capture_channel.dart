import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';

class ScreenCaptureChannel {
  static const _channel = MethodChannel(AppConstants.screenCaptureChannel);

  Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  Future<bool> hasProjectionToken() async {
    return await _channel.invokeMethod<bool>('hasProjectionToken') ?? false;
  }

  Future<void> startCapture({
    required int width,
    required int height,
    required int frameRate,
    required double threshold,
  }) async {
    await _channel.invokeMethod('startCapture', {
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'threshold': threshold,
    });
  }

  Future<void> stopCapture() async {
    await _channel.invokeMethod('stopCapture');
  }

  Future<bool> isServiceRunning() async {
    return await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
  }

  void setCallbacks({
    required void Function(int count) onDetection,
    required void Function() onModelReady,
    void Function(String error)? onModelError,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDetectionEvent':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          onDetection(args['count'] as int? ?? 0);
        case 'onModelReady':
          onModelReady();
        case 'onModelError':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          onModelError?.call(args['error'] as String? ?? 'Unknown error');
      }
    });
  }
}
