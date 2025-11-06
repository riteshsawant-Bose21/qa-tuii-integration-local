import 'package:flutter/material.dart';

const double _bRadius = 12;
const double _blurRadius = 10;

class PBTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String?>? onChanged;
  final double? height;
  final double? width;

  const PBTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(_bRadius),
        child: Container(
          height: height ?? 50,
          width: width ?? double.infinity,
          color: const Color(0xFFF5F5F5),
          child: Container(
            height: double.infinity,
            width: double.infinity,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.black12, blurRadius: _blurRadius, offset: Offset(0, -2)),
                BoxShadow(color: Colors.black12, blurRadius: _blurRadius, offset: Offset(-2, 0)),
                BoxShadow(color: Colors.white, blurRadius: _blurRadius),
                BoxShadow(color: Colors.white, blurRadius: _blurRadius, offset: Offset(10, 0)),
                BoxShadow(color: Colors.white, blurRadius: _blurRadius, offset: Offset(5, 5)),
              ],
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              cursorColor: Theme.of(context).colorScheme.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
