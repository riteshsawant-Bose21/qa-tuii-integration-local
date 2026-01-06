import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

/// A widget that displays an event header with an editable snapshot name.
/// The header includes an icon and allows the user to tap on the snapshot name to edit it.
/// When the user finishes editing, the new name is validated and a callback is triggered if the name has changed.
/// Example usage:
/// ```dart
/// EventHeaderWidget(
///   snapshotName: 'My Event',
///   onNameChanged: (newName) {
///     // Handle name change
///   },
/// );
/// ```
/// Parameters:
/// - [eventName]: The current name of the snapshot to be displayed.
/// - [onNameChanged]: A callback function that is triggered when the snapshot name is changed.
/// Returns:
/// A [Container] widget containing the event header with editable snapshot name.
///

class EventHeaderWidget extends StatefulWidget {
  final String eventName;
  final Function(String)? onNameChanged;

  const EventHeaderWidget({
    super.key,
    required this.eventName,
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
    final String capitalizedName = widget.eventName.isNotEmpty ? widget.eventName[0].toUpperCase() + widget.eventName.substring(1) : widget.eventName;
    _textController = TextEditingController(text: capitalizedName);
    _focusNode = FocusNode();
  }

  /// Update the text controller if the snapshot name changes
  @override
  void didUpdateWidget(EventHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventName != widget.eventName) {
      // make widget.snapshotName first letter caps
      final String capitalizedName = widget.eventName.isNotEmpty ? widget.eventName[0].toUpperCase() + widget.eventName.substring(1) : widget.eventName;

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
    if (widget.onNameChanged != null && _textController.text.trim().isNotEmpty && _textController.text.trim() != widget.eventName) {
      widget.onNameChanged!(_textController.text.trim());
      FusionToast.success(context, message: 'Event renamed to "${_textController.text.trim()}"');
    } else {
      /// name cannot same and cant be empty, revert to old name and show toast
      final String capitalizedName = widget.eventName.isNotEmpty ? widget.eventName[0].toUpperCase() + widget.eventName.substring(1) : widget.eventName;
      _textController.text = capitalizedName;
      if (_textController.text.trim().isEmpty) {
        FusionToast.error(context, message: 'Event name cannot be empty.');
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
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.25,
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
                        text: widget.eventName.isNotEmpty ? widget.eventName[0].toUpperCase() + widget.eventName.substring(1) : widget.eventName,
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
