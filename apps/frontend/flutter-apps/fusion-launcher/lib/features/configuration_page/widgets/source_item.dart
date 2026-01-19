import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_chain_view.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/constants/assets_constants.dart';

class SourceItem extends StatefulWidget {
  final Source source;
  final SourceSet? sourceSet;
  final bool isDragging;

  const SourceItem({
    required this.source,
    this.sourceSet,
    this.isDragging = false,
    super.key,
  });

  @override
  State<SourceItem> createState() => _SourceItemState();
}

class _SourceItemState extends State<SourceItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDragging ? Theme.of(context).colorScheme.primary.withAlpha(150) : (_isHovered ? context.colorScheme.elevation2 : null),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.isDragging ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 1.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: <Widget>[
            if (widget.sourceSet != null)
              Opacity(
                opacity: 0.4,
                child: FusionImage.asset(
                  widget.sourceSet!.isLinked ? Assets.linkIcon : null,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
              ),
            if (widget.sourceSet != null) const SizedBox(width: 8),
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
            // todo : add configuration icon back in when source configuration is supported (ex:media player)
            // const FusionImage.asset(
            //   Assets.configurationFilledIcon,
            //   width: 24,
            //   height: 24,
            //   fit: BoxFit.contain,
            // ),
            const SizedBox(width: 8),
            if (!widget.isDragging)
              InkWell(
                onTap: () {
                  ProcessingChainView.showForSource(context, widget.source);
                },
                child: const FusionImage.asset(
                  Assets.processingBlocksFilledIcon,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // /// Override equality operator and hashCode for proper comparison
  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;
  //   return other is _SourceItemState &&
  //       other.widget.source.id == widget.source.id &&
  //       other.widget.isDragging == widget.isDragging &&
  //       other._isHovered == _isHovered;
  // }
  //
  // @override
  // int get hashCode => Object.hash(widget.source.id, widget.isDragging, _isHovered);
}
