import 'package:flutter/material.dart';

class DetectionCounterWidget extends StatelessWidget {
  final int count;

  const DetectionCounterWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1f2937)),
      ),
      child: Row(
        children: [
          const Icon(Icons.remove_red_eye_outlined, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Text(
            'Blocked regions: $count',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
