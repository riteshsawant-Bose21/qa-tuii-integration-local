import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class EventHeaderWidget extends StatefulWidget {
  final String snapshotName;
  final Function(String)? onNameChanged;

  const EventHeaderWidget({
    super.key,
    required this.snapshotName,
    this.onNameChanged,
  });

  @override
  State<EventHeaderWidget> createState() => _EventHeaderWidgetState();
}

class _EventHeaderWidgetState extends State<EventHeaderWidget> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.snapshotName);
    _focusNode = FocusNode();
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
      FusionToast.success(context, message: 'Event renamed to "${_textController.text.trim()}"');
    } else {
      /// name cannot same and cant be empty, revert to old name and show toast
      _textController.text = widget.snapshotName;
      if (_textController.text.trim().isEmpty) {
        FusionToast.error(context, message: 'Event name cannot be empty.');
      } else {
        FusionToast.error(context, message: 'Event name cannot be same as before.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.greyLight,
        // border bottom
        border: Border(
          bottom: BorderSide(width: 1, color: context.colorScheme.grey),
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
                      style: context.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
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
                        style: context.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLine: 1,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
