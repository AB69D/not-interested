import 'package:flutter/material.dart';

class SensitivitySliderWidget extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const SensitivitySliderWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection Sensitivity: ${(value * 100).toInt()}%',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.3,
          max: 0.9,
          divisions: 12,
          activeColor: const Color(0xFF3b82f6),
          inactiveColor: const Color(0xFF1e2d4a),
          onChanged: enabled ? onChanged : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Relaxed', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text('Strict', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
