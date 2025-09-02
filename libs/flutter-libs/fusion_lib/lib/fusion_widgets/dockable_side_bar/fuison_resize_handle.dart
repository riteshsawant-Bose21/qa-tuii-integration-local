import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FusionResizeHandle extends StatelessWidget {
  final void Function(double, double) onResize;

  const FusionResizeHandle({super.key, required this.onResize});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        onResize(details.delta.dx, details.delta.dy);
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
        ),
        child: const Icon(Icons.drag_handle, size: 14, color: Colors.white),
      ),
    );
  }
}
