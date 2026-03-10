import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../view/item_widget_builder.dart';

class PBEmpty extends StatelessWidget {
  const PBEmpty({
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
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PBEmpty_$semanticId",
      ),
      child: Container(),
    );
  }
}
