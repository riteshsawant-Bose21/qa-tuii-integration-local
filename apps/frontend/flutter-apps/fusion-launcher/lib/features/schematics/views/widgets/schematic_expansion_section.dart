import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SchematicExpansionSection<T> extends StatefulWidget {
  const SchematicExpansionSection({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.title,
    required this.onReorder,
    required this.emptyMessage,
    this.action,
  });
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String title;
  final Widget? action;
  final void Function(T oldIndex, T newIndex) onReorder;
  final String emptyMessage;

  @override
  State<SchematicExpansionSection<T>> createState() => _SchematicExpansionSectionState<T>();
}

class _SchematicExpansionSectionState<T> extends State<SchematicExpansionSection<T>> {
  bool isExpanded = true;
  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "expandable_sections_container"),
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "expandable_section_${widget.title}"),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: <Widget>[
              SemanticHelper.toggle(
                testId: SemanticHelper.createTestId(SemanticTypes.toggle, "expandable_header_${widget.title}"),
                value: isExpanded,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: Row(
                    children: <Widget>[
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.25,
                        duration: const Duration(milliseconds: 200),
                        child: FusionSvgIcon(
                          icon: AssetSvg.expandUp,
                          size: FusionSizes.iconSize12,
                          color: context.colorScheme.iconWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FusionAppText(
                        text: widget.title,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (widget.action != null) widget.action!,
                    ],
                  ),
                ),
              ),
              SemanticHelper.container(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.container,
                  "expandable_content_${widget.title}",
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child:
                      isExpanded
                          ? widget.items.isEmpty
                              ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                child: Center(
                                  child: FusionAppText(
                                    text: widget.emptyMessage,
                                    textAlign: TextAlign.center,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontSize: FusionSizes.fontSize12,
                                      color: context.colorScheme.textBody,
                                    ),
                                  ),
                                ),
                              )
                              : ReorderableColumn<T>(
                                items: widget.items,
                                onReorder: (int oldIndex, int newIndex) {
                                  final T oldItem = widget.items[oldIndex];
                                  final T newItem = widget.items[newIndex];
                                  widget.onReorder(oldItem, newItem);
                                },
                                itemBuilder: (BuildContext context, T item) => widget.itemBuilder(context, item, widget.items.indexOf(item)),
                              )
                          : const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
