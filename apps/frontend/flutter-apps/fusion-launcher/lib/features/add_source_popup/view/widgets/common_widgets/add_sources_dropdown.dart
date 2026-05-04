import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A reusable dropdown selector styled with a rounded outlined container
/// and a chevron icon.
///
/// Usage:
/// ```dart
/// // Simple string label
/// FusionOutlinedDropdown<SourceSectionType>(
///   label: 'Source Type',
///   hint: 'Select Source Type',
///   value: state.selectedType,
///   items: SourceSectionType.values,
///   itemLabelBuilder: (item) => item.displayName,
///   onChanged: (value) => viewModel.setType(value),
/// )
///
/// // Custom label builder
/// FusionOutlinedDropdown<SourceData>(
///   labelBuilder: (context) => Row(
///     children: [
///       Icon(Icons.source, size: 14),
///       SizedBox(width: 4),
///       Text('Source Type'),
///     ],
///   ),
///   hint: 'Select Source',
///   ...
/// )
///
/// // Custom item + selected item rendering
/// FusionOutlinedDropdown<SourceData>(
///   label: 'Source',
///   hint: 'Select Source',
///   value: selectedSource,
///   items: sources,
///   itemLabelBuilder: (item) => item.name,
///   itemWidgetBuilder: (context, item, isSelected) => Row(
///     children: [
///       Image.asset(item.assetPath, height: 14, width: 14),
///       SizedBox(width: 8),
///       Expanded(child: Text(item.name)),
///     ],
///   ),
///   selectedItemBuilder: (context, item) => Row(
///     children: [
///       Image.asset(item.assetPath, height: 14, width: 14),
///       SizedBox(width: 8),
///       Expanded(child: Text(item.name)),
///     ],
///   ),
///   onChanged: (value) => viewModel.setSource(value),
/// )
/// ```
class FusionOutlinedDropdown<T> extends StatefulWidget {
  /// Simple string label displayed above the dropdown.
  /// Ignored if [labelBuilder] is provided.
  final String? label;

  /// Custom label widget builder displayed above the dropdown.
  /// Takes precedence over [label].
  final Widget Function(BuildContext context)? labelBuilder;

  /// Placeholder text shown when no value is selected.
  final String hint;

  /// Currently selected value. `null` shows the hint.
  final T? value;

  /// List of selectable items.
  final List<T> items;

  /// Converts an item of type [T] to a display string.
  /// Used for default item rendering and the selected value display.
  final String Function(T item) itemLabelBuilder;

  /// Optional custom builder for each item in the popup list.
  /// If null, falls back to a default row with text + check icon.
  final Widget Function(BuildContext context, T item, bool isSelected)? itemWidgetBuilder;

  /// Optional custom builder for displaying the selected value
  /// inside the dropdown trigger. If null, falls back to
  /// [itemLabelBuilder] as plain text.
  final Widget Function(BuildContext context, T item)? selectedItemBuilder;

  /// Called when the user picks a new value.
  final ValueChanged<T> onChanged;

  /// If `true`, the dropdown is greyed out and non-interactive.
  final bool enabled;

  /// Optional semantic / test id.
  final String? semanticId;

  /// Dropdown width. Defaults to full available width.
  final double? width;

  /// Dropdown height. Defaults to 48.
  final double height;

  /// Border radius of the container. Defaults to 12.
  final double borderRadius;

  const FusionOutlinedDropdown({
    super.key,
    this.label,
    this.labelBuilder,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    this.itemWidgetBuilder,
    this.selectedItemBuilder,
    required this.onChanged,
    this.enabled = true,
    this.semanticId,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
  });

  @override
  State<FusionOutlinedDropdown<T>> createState() => _FusionOutlinedDropdownState<T>();
}

class _FusionOutlinedDropdownState<T> extends State<FusionOutlinedDropdown<T>> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── Label ──────────────────────────────────────────
        if (widget.labelBuilder != null) ...<Widget>[
          widget.labelBuilder!(context),
          const SizedBox(height: 8),
        ] else if (widget.label != null) ...<Widget>[
          FusionAppText(
            text: widget.label!,
            style: context.textTheme.l1Medium.copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Dropdown ───────────────────────────────────────
        IgnorePointer(
          ignoring: !widget.enabled,
          child: FusionPopupMenu<T>(
            items: widget.items,
            tooltip: widget.hint,
            semanticsId: widget.semanticId ?? '',
            popupOffset: const Offset(0, 4),
            matchChildWidth: true,
            onSelected: widget.onChanged,
            itemBuilder: (BuildContext context, T item) {
              final bool isSelected = item == widget.value;

              if (widget.itemWidgetBuilder != null) {
                return widget.itemWidgetBuilder!(context, item, isSelected);
              }

              return Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: widget.itemLabelBuilder(item),
                      maxLine: 1,
                      style: context.textTheme.b3Regular.copyWith(
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    FusionIcon.icon(
                      Icons.check,
                      size: 14,
                      color: context.colorScheme.iconWhite,
                    ),
                ],
              );
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => hovered = true),
              onExit: (_) => setState(() => hovered = false),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: hovered ? context.colorScheme.elevation2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: context.colorScheme.strokeLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: _buildSelectedContent(context)),
                    FusionIcon.icon(
                      LucideIcons.chevronDown200,
                      size: 20,
                      color: context.colorScheme.iconWhite,
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

  Widget _buildSelectedContent(BuildContext context) {
    if (widget.value == null) {
      return FusionAppText(
        text: widget.hint,
        maxLine: 1,
        style: context.textTheme.b3Regular.copyWith(
          color: context.colorScheme.textPlaceholder,
        ),
      );
    }

    if (widget.selectedItemBuilder != null) {
      return widget.selectedItemBuilder!(context, widget.value as T);
    }

    return FusionAppText(
      text: widget.itemLabelBuilder(widget.value as T),
      maxLine: 1,
      style: context.textTheme.b3Regular.copyWith(
        color: context.colorScheme.textPrimary,
      ),
    );
  }
}
