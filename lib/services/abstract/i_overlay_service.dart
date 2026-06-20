import '../../features/home/model/detection_result.dart';

abstract class IOverlayService {
  bool get isVisible;

  Future<void> showOverlay();
  Future<void> hideOverlay();
  Future<void> updateBlurRegions(List<DetectionResult> detections);
  Future<void> clearBlurRegions();
  Future<void> setThreshold(double threshold);
}
