import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NetworkDropdown<T> extends StatelessWidget {
  final T? selectedValue;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T?>? onChanged;
  final String placeholder;

  const NetworkDropdown({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.selectedValue,
    this.onChanged,
    this.placeholder = 'Select...',
  });

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      borderRadius: 6,
      child: Container(
        height: 32, // Fixed height to match design
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: selectedValue,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: context.colorScheme.textDisabled,
              size: 16,
            ),
            dropdownColor: context.colorScheme.elevation2, // Darker background for menu
            style: context.textTheme.labelMedium!.copyWith(
              color: context.colorScheme.textPrimary,
            ),
            hint: FusionAppText(
              text: placeholder,
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textDisabled,
              ),
            ),
            items:
                items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: FusionAppText(
                      text: labelBuilder(item),
                      style: context.textTheme.labelMedium!.copyWith(
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
