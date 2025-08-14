import 'package:flutter/material.dart';

class VolumeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  const VolumeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('${(value * 100).toStringAsFixed(1)}%'),
      ],
    );
  }
}
