import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';

class PBIndicator extends StatelessWidget {
  const PBIndicator({super.key, required this.item});
  final PBItem item;

  @override
  Widget build(BuildContext context) {
    final PBIndicatorParam data = item.param as PBIndicatorParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double indicatorSize = constraints.maxWidth * 0.1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: indicatorSize.clamp(5, 10),
          children: <Widget>[
            Text(data.label, style: TextStyle(fontSize: indicatorSize.clamp(10, 16))),
            Container(
              width: indicatorSize.clamp(10, 32),
              height: indicatorSize.clamp(10, 32),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(),
          ],
        );
      },
    );
  }
}
