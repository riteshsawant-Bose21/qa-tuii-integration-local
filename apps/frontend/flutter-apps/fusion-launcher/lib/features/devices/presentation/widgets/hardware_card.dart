import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class HardwareCard extends StatelessWidget {
  final FusionNetworkDevice hardware;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const HardwareCard({
    super.key,
    required this.hardware,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: hardware.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(
            width: 280, // Fixed width for drag feedback
            child: _buildCardContent(context, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(context),
      ),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool isDragging = false}) {
    return Container(
      // Use constrained width during drag, otherwise fit parent
      width: isDragging ? 280 : null,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        // color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      // LayoutBuilder allows us to check if we are too narrow
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Calculate if we have enough space for text
          // 20px (Icon) + 8px (Gap) = 28px minimum reserved
          final bool showText = constraints.maxWidth > 50 || isDragging;

          return Row(
            children: <Widget>[
              // 1. EXPANDED: Forces the column to take only remaining space
              if (showText)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Shrink vertically
                    children: <Widget>[
                      // 2. FLEXIBLE: Ensures text doesn't force width issues
                      Flexible(
                        child: FusionAppText(
                          text: hardware.name,
                          style: context.textTheme.bodyMedium,
                          textOverflow: TextOverflow.ellipsis,
                          maxLine: 1,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: FusionAppText(
                          text: "IP: ${hardware.address}",
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                          textOverflow: TextOverflow.ellipsis,
                          maxLine: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),

              if (showText) const SizedBox(width: 8), // Reduce gap slightly
              // 3. ICON: Always visible, pushed to end
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: context.colorScheme.iconWhite,
              ),
            ],
          );
        },
      ),
    );
  }
}
