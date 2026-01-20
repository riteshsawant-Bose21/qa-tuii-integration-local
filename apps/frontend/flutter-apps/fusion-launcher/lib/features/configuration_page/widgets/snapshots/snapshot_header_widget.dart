import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class SnapshotHeaderWidget extends StatefulWidget {
  final VoidCallback onAdd;
  final VoidCallback onReorder;
  final String snapshotName;
  final Function(String)? onNameChanged;

  const SnapshotHeaderWidget({
    super.key,
    required this.onAdd,
    required this.onReorder,
    required this.snapshotName,
    this.onNameChanged,
  });

  @override
  State<SnapshotHeaderWidget> createState() => _SnapshotHeaderWidgetState();
}

class _SnapshotHeaderWidgetState extends State<SnapshotHeaderWidget> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    widget.snapshotName.isNotEmpty ? widget.snapshotName[0].toUpperCase() + widget.snapshotName.substring(1) : widget.snapshotName;

    _textController = TextEditingController(text: widget.snapshotName);
    _focusNode = FocusNode();
  }

  /// Update the text controller if the snapshot name changes
  @override
  void didUpdateWidget(SnapshotHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshotName != widget.snapshotName) {
      // make widget.snapshotName first letter caps
      final String capitalizedName =
          widget.snapshotName.isNotEmpty ? widget.snapshotName[0].toUpperCase() + widget.snapshotName.substring(1) : widget.snapshotName;

      _textController.text = capitalizedName;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _focusNode.requestFocus();
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
    if (widget.onNameChanged != null && _textController.text.trim().isNotEmpty && _textController.text.trim() != widget.snapshotName) {
      widget.onNameChanged!(_textController.text.trim());
      FusionToast.success(context, message: 'Snapshot renamed to "${_textController.text.trim()}"');
    } else {
      /// name cannot same and cant be empty, revert to old name and show toast
      final String capitalizedName =
          widget.snapshotName.isNotEmpty ? widget.snapshotName[0].toUpperCase() + widget.snapshotName.substring(1) : widget.snapshotName;
      _textController.text = capitalizedName;
      if (_textController.text.trim().isEmpty) {
        FusionToast.error(context, message: 'Snapshot name cannot be empty.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_header"),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          // border bottom
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            topLeft: Radius.circular(12),
          ),
          border: Border(
            bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.layers, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child:
                  _isEditing
                      ? TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: context.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _stopEditing(),
                        onTapOutside: (_) => _stopEditing(),
                      )
                      : GestureDetector(
                        onTap: _startEditing,
                        child: FusionAppText(
                          text: widget.snapshotName,
                          style: context.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLine: 1,
                        ),
                      ),
            ),
            GestureDetector(
              onTap: widget.onAdd,
              child: const Icon(Icons.add, size: 16),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onReorder,
              child: const Icon(Icons.more_vert, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
