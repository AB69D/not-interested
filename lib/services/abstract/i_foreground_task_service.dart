abstract class IForegroundTaskService {
  bool get isRunning;

  Future<bool> requestPermissions();
  Future<void> startService();
  Future<void> stopService();
}
