import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/constants/assets_constants.dart';

class SourceItem extends StatefulWidget {
  final Source source;

  const SourceItem({required this.source, super.key});

  @override
  State<SourceItem> createState() => _SourceItemState();
}

class _SourceItemState extends State<SourceItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey[200] : null,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
          children: <Widget>[
            FusionImage.asset(
              widget.source.assetImagePath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FusionAppText(
                text: widget.source.name,

                maxLine: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ),

            const FusionImage.asset(
              Assets.configurationFilledIcon,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const FusionImage.asset(
              Assets.processingBlocksFilledIcon,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
