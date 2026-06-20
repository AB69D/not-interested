import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../home/viewmodel/home_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.app_blocking_outlined, color: Colors.white70),
              title: const Text('App Exclusions', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Skip filtering for specific apps',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () => context.push('/whitelist'),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              title: 'Sensitivity',
              subtitle: '${(vm.state.sensitivity * 100).toInt()}%  —  higher means stricter',
              child: Slider(
                value: vm.state.sensitivity,
                min: 0.3,
                max: 0.9,
                divisions: 12,
                activeColor: const Color(0xFF3b82f6),
                inactiveColor: const Color(0xFF1e2d4a),
                onChanged: vm.state.status.name == 'stopped' ? vm.updateSensitivity : null,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'About',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const _SettingsTile(
              title: 'Version',
              subtitle: '1.0.0',
            ),
            const _SettingsTile(
              title: 'Processing',
              subtitle: 'On-device only — no data leaves your phone',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? child;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1f2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ?child,
        ],
      ),
    );
  }
}
