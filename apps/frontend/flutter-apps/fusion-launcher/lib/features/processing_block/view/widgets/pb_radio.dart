import 'package:flutter/material.dart';

const Color bgColor = Color(0xFFF5F5F5);
const Color activeColor = Color(0xFF333333);
const Color inactiveColor = Color(0xFFE5E5E5);

class PBRadio extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PBRadio({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double radioSize = (constraints.maxWidth * 0.3).clamp(36, 44);
        final double outerPadding = (constraints.maxWidth * 0.1).clamp(4, 8);
        final double innerPadding = (constraints.maxWidth * 0.05).clamp(1, 2);

        return GestureDetector(
          onTap: () => onChanged.call(!value),
          child: Container(
            height: radioSize,
            width: radioSize,
            color: bgColor,
            child: Container(
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.all(outerPadding),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: inactiveColor)),
              child: Container(
                height: double.infinity,
                width: double.infinity,
                padding: EdgeInsets.all(innerPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? activeColor : inactiveColor,
                ),
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? activeColor : inactiveColor,
                      border: Border.all(color: bgColor, width: innerPadding),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
