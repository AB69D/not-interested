import '../../core/platform/channels/overlay_channel.dart';
import '../../features/home/model/detection_result.dart';
import '../abstract/i_overlay_service.dart';

class OverlayService implements IOverlayService {
  final OverlayChannel _channel;
  bool _isVisible = false;

  OverlayService(this._channel);

  @override
  bool get isVisible => _isVisible;

  @override
  Future<void> showOverlay() async {
    await _channel.showOverlay();
    _isVisible = true;
  }

  @override
  Future<void> hideOverlay() async {
    await _channel.hideOverlay();
    _isVisible = false;
  }

  @override
  Future<void> updateBlurRegions(List<DetectionResult> detections) async {
    final regions = detections.map((d) => d.toRegionMap()).toList();
    await _channel.updateBlurRegions(regions);
  }

  @override
  Future<void> clearBlurRegions() async {
    await _channel.clearBlurRegions();
  }

  @override
  Future<void> setThreshold(double threshold) async {
    await _channel.setThreshold(threshold);
  }
}
