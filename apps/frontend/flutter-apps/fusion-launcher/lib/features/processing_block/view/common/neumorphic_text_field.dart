import 'package:flutter/material.dart';

import 'neumorphic_container.dart';

class NeumorphicTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String?>? onChanged;
  final double? height;
  final double? width;
  final double borderRadius;

  const NeumorphicTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.height,
    this.width,
    this.borderRadius = 10,
  });

  @override
  State<NeumorphicTextField> createState() => _NeumorphicTextFieldState();
}

class _NeumorphicTextFieldState extends State<NeumorphicTextField> {
  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: NeumorphicContainer(
        child: TextField(
          controller: widget.controller,
          textAlign: TextAlign.center,
          focusNode: _focusNode,
          style: Theme.of(context).textTheme.labelLarge,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            isDense: true,
            hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
            contentPadding: const EdgeInsets.all(0),
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
