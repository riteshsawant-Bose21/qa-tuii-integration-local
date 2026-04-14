import 'package:flutter/material.dart';


class CommonCircleIcon extends StatelessWidget {
  final double size;
  final Color bgColor;
  final Color iconColor;
  final double iconSize;
  final IconData icon;

  const CommonCircleIcon({
    this.size = 40,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.iconSize = 20,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}
