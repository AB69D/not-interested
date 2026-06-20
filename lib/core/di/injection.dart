import 'package:get_it/get_it.dart';
import '../platform/channels/overlay_channel.dart';
import '../platform/channels/screen_capture_channel.dart';
import '../../services/abstract/i_foreground_task_service.dart';
import '../../services/abstract/i_overlay_service.dart';
import '../../services/abstract/i_screen_capture_service.dart';
import '../../services/impl/foreground_task_service.dart';
import '../../services/impl/overlay_service.dart';
import '../../services/impl/screen_capture_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton(() => ScreenCaptureChannel());
  getIt.registerLazySingleton(() => OverlayChannel());

  getIt.registerLazySingleton<IForegroundTaskService>(() => ForegroundTaskService());
  getIt.registerLazySingleton<IScreenCaptureService>(() => ScreenCaptureService(getIt()));
  getIt.registerLazySingleton<IOverlayService>(() => OverlayService(getIt()));
}
