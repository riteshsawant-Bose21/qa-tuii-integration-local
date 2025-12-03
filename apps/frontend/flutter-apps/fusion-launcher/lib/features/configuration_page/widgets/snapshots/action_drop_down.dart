import 'package:flutter/material.dart';

class FusionDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  const FusionDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items:
          items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(display(e)),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}
