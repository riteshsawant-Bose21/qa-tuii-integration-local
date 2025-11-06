import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

const double _bRadius = 12;
const double _blurRadius = 10;

class PBDropdown<T> extends StatelessWidget {
  final String? value;
  final String hintText;
  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T> onChanged;
  final double? height;
  final double? width;

  const PBDropdown({
    super.key,
    this.value,
    required this.hintText,
    required this.itemBuilder,
    required this.onChanged,
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
            margin: const EdgeInsets.all(3),
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
            child: PopupMenuButton<T>(
              color: Colors.white,
              elevation: 1,
              position: PopupMenuPosition.under,
              itemBuilder: itemBuilder,
              onSelected: onChanged,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(child: FusionAppText(text: value ?? hintText, maxLine: 1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: VerticalDivider(
                        width: 5,
                        thickness: 2,
                        color: Color(0xFFE5E5E5),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
