import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DottedLine extends StatelessWidget {
  const DottedLine({
    super.key,
    this.dotSize = 4,
    this.spacing = 4,
    this.color = Colors.black,
    this.direction = Axis.horizontal,
  });

  final double dotSize;
  final double spacing;
  final Color color;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "DottedLine",
      ),
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final int count =
              direction == Axis.horizontal
                  ? (constraints.maxWidth / (dotSize + spacing)).floor()
                  : (constraints.maxHeight / (dotSize + spacing)).floor();

          return Flex(
            direction: direction,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              count,
              (_) => Container(
                width: direction == Axis.horizontal ? dotSize : 2,
                height: direction == Axis.horizontal ? 2 : dotSize,
                decoration: BoxDecoration(
                  color: color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
