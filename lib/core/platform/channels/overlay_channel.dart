import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';

class OverlayChannel {
  static const _channel = MethodChannel(AppConstants.overlayChannel);

  Future<void> showOverlay() async {
    await _channel.invokeMethod('showOverlay');
  }

  Future<void> hideOverlay() async {
    await _channel.invokeMethod('hideOverlay');
  }

  Future<void> updateBlurRegions(List<Map<String, double>> regions) async {
    await _channel.invokeMethod('updateBlurRegions', {'regions': regions});
  }

  Future<void> clearBlurRegions() async {
    await _channel.invokeMethod('clearBlurRegions');
  }

  Future<void> setThreshold(double threshold) async {
    await _channel.invokeMethod('setThreshold', {'threshold': threshold});
  }
}
