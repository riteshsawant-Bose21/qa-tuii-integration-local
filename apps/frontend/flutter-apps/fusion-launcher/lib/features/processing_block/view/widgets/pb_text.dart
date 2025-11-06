import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';

class PBText extends StatelessWidget {
  const PBText({super.key, required this.item});
  final PBItem item;
  @override
  Widget build(BuildContext context) {
    final PBTextParam data = item.param as PBTextParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: Text(
            data.label,
            style: TextStyle(
              fontSize: (constraints.maxWidth * 0.1).clamp(15, 25),
            ),
          ),
        );
      },
    );
  }
}
