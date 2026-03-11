import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBIndicator extends StatelessWidget {
  const PBIndicator({
    super.key,
    required this.item,
    this.handler,
    this.semanticId,
  });
  final PBItem item;
  final PBWidgetValueHandler? handler;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    final PBIndicatorParam data = item.param as PBIndicatorParam;
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PB_indicator_${semanticId ?? ''}",
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double indicatorSize = constraints.maxWidth * 0.1;

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: indicatorSize.clamp(5, 10),
            children: <Widget>[
              Text(
                data.label,
                style: TextStyle(fontSize: indicatorSize.clamp(10, 16)),
              ),
              Container(
                width: indicatorSize.clamp(10, 32),
                height: indicatorSize.clamp(10, 32),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(),
            ],
          );
        },
      ),
    );
  }
}
