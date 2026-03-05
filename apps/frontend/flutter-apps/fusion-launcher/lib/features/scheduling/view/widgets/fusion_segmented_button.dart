import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionSegmentedButton<T> extends StatelessWidget {
  const FusionSegmentedButton({super.key, required this.value, required this.labels, required this.onChanged});
  final T value;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final List<T> keys = labels.keys.toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < keys.length; i++)
          GestureDetector(
            onTap: () {
              onChanged(keys[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: keys[i] == value ? Colors.black : Colors.transparent,
                border: const Border.symmetric(horizontal: BorderSide(color: Colors.grey, width: 1), vertical: BorderSide(color: Colors.grey, width: 0.5)),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(20) : Radius.zero,
                  right: i == keys.length - 1 ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                labels[keys[i]]!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: keys[i] == value ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
