import 'package:flutter/material.dart';

class BuildingPageGridView extends StatelessWidget {
  const BuildingPageGridView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const double itemWidth = 120;
    const double spacing = 8;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int itemsPerRow = (constraints.maxWidth / itemWidth).floor().clamp(1, 100);

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
