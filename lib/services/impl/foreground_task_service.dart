import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../abstract/i_foreground_task_service.dart';

class ForegroundTaskService implements IForegroundTaskService {
  bool _isRunning = false;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<bool> requestPermissions() async {
    // Request POST_NOTIFICATIONS (Android 13+)
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    final granted = await FlutterForegroundTask.checkNotificationPermission();
    return granted == NotificationPermission.granted;
  }

  @override
  Future<void> startService() async {
    // Native NotInterestedService is started via platform channel in ScreenCaptureService
    _isRunning = true;
  }

  @override
  Future<void> stopService() async {
    _isRunning = false;
  }
}
