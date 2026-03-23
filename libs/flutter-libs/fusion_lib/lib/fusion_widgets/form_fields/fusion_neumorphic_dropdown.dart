import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionNeumorphicDropdown<T> extends StatefulWidget {
  const FusionNeumorphicDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
    this.value,
    this.hintText = "",
    this.width,
    this.itemBuilder,
    this.itemBuilderWithSelection,
    this.displayValue,
    this.height = 40,
    this.popupWidth,
    this.matchChildWidth = true,
    this.borderRadius,
    this.child,
  });

  final String? displayValue;
  final BorderRadius? borderRadius;
  final List<T> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final String Function(T)? itemLabelBuilder;
  final String hintText;
  final double? width;
  final double height;
  final double? popupWidth;
  final bool matchChildWidth;

  final Widget Function(BuildContext, T)? itemBuilder;
  final Widget Function(BuildContext, T, bool isSelected)? itemBuilderWithSelection;
  final Widget? child;

  @override
  State<FusionNeumorphicDropdown<T>> createState() => _FusionNeumorphicDropdownState<T>();
}

class _FusionNeumorphicDropdownState<T> extends State<FusionNeumorphicDropdown<T>> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant FusionNeumorphicDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Sync only if parent explicitly changes value
    if (widget.value != oldWidget.value && widget.value != _selectedValue) {
      _selectedValue = widget.value;
    }
  }

  void _handleChange(T value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _selectedValue = value;
      });
    });

    widget.onChanged(value);
  }

  String _getLabel(T item) {
    return widget.itemLabelBuilder?.call(item) ?? item.toString();
  }

  String _getDisplayText(bool isEmpty) {
    if (widget.displayValue != null && widget.displayValue!.isNotEmpty) {
      return widget.displayValue!;
    }
    if (!isEmpty) {
      return _getLabel(_selectedValue as T);
    }
    return widget.hintText;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _selectedValue == null;

    return FusionPopupMenu<T>(
      popoupwidth: widget.matchChildWidth ? null : widget.popupWidth,
      items: widget.items,
      onSelected: _handleChange,
      popupOffset: const Offset(-1, 6),
      matchChildWidth: widget.matchChildWidth,
      itemBuilder: (context, item) {
        final bool isSelected = item == _selectedValue;
        if (widget.itemBuilderWithSelection != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: widget.itemBuilderWithSelection!(context, item, isSelected),
          );
        }

        if (widget.itemBuilder != null) {
          return Container(child: widget.itemBuilder!(context, item));
        }

        return Center(
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: isSelected ? context.colorScheme.primary.withAlpha(100) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: FusionAppText(
                text: _getLabel(item),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? context.colorScheme.primary : context.colorScheme.textPlaceholder,
                ),
              ),
            ),
          ),
        );
      },
      child:
          widget.child ??
          Container(
            key: ValueKey(_selectedValue ?? widget.displayValue),
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
                BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
              ],
            ),
            child: Center(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: FusionAppText(
                        maxLine: 1,
                        text: _getDisplayText(isEmpty),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: isEmpty ? context.colorScheme.onSurface.withAlpha(100) : context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  FusionIcon.icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: context.colorScheme.onSurface.withAlpha(200),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
