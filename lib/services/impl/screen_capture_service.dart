import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/platform/channels/screen_capture_channel.dart';
import '../abstract/i_screen_capture_service.dart';

class ScreenCaptureService implements IScreenCaptureService {
  final ScreenCaptureChannel _channel;
  final _detectionController = StreamController<int>.broadcast();
  final _modelReadyController = StreamController<void>.broadcast();
  final _modelErrorController = StreamController<String>.broadcast();

  bool _isCapturing = false;
  bool _isModelReady = false;

  ScreenCaptureService(this._channel) {
    _channel.setCallbacks(
      onDetection: (count) {
        if (!_detectionController.isClosed) _detectionController.add(count);
      },
      onModelReady: () {
        _isModelReady = true;
        if (!_modelReadyController.isClosed) _modelReadyController.add(null);
      },
      onModelError: (error) {
        if (!_modelErrorController.isClosed) _modelErrorController.add(error);
      },
    );
  }

  @override
  bool get isCapturing => _isCapturing;

  @override
  bool get isModelReady => _isModelReady;

  @override
  Stream<int> get detectionStream => _detectionController.stream;

  Stream<void> get modelReadyStream => _modelReadyController.stream;
  Stream<String> get modelErrorStream => _modelErrorController.stream;

  @override
  Future<bool> requestPermission() => _channel.requestPermission();

  @override
  Future<bool> hasProjectionToken() => _channel.hasProjectionToken();

  @override
  Future<void> startCapture({required double threshold}) async {
    await _channel.startCapture(
      width: AppConstants.captureWidth,
      height: AppConstants.captureHeight,
      frameRate: AppConstants.captureFrameRate,
      threshold: threshold,
    );
    _isCapturing = true;
  }

  @override
  Future<void> stopCapture() async {
    await _channel.stopCapture();
    _isCapturing = false;
  }

  @override
  Future<bool> isServiceRunning() => _channel.isServiceRunning();

  @override
  void dispose() {
    _detectionController.close();
    _modelReadyController.close();
    _modelErrorController.close();
  }
}
