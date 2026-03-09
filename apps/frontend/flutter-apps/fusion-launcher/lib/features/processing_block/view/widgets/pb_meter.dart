import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_vertical_meter.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBMeter extends StatelessWidget {
  const PBMeter({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.handler,
    this.semanticId,
  });

  final PBItem item;
  final bool showIntervals;
  final PBWidgetValueHandler? handler;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    final PBMeterParam data =
        (handler?.resolveForItem(item) ?? item.param) as PBMeterParam;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PBMeter_${semanticId ?? ''}",
      ),
      child: VerticalMeter(
        value: handler?.getValue(item) ?? item.value ?? 40,
        min: data.min,
        max: data.max,
        showIntervals: showIntervals,
      ),
    );
  }
}
