import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class FusionDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final String Function(T) display;
  final ValueChanged<T?>? onChanged;
  final bool isEnabled;

  const FusionDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
    required this.hint,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: FusionAppText(
        text: hint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isEnabled ? Theme.of(context).colorScheme.greyDark.withAlpha(200) : Theme.of(context).colorScheme.greyDark.withAlpha(100),
        ),
        maxLine: 1,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: isEnabled ? Theme.of(context).colorScheme.greyDark.withAlpha(200) : Theme.of(context).colorScheme.greyLight.withAlpha(100),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: isEnabled ? Theme.of(context).colorScheme.greyDark.withAlpha(200) : Theme.of(context).colorScheme.greyLight.withAlpha(100),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.greyLight.withAlpha(200),
          ),
        ),
        isDense: true,
        filled: true,
        fillColor: isEnabled ? Theme.of(context).colorScheme.white : Theme.of(context).colorScheme.greyLight.withAlpha(100),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dropdownColor: Theme.of(context).colorScheme.white,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isEnabled ? null : Theme.of(context).colorScheme.greyDark.withAlpha(100),
      ),
      items:
          isEnabled
              ? items
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
                  .toList()
              : null,
      onChanged: isEnabled ? onChanged : null,
    );
  }
}
