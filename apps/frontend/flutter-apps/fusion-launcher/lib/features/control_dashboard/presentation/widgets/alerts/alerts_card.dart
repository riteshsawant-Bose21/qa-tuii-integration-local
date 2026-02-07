import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'alerts_dashboard.dart';

class AlertCard extends StatelessWidget {
  final AlertItem item;

  const AlertCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Define styles based on Alert Type
    final bool isCritical = item.type == AlertType.critical;

    // Critical: Red | Warning: Orange
    final Color accentColor =
        isCritical
            ? context
                .colorScheme
                .errorText // Red
            : context.colorScheme.warningText; // Orange

    final Color iconBgColor = isCritical ? context.colorScheme.errorText : context.colorScheme.warningText;

    final IconData iconData =
        isCritical
            ? Icons
                .gpp_bad_outlined // Shield/Exclamation
            : Icons.warning_amber_rounded; // Triangle

    // Subtle background tint
    final Color cardBgColor = isCritical ? context.colorScheme.errorFill : context.colorScheme.warningFill;

    final Color borderColor = isCritical ? context.colorScheme.errorStroke : context.colorScheme.warningStroke;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: <Widget>[
          // Top Section: Icon, Texts, Time
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconBgColor, width: 1.5),
                  ),
                  child: Icon(iconData, color: context.colorScheme.iconWhite, size: 20),
                ),
                const SizedBox(width: 12),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: FusionAppText(
                              text: item.title,
                              maxLine: 1,
                              textOverflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall!.copyWith(
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FusionAppText(
                            text: item.time,
                            style: context.textTheme.labelSmall!.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FusionAppText(
                        text: item.description,
                        style: context.textTheme.labelMedium!.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Divider
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DashedLinePainter(
              color: context.colorScheme.strokeLight,
            ),
          ),

          // Bottom Section: Device & Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: <Widget>[
                // 1. Wrap the Left Inner Row in Flexible
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Important: shrink-wrap the row
                    children: <Widget>[
                      const Icon(Icons.dns_outlined, color: Colors.grey, size: 16),
                      const SizedBox(width: 6),
                      // 2. Wrap the Text in Flexible so it truncates if space runs out
                      Flexible(
                        child: FusionAppText(
                          text: item.deviceId,
                          style: context.textTheme.labelSmall!.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                          textOverflow: TextOverflow.ellipsis,
                          maxLine: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16), // Use a fixed gap instead of Spacer() to avoid layout conflicts
                // 1. Wrap the Right Inner Row in Flexible
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.language, color: Colors.grey, size: 16),
                      const SizedBox(width: 6),
                      // 2. Wrap the Text in Flexible
                      Flexible(
                        child: FusionAppText(
                          text: item.location,
                          style: context.textTheme.labelSmall!.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                          textOverflow: TextOverflow.ellipsis,
                          maxLine: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. Custom Dashed Line Painter ---

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
