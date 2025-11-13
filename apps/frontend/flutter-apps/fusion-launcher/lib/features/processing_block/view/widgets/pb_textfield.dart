import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import 'pb_button.dart';

class PBTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String?>? onSubmitted;
  final double? height;
  final double? width;
  final double borderRadius;
  final List<TextInputFormatter>? inputFormatters;

  const PBTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.onSubmitted,
    this.height,
    this.width,
    this.borderRadius = 10,
    this.inputFormatters,
  });

  @override
  State<PBTextField> createState() => _PBTextFieldState();
}

class _PBTextFieldState extends State<PBTextField> {
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
      child: Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isFocused ? null : getNeumorphismBoxShadows(inner: true),
          border: isFocused ? Border.all(color: Colors.black12, width: 2) : null,
        ),
        child: TextField(
          controller: widget.controller,
          textAlign: TextAlign.center,
          focusNode: _focusNode,
          style: Theme.of(context).textTheme.labelLarge,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            isDense: true,
            hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
            contentPadding: const EdgeInsets.all(0),
          ),
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}
