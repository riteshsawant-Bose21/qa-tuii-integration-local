import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBSwitch extends StatelessWidget {
  const PBSwitch({
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
    final PBSwitchParam data =
        (handler?.resolveForItem(item) ?? item.param) as PBSwitchParam;
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PBSwitch_${semanticId ?? ''}",
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double mw = constraints.maxWidth;
          final TextStyle style = TextStyle(fontSize: (mw * 0.05).clamp(6, 12));
          return Row(
            spacing: (mw * 0.05).clamp(10, 20),
            children: <Widget>[
              Text(
                data.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: (mw * 0.05).clamp(10, 20),
                ),
              ),
              CupertinoSlidingSegmentedControl<bool>(
                children: <bool, Widget>{
                  true: Text(data.enableValueLabel ?? "Yes", style: style),
                  false: Text(data.disabledValueLabel ?? "No", style: style),
                },
                onValueChanged: (_) {
                  handler?.onValueChanged(
                    item,
                    !((handler?.getValue(item) ?? true) as bool),
                  );
                },
                groupValue: handler?.getValue(item) ?? true,
              ),
            ],
          );
        },
      ),
    );
  }
}
