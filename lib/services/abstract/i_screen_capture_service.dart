abstract class IScreenCaptureService {
  bool get isCapturing;
  bool get isModelReady;
  Stream<int> get detectionStream;

  Future<bool> requestPermission();
  Future<bool> hasProjectionToken();
  Future<void> startCapture({required double threshold});
  Future<void> stopCapture();
  Future<bool> isServiceRunning();
  void dispose();
}
