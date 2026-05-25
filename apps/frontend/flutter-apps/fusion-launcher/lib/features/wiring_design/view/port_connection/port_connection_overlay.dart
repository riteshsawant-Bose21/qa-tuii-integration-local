import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionExpansionPanel extends StatefulWidget {
  const FusionExpansionPanel({
    super.key,
    required this.content,
    required this.titleBuilder,
    this.initiallyExpanded = true,
    required this.semanticsId,
  });
  final Widget Function(BuildContext context, bool isExpanded) titleBuilder;
  final Widget content;
  final bool initiallyExpanded;
  final String semanticsId;
  @override
  State<FusionExpansionPanel> createState() => _FusionExpansionPanelState();
}

class _FusionExpansionPanelState extends State<FusionExpansionPanel> {
  bool isExpanded = false;
  void toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: widget.semanticsId,
      value: isExpanded.toString(),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SemanticHelper.container(
              testId: "${widget.semanticsId}_title",
              child: InkWell(
                onTap: toggleExpanded,
                child: widget.titleBuilder(context, isExpanded),
              ),
            ),
            if (isExpanded) SemanticHelper.container(testId: "${widget.semanticsId}_content", child: widget.content),
          ],
        ),
      ),
    );
  }
}
