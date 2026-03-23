import 'package:flutter/material.dart' hide Thumb;
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../item_widget_builder.dart';

class PBSlider extends StatelessWidget {
  const PBSlider({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.onChanged,
    this.handler,
    this.semanticId,
  });

  final PBItem item;
  final bool showIntervals;
  final ValueChanged<num>? onChanged;
  final PBWidgetValueHandler? handler;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    final PBSliderParam data =
        (handler?.resolveForItem(item) ?? item.param) as PBSliderParam;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PBSlider_${semanticId ?? ''}",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              data.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: VerticalSlider(
              semanticId: 'pb_slider_$semanticId',
              value: handler?.getValue(item) ?? item.value ?? 10,
              min: data.min,
              max: data.max,
              showIntervals: showIntervals,
              activeColor: context.colorScheme.primary,
              onChanged:
                  onChanged ??
                  (num value) {
                    print("ON CHANGED: $value");
                    handler?.onValueChanged(item, value);
                  },
            ),
          ),
        ],
      ),
    );
  }
}
