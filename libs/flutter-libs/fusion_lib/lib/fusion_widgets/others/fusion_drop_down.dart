import 'dart:math' as math show pi;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

class FusionDropdown2<T> extends StatefulWidget {
  final String? title;
  final T? selectedValue;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T>? onChanged;
  final String placeholder;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const FusionDropdown2({
    super.key,
    this.title,
    required this.items,
    required this.labelBuilder,
    this.selectedValue,
    this.onChanged,
    this.placeholder = "Select",
    this.padding,
    this.borderRadius = 12.0,
  });

  @override
  State<FusionDropdown2<T>> createState() => _FusionDropdown2State<T>();
}

class _FusionDropdown2State<T> extends State<FusionDropdown2<T>> {
  bool isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final GlobalKey childKey = GlobalKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.title != null) ...<Widget>[
          FusionAppText(
            text: widget.title!,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          key: childKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final RenderBox box = childKey.currentContext!.findRenderObject() as RenderBox;

              final Offset pos = box.localToGlobal(Offset.zero);
              final double width = box.size.width;

              setState(() => isMenuOpen = true);

              final T? result = await showMenu<T>(
                context: context,
                color: context.colorScheme.surface,
                elevation: 0,
                constraints: BoxConstraints.tightFor(width: width),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: BorderSide(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                position: RelativeRect.fromLTRB(
                  pos.dx,
                  pos.dy + box.size.height + 4,
                  pos.dx + width,
                  0,
                ),
                items: <PopupMenuEntry<T>>[
                  ...widget.items.map(
                    (T item) {
                      return PopupMenuItem<T>(
                        value: item,
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: FusionAppText(
                                  text: widget.labelBuilder(item),
                                  style: context.textTheme.labelMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );

              setState(() => isMenuOpen = false);

              if (result != null) widget.onChanged?.call(result);
            },
            child: SemanticHelper.button(
              testId: SemanticHelper.createTestId(
                SemanticTypes.button,
                "${widget.title ?? 'dropdown'}_dropdown_button",
              ),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: isMenuOpen ? context.colorScheme.primaryWhite : context.colorScheme.strokeLight,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: widget.selectedValue != null ? widget.labelBuilder(widget.selectedValue as T) : widget.placeholder,
                        maxLine: 1,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.textPrimary.withValues(
                            alpha: widget.selectedValue != null ? 1.0 : 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.rotate(
                      angle: isMenuOpen ? math.pi : 0,
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: context.colorScheme.iconDefault,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
