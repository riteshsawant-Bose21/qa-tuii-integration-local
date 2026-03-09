import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionDropDown<T> extends StatelessWidget {
  final List<T>? items;
  final int? selectedIndex;
  final Widget Function(BuildContext context, T item, bool isSelected)? itemBuilder;
  final Widget Function(BuildContext context, int index, T item)? childBuilder;
  final void Function(int index)? onSelected;

  final Widget Function(BuildContext context)? customDropdownBuilder;

  final Widget? trigger;
  final Offset offset;
  final ShapeBorder shape;
  final double elevation;
  final Color? backgroundColor;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final String? semanticId;

  const FusionDropDown({
    this.semanticId,
    super.key,
    this.items,
    this.selectedIndex,
    this.itemBuilder,
    this.childBuilder,
    this.onSelected,
    this.customDropdownBuilder,
    this.trigger,
    this.tooltip,
    this.offset = const Offset(0, 40),
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    this.elevation = 1,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.dropdown(
      testId: SemanticHelper.createTestId(
        SemanticTypes.dropdown,
        "fusion_drop_down",
      ),
      value: selectedIndex == null ? 'No selection' : items?[selectedIndex as int].toString(),
      child: PopupMenuButton(
        tooltip: tooltip,
        offset: offset,
        shape: shape,
        elevation: elevation,
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        padding: padding ?? EdgeInsets.zero,
        onSelected: (value) {
          if (value is int && onSelected != null) {
            onSelected!(value);
          }
        },
        itemBuilder: (BuildContext context) {
          if (customDropdownBuilder != null) {
            // Case 2: Build custom widget
            return [
              PopupMenuItem(
                enabled: false,
                padding: EdgeInsets.zero,
                child: customDropdownBuilder!(context),
              ),
            ];
          }

          if (items != null && itemBuilder != null) {
            // Case 1: Build list with selection (selectedIndex can be null for no selection)
            return List<PopupMenuEntry<int>>.generate(items!.length, (index) {
              final isSelected = selectedIndex != null && index == selectedIndex;
              return PopupMenuItem<int>(
                value: index,
                padding: const EdgeInsets.all(12),
                child: itemBuilder!(context, items![index], isSelected),
              );
            });
          }

          throw Exception(
            "FusionDropDown requires either (items + itemBuilder) or (customDropdownBuilder)",
          );
        },
        child:
            trigger ??
            (items != null && selectedIndex != null && childBuilder != null
                ? childBuilder!(context, selectedIndex!, items![selectedIndex!])
                : const Icon(Icons.arrow_drop_down)),
      ),
    );
  }
}
