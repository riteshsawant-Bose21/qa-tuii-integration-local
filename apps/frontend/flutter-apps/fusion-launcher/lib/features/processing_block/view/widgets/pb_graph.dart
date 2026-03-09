import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBGraph extends StatelessWidget {
  const PBGraph({
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
    final PBGraphParam data = item.param as PBGraphParam;
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PB_graph_$semanticId",
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            color: Colors.grey,
            child: Center(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: (constraints.maxWidth * 0.1).clamp(15, 25),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
