import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../model/home_state.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/service_toggle_widget.dart';
import 'widgets/detection_counter_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-sync when returning from the overlay/system permission screen
    if (state == AppLifecycleState.resumed) {
      context.read<HomeViewModel>().checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        title: const Text(
          'Not Interested',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          final state = vm.state;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ServiceToggleWidget(
                  status: state.status,
                  isModelLoading: state.isModelLoading,
                  onStart: vm.startService,
                  onStop: vm.stopService,
                ),
                if (state.status == ServiceStatus.running) ...[
                  const SizedBox(height: 20),
                  DetectionCounterWidget(count: state.detectionCount),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2d1515),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFf87171), fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
