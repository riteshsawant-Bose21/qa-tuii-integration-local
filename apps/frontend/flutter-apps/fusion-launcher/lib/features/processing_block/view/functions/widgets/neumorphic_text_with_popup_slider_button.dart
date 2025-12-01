import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../common/neumorphic_button.dart';
import '../../widgets/pb_slider.dart';

class NeumorphicTextWithPopupSliderButton extends StatefulWidget {
  final bool isActive;
  final double? value;
  final VoidCallback? onTap;
  final ValueChanged<double>? onChanged;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double borderRadius;
  final double iconSize;

  const NeumorphicTextWithPopupSliderButton({
    super.key,
    required this.isActive,
    this.value,
    this.onTap,
    this.onChanged,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius = 8,
    this.iconSize = 24,
  });

  @override
  State<NeumorphicTextWithPopupSliderButton> createState() => _NeumorphicTextWithPopupSliderButtonState();
}

class _NeumorphicTextWithPopupSliderButtonState extends State<NeumorphicTextWithPopupSliderButton> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(widget.borderRadius),
      clipBehavior: widget.isActive ? Clip.hardEdge : Clip.none,
      child: Container(
        height: widget.height ?? 28,
        width: widget.width ?? double.infinity,
        clipBehavior: widget.isActive ? Clip.hardEdge : Clip.none,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: getNeumorphismBoxShadows(inner: widget.isActive, color: const Color(0xFFF9F7F6)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                // onTapDown: (_) => setState(() => _isPressed = true),
                // onTapCancel: () => setState(() => _isPressed = false),
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: widget.height ?? 32,
                  width: widget.width ?? double.infinity,
                  child: Center(
                    child: FusionAppText(
                      text: "${widget.value ?? 0.0}db",
                      maxLine: 1,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),

            const VerticalDivider(color: Colors.black12, thickness: 1, width: 1),
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: const PopupMenuThemeData(
                  color: Color(0xFFF5F5F5),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                ),
                splashColor: Colors.transparent, // Disable ripple
                highlightColor: Colors.transparent, // Disable tap highlight
                hoverColor: Colors.transparent, // Disable hover color
              ),
              child: PopupMenuButton<String>(
                color: const Color(0xFFF5F5F5),
                shadowColor: Colors.transparent,
                position: PopupMenuPosition.under,
                tooltip: '',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: const BorderSide(color: Color(0xFFB2B2B2), width: 1),
                ),
                offset: const Offset(0, 10),
                padding: EdgeInsets.zero,
                menuPadding: EdgeInsets.zero,
                clipBehavior: Clip.none,
                elevation: 2,
                constraints: const BoxConstraints(
                  maxWidth: 60,
                  maxHeight: 250,
                ),
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: const EdgeInsets.all(8).copyWith(right: 0),
                      child: SizedBox(
                        width: 60,
                        height: 200,
                        child: Center(
                          child: VerticalSlider(
                            value: widget.value ?? 0.0,
                            min: -60,
                            max: 12,
                            intervalGap: 12,
                            onChanged: (num value) {
                              widget.onChanged?.call(
                                value.toDouble(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                child: AbsorbPointer(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
