import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class FusionDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  const FusionDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: FusionAppText(
        text: hint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.greyDark.withAlpha(200),
        ),
        maxLine: 1,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).colorScheme.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dropdownColor: Theme.of(context).colorScheme.white,
      style: Theme.of(context).textTheme.bodySmall,
      items:
          items
              .map(
                (T menuItem) => DropdownMenuItem<T>(
                  value: menuItem,
                  child: FusionAppText(
                    text: display(menuItem),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLine: 1,
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}
