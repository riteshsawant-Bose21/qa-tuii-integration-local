import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBText extends StatelessWidget {
  const PBText({
    super.key,
    required this.item,
    this.handler,
    required this.semanticId,
  });
  final PBItem item;
  final PBWidgetValueHandler? handler;
  final String semanticId;
  @override
  Widget build(BuildContext context) {
    final PBTextParam data = item.param as PBTextParam;
    return SemanticHelper.staticText(
      testId: SemanticHelper.createTestId(
        SemanticTypes.text,
        "PB_text_$semanticId",
      ),
      label: data.label,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Center(
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: (constraints.maxHeight * 0.1).clamp(15, 25),
              ),
            ),
          );
        },
      ),
    );
  }
}
