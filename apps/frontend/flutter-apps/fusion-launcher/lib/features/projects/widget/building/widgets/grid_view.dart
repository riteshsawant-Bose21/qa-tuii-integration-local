import 'package:flutter/material.dart';

class BuildingPageGridView extends StatelessWidget {
  const BuildingPageGridView({super.key, required this.children, this.width = 120, this.spacing = 8});

  final List<Widget> children;
  final double width;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int itemsPerRow = (constraints.maxWidth / width).floor().clamp(1, 100);

        final double actualWidth = (constraints.maxWidth - (itemsPerRow - 1) * spacing) / itemsPerRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            ...children.map((Widget child) {
              return SizedBox(
                width: actualWidth,
                child: child,
              );
            }),
          ],
        );
      },
    );
  }
}
