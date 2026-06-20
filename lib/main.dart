import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'features/home/viewmodel/home_viewmodel.dart';
import 'services/abstract/i_foreground_task_service.dart';
import 'services/abstract/i_overlay_service.dart';
import 'services/abstract/i_screen_capture_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(NotInterestedApp(initialLocation: onboardingDone ? '/' : '/onboarding'));
}

class NotInterestedApp extends StatelessWidget {
  final String initialLocation;
  const NotInterestedApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        foregroundService: getIt<IForegroundTaskService>(),
        captureService: getIt<IScreenCaptureService>(),
        overlayService: getIt<IOverlayService>(),
      ),
      child: MaterialApp.router(
        title: 'Not Interested',
        debugShowCheckedModeBanner: false,
        routerConfig: createRouter(initialLocation: initialLocation),
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F1117),
        ),
      ),
    );
  }
}
