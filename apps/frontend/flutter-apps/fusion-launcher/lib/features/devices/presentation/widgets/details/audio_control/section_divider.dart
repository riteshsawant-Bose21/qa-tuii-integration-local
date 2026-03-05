import 'package:flutter/material.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int boxWidth = constraints.constrainWidth().floor();
          const double dashWidth = 2.0;
          const double dashHeight = 1.0;
          final int dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List<Widget>.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF424242)),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
