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
      // Force recreation when the selected value changes so the FormField's
      // internal state is always in sync with the external value prop.
      // Without this, DropdownButtonFormField (uncontrolled FormField) keeps a
      // stale _value from a previous build and the Flutter assertion:
      //   "There should be exactly one item with DropdownButtonFormField's value"
      // fires when items are regenerated with new instances.
      key: ObjectKey(value),
      isExpanded: true,
      initialValue: value,
      hint: FusionAppText(
        text: hint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isEnabled ? context.colorScheme.primaryWhite.withAlpha(100) : context.colorScheme.primaryWhite.withAlpha(100),
        ),
        maxLine: 1,
      ),

      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        isDense: true,
        filled: true,
        fillColor: isEnabled ? Theme.of(context).colorScheme.elevation1 : context.colorScheme.elevation2.withAlpha(100),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dropdownColor: Theme.of(context).colorScheme.elevation1,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isEnabled ? null : context.colorScheme.primaryWhite.withAlpha(100),
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
