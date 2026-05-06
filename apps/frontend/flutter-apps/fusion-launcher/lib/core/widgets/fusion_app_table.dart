import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionTableHeader {
  final String title;
  final int flex;
  final Alignment aligment;

  FusionTableHeader({required this.title, required this.flex, this.aligment = Alignment.centerLeft});
}

class FusionAppTable extends StatelessWidget {
  const FusionAppTable({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 10,
    this.onRowTap,
    this.onReorder,
    this.keyExtractor,
    this.semanticId,
  });
  final List<FusionTableHeader> headers;
  final int itemCount;
  final List<Widget> Function(BuildContext context, int index) itemBuilder;
  final double spacing;
  final ValueChanged<int>? onRowTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final String Function(int index)? keyExtractor;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        /// table headers
        SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "fusion_table_header_$semanticId"),
          child: Container(
            margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                left: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              spacing: spacing,
              children: <Widget>[
                ...headers.map(
                  (final FusionTableHeader e) => Expanded(
                    flex: e.flex,
                    child: Align(
                      alignment: e.aligment,
                      child: FusionAppText(
                        semanticId: 'fusion_table_header_text',
                        text: e.title,
                        maxLine: 1,
                        style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// table rows
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
              ),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: itemCount,
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                onReorder?.call(oldIndex, newIndex);
              },
              buildDefaultDragHandles: false,
              itemBuilder: (BuildContext context, int index) {
                final List<Widget> rowItems = itemBuilder(context, index);
                final String key = keyExtractor != null ? keyExtractor!(index) : 'fusion_table_row_$index';
                return FusionTableRow(
                  key: ValueKey<String>(key),
                  rowKey: key,
                  index: index,
                  itemCount: itemCount,
                  rowItems: rowItems,
                  headers: headers,
                  spacing: spacing,
                  onRowTap: onRowTap,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FusionTableRow extends StatefulWidget {
  const FusionTableRow({
    super.key,
    required this.rowKey,
    required this.index,
    required this.itemCount,
    required this.rowItems,
    required this.headers,
    required this.spacing,
    required this.onRowTap,
  });

  final String rowKey;
  final int index;
  final int itemCount;
  final List<Widget> rowItems;
  final List<FusionTableHeader> headers;
  final double spacing;
  final ValueChanged<int>? onRowTap;

  @override
  State<FusionTableRow> createState() => _FusionTableRowState();
}

class _FusionTableRowState extends State<FusionTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _isHovered ? context.colorScheme.elevation2 : Colors.transparent,
          border: Border(
            bottom: widget.index != widget.itemCount - 1 ? BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1) : BorderSide.none,
          ),
        ),
        child: SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, "fusion_table_row_${widget.index}"),
          child: ReorderableDragStartListener(
            key: ValueKey<String>(widget.rowKey),
            index: widget.index,
            child: InkWell(
              hoverColor: Colors.transparent,
              onTap: widget.onRowTap != null ? () => widget.onRowTap!(widget.index) : null,
              child: Row(
                spacing: widget.spacing,
                children: List<Widget>.generate(
                  widget.headers.length,
                  (int i) => Expanded(
                    flex: widget.headers[i].flex,
                    child: Align(alignment: widget.headers[i].aligment, child: widget.rowItems[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
