import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TitleTextFieldSwitcher extends StatefulWidget {
  const TitleTextFieldSwitcher({
    super.key,
    required this.save,
    required this.style,
    required this.value,
  });
  final String value;
  final ValueChanged<String> save;
  final TextStyle style;
  @override
  State<TitleTextFieldSwitcher> createState() => _TitleTextFieldSwitcherState();
}

class _TitleTextFieldSwitcherState extends State<TitleTextFieldSwitcher> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isEditing = false;
  late String currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
    controller.text = widget.value;

    focusNode.addListener(() {
      if (!focusNode.hasFocus && isEditing) {
        _saveValue();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      isEditing = true;
      controller.text = currentValue;
    });

    // Focus and select all text after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  void _saveValue() {
    if (isEditing) {
      if (controller.text.isEmpty) {
        _cancelEditing();
        return;
      }
      setState(() {
        currentValue = controller.text;
        isEditing = false;
      });
      widget.save(controller.text);
    }
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      controller.text = currentValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: isEditing,
      child:
          isEditing
              ? Focus(
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _cancelEditing();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: widget.style,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _saveValue(),
                  onTapOutside: (_) => _saveValue(),
                ),
              )
              : GestureDetector(
                behavior: HitTestBehavior.translucent,

                onDoubleTap: _startEditing,
                child: Text(
                  currentValue,
                  style: widget.style,
                ),
              ),
    );
  }
}
