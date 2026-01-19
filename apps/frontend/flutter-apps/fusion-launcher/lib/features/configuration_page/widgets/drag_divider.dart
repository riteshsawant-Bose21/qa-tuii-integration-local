import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DragDivider extends StatelessWidget {
  final Function(double delta) onDragUpdate;

  const DragDivider({required this.onDragUpdate, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) => onDragUpdate(details.delta.dy),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Center(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: context.colorScheme.elevation3,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: context.colorScheme.elevation3,
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
