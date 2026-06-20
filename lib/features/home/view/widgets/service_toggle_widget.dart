import 'package:flutter/material.dart';
import '../../model/home_state.dart';

class ServiceToggleWidget extends StatelessWidget {
  final ServiceStatus status;
  final bool isModelLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const ServiceToggleWidget({
    super.key,
    required this.status,
    required this.isModelLoading,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = status == ServiceStatus.running;
    final isStarting = status == ServiceStatus.starting;
    final busy = isStarting;

    return GestureDetector(
      onTap: busy ? null : (isRunning ? onStop : onStart),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isRunning ? const Color(0xFF1a3a2a) : const Color(0xFF1e2d4a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRunning ? const Color(0xFF22c55e) : const Color(0xFF3b82f6),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            if (busy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isRunning ? Icons.shield : Icons.shield_outlined,
                size: 52,
                color: isRunning ? const Color(0xFF22c55e) : const Color(0xFF3b82f6),
              ),
            const SizedBox(height: 12),
            Text(
              busy
                  ? 'Starting...'
                  : isRunning
                      ? 'Protection Active — Tap to Stop'
                      : 'Tap to Start Protection',
              style: TextStyle(
                color: isRunning ? const Color(0xFF22c55e) : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRunning && !isModelLoading) ...[
              const SizedBox(height: 4),
              const Text(
                'Screen is being monitored',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
