import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionResizeHandle extends StatelessWidget {
  final void Function(double, double) onResize;
  final String semanticId;

  const FusionResizeHandle({
    super.key,
    required this.onResize,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        'fusion_resize_handle${semanticId}',
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          onResize(details.delta.dx, details.delta.dy);
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: const Icon(Icons.drag_handle, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
