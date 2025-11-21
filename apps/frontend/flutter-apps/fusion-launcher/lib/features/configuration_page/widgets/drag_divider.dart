import 'package:flutter/material.dart';

class DragDivider extends StatelessWidget {
  final Function(double delta) onDragUpdate;

  const DragDivider({required this.onDragUpdate, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) => onDragUpdate(details.delta.dy),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 8,
          color: Colors.transparent,
          child: Center(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
