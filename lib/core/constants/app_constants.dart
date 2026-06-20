abstract class AppConstants {
  static const String screenCaptureChannel = 'com.yonderchat.not_interested/screen_capture';
  static const String overlayChannel = 'com.yonderchat.not_interested/overlay';
  static const String foregroundChannel = 'com.yonderchat.not_interested/foreground';

  static const int captureWidth = 480;
  static const int captureHeight = 854;
  static const int captureFrameRate = 15;

  static const int skinDetectSize = 128;
  static const double skinDetectThreshold = 0.15;

  static const double mlConfidenceThreshold = 0.6;
  static const String mlModelPath = 'assets/models/nudenet.tflite';
}
