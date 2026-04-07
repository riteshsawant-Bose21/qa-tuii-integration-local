import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class CommonTabSwitcher<T> extends StatefulWidget {
  final List<T> values;
  final T initialValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T>? onChanged;

  const CommonTabSwitcher({
    super.key,
    required this.values,
    required this.initialValue,
    required this.labelBuilder,
    this.onChanged,
  });

  @override
  State<CommonTabSwitcher<T>> createState() => _CommonTabSwitcherState<T>();
}

class _CommonTabSwitcherState<T> extends State<CommonTabSwitcher<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(widget.values.length, (index) {
          final value = widget.values[index];
          final isSelected = value == _selected;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index != widget.values.length - 1 ? 12 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selected = value);
                  widget.onChanged?.call(value);
                },
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colorScheme.elevation2
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.labelBuilder(value),
                    style: Theme.of(context)
                        .textTheme
                        .b3Regular
                        .copyWith(
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? context.colorScheme.textPrimary
                          : context.colorScheme.textBody,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}