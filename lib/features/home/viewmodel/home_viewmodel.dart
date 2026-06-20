import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/abstract/i_foreground_task_service.dart';
import '../../../services/abstract/i_overlay_service.dart';
import '../../../services/abstract/i_screen_capture_service.dart';
import '../../../services/impl/screen_capture_service.dart';
import '../model/home_state.dart';

class HomeViewModel extends ChangeNotifier {
  final IForegroundTaskService _foregroundService;
  final IScreenCaptureService _captureService;
  final IOverlayService _overlayService;

  HomeState _state = const HomeState();
  StreamSubscription<int>? _detectionSub;
  StreamSubscription<void>? _modelReadySub;
  StreamSubscription<String>? _modelErrorSub;

  HomeViewModel({
    required IForegroundTaskService foregroundService,
    required IScreenCaptureService captureService,
    required IOverlayService overlayService,
  })  : _foregroundService = foregroundService,
        _captureService = captureService,
        _overlayService = overlayService {
    // Sync immediately so the toggle reflects real state on first open
    checkStatus();
  }

  HomeState get state => _state;

  Future<void> checkStatus() async {
    final running = await _captureService.isServiceRunning();
    if (running && _state.status != ServiceStatus.running) {
      _state = _state.copyWith(status: ServiceStatus.running);
      _listenToDetections();
      notifyListeners();
    } else if (!running && _state.status == ServiceStatus.running) {
      _state = _state.copyWith(
        status: ServiceStatus.stopped,
        detectionCount: 0,
        isModelLoading: false,
      );
      notifyListeners();
    }
  }

  Future<void> startService() async {
    _state = _state.copyWith(
      status: ServiceStatus.starting,
      isModelLoading: true,
      clearError: true,
    );
    notifyListeners();

    try {
      // If we don't have a cached MediaProjection token, ask the user once.
      // Overlay permission is handled transparently inside requestPermission()
      // (opens Settings only the very first time, never again after granted).
      final hasToken = await _captureService.hasProjectionToken();
      if (!hasToken) {
        final granted = await _captureService.requestPermission();
        if (!granted) {
          _state = _state.copyWith(
            status: ServiceStatus.stopped,
            isModelLoading: false,
          );
          notifyListeners();
          return;
        }
      }

      // Request notification permission silently — service runs even if denied
      await _foregroundService.requestPermissions();

      await _foregroundService.startService();
      await _overlayService.showOverlay();
      await _captureService.startCapture(threshold: _state.sensitivity);
      _listenToDetections();
      _state = _state.copyWith(status: ServiceStatus.running);
    } catch (e) {
      _state = _state.copyWith(
        status: ServiceStatus.error,
        errorMessage: e.toString(),
        isModelLoading: false,
      );
    }
    notifyListeners();
  }

  Future<void> stopService() async {
    _detectionSub?.cancel();
    _detectionSub = null;
    _modelReadySub?.cancel();
    _modelReadySub = null;

    await _captureService.stopCapture();
    await _overlayService.clearBlurRegions();
    await _overlayService.hideOverlay();
    await _foregroundService.stopService();

    _state = _state.copyWith(
      status: ServiceStatus.stopped,
      detectionCount: 0,
      isModelLoading: false,
    );
    notifyListeners();
  }

  void updateSensitivity(double value) {
    _state = _state.copyWith(sensitivity: value);
    _overlayService.setThreshold(value);
    notifyListeners();
  }

  void _listenToDetections() {
    _detectionSub?.cancel();
    _detectionSub = _captureService.detectionStream.listen((count) {
      _state = _state.copyWith(detectionCount: _state.detectionCount + count);
      notifyListeners();
    });

    final svc = _captureService;
    if (svc is ScreenCaptureService) {
      _modelReadySub?.cancel();
      _modelReadySub = svc.modelReadyStream.listen((_) {
        _state = _state.copyWith(isModelLoading: false);
        notifyListeners();
      });
      _modelErrorSub?.cancel();
      _modelErrorSub = svc.modelErrorStream.listen((error) {
        _state = _state.copyWith(
          status: ServiceStatus.error,
          errorMessage: 'Model failed to load: $error',
          isModelLoading: false,
        );
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _detectionSub?.cancel();
    _modelReadySub?.cancel();
    _modelErrorSub?.cancel();
    _captureService.dispose();
    super.dispose();
  }
}
