import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionTableColumn {
  final String key;
  final String header;
  final int flex; // Ensure this is int flex, not double width
  final bool sortable;
  final Alignment alignment;

  const FusionTableColumn({
    required this.key,
    required this.header,
    this.flex = 1,
    this.sortable = true,
    this.alignment = Alignment.centerLeft,
  });
}

class FusionTableCell {
  final dynamic value;
  final Widget child;
  const FusionTableCell({required this.value, required this.child});
}

class FusionTableRow {
  final String key;
  final Map<String, FusionTableCell> cells;
  final Function(String)? onDragEnter;
  final VoidCallback? onDragLeave;
  final Function(String)? onDrop;
  final bool isDragTarget;

  const FusionTableRow({
    required this.key,
    required this.cells,
    this.onDragEnter,
    this.onDragLeave,
    this.onDrop,
    this.isDragTarget = false,
  });
}

class FusionTable extends StatefulWidget {
  final List<FusionTableColumn> columns;
  final List<FusionTableRow> rows;

  const FusionTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  State<FusionTable> createState() => _FusionTableState();
}

class _FusionTableState extends State<FusionTable> {
  final ScrollController _verticalController = ScrollController();
  String? _sortColumnKey;
  bool _sortAscending = true;
  List<FusionTableRow> _sortedRows = <FusionTableRow>[];

  @override
  void initState() {
    super.initState();
    _sortedRows = List<FusionTableRow>.from(widget.rows);
  }

  @override
  void didUpdateWidget(FusionTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _applySorting();
    }
  }

  void _onSort(String key) {
    setState(() {
      if (_sortColumnKey == key) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnKey = key;
        _sortAscending = true;
      }
      _applySorting();
    });
  }

  void _applySorting() {
    if (_sortColumnKey == null) {
      _sortedRows = List<FusionTableRow>.from(widget.rows);
      return;
    }
    _sortedRows = List<FusionTableRow>.from(widget.rows);
    _sortedRows.sort((FusionTableRow a, FusionTableRow b) {
      final String aVal = a.cells[_sortColumnKey]?.value?.toString().toLowerCase() ?? '';
      final String bVal = b.cells[_sortColumnKey]?.value?.toString().toLowerCase() ?? '';
      if (aVal == '--' || aVal == 'unassigned') return 1;
      if (bVal == '--' || bVal == 'unassigned') return -1;
      return _sortAscending ? aVal.compareTo(bVal) : -aVal.compareTo(bVal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight)),
          ),
          child: Row(
            children:
                widget.columns.map((FusionTableColumn column) {
                  // FLEX HEADER
                  return Expanded(
                    flex: column.flex,
                    child: InkWell(
                      onTap: column.sortable ? () => _onSort(column.key) : null,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: FusionAppText(
                              text: column.header.toUpperCase(),
                              maxLine: 1,
                              textOverflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colorScheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (column.sortable && _sortColumnKey == column.key)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 14,
                                color: context.colorScheme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        // BODY
        Expanded(
          child: ListView.builder(
            controller: _verticalController,
            itemCount: _sortedRows.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildDataRow(_sortedRows[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(FusionTableRow row, int index) {
    return DragTarget<String>(
      onWillAccept: (_) => row.onDrop != null,
      onAccept: (String id) => row.onDrop?.call(id),
      onMove: (DragTargetDetails<String> d) => row.onDragEnter?.call(d.data),
      onLeave: (_) => row.onDragLeave?.call(),
      builder: (BuildContext context, List<String?> candidateData, List<dynamic> rejectedData) {
        final bool isDragOver = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // The 32px padding
          decoration: BoxDecoration(
            color: isDragOver ? context.colorScheme.primaryColor.withOpacity(0.1) : Colors.transparent,
            border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight.withOpacity(0.5))),
          ),
          child: Row(
            // FLEX BODY ROWS - This was likely causing the overflow
            children:
                widget.columns.map((FusionTableColumn column) {
                  return Expanded(
                    flex: column.flex,
                    child: Align(
                      alignment: column.alignment,
                      child: row.cells[column.key]?.child ?? const SizedBox(),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}
