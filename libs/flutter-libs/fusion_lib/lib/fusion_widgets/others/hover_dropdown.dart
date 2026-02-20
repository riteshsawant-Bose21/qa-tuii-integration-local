import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

typedef HoverCallback<T> = void Function(T? value, int? index);

class HoverDropdownButtonFormField<T> extends StatefulWidget {
  // Core
  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldSetter<T>? onSaved;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;

  // New
  final HoverCallback<T>? onHover;

  // Decoration / layout
  final InputDecoration? decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final bool isDense;
  final bool isExpanded;
  final double? itemHeight;
  final AlignmentGeometry alignment;

  // Style / theming
  final TextStyle? style;
  final Widget? icon;
  final double iconSize;
  final Color? dropdownColor;
  final int elevation;
  final double? menuMaxHeight;
  final BorderRadius? borderRadius;
  final bool? enableFeedback;

  // Behavior
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;

  // Builders
  final DropdownButtonBuilder? selectedItemBuilder;

  const HoverDropdownButtonFormField({
    super.key,
    // Core
    required this.items,
    this.value,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,

    // New
    this.onHover,

    // Decoration / layout
    this.decoration,
    this.hint,
    this.disabledHint,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight,
    this.alignment = AlignmentDirectional.centerStart,

    // Style / theming
    this.style,
    this.icon,
    this.iconSize = 24.0,
    this.dropdownColor,
    this.elevation = 8,
    this.menuMaxHeight,
    this.borderRadius,
    this.enableFeedback,

    // Behavior
    this.focusNode,
    this.autofocus = false,
    this.onTap,

    // Builders
    this.selectedItemBuilder,
  });

  @override
  State<HoverDropdownButtonFormField<T>> createState() => _HoverDropdownButtonFormFieldState<T>();
}

class _HoverDropdownButtonFormFieldState<T> extends State<HoverDropdownButtonFormField<T>> {
  List<DropdownMenuItem<T>> _wrapWithHover(List<DropdownMenuItem<T>>? items) {
    if (items == null) return <DropdownMenuItem<T>>[]; // ← remove `const`
    return List<DropdownMenuItem<T>>.generate(items.length, (i) {
      final it = items[i];
      return DropdownMenuItem<T>(
        value: it.value,
        enabled: it.enabled,
        onTap: it.onTap,
        alignment: it.alignment,
        child: MouseRegion(
          onEnter: (_) => widget.onHover?.call(it.value, i),
          onExit: (_) => widget.onHover?.call(null, null),
          child: it.child,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: widget.value,
      items: _wrapWithHover(widget.items),
      onChanged: widget.enabled ? widget.onChanged : null,
      onSaved: widget.onSaved,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      decoration: widget.decoration ?? const InputDecoration(),
      hint: widget.hint,
      disabledHint: widget.disabledHint,
      isDense: widget.isDense,
      isExpanded: widget.isExpanded,
      itemHeight: widget.itemHeight,
      alignment: widget.alignment,
      style: widget.style,
      icon: widget.icon,
      iconSize: widget.iconSize,
      dropdownColor: widget.dropdownColor,
      elevation: widget.elevation,
      menuMaxHeight: widget.menuMaxHeight,
      borderRadius: widget.borderRadius,
      enableFeedback: widget.enableFeedback,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      selectedItemBuilder: widget.selectedItemBuilder,
    );
  }
}
