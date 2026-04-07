import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../zone_function_settings/select_settings/select_settings.dart';

class ZoneItemWidget extends StatefulWidget {
  final Zone zone;
  final List<SubZone> subZones;
  final bool isSelected;
  final bool isActiveZone;
  final bool isProController;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onSelectZone;
  final Function(String subZoneId)? onToggleSubZoneSelection;
  final Function(String subZoneId)? onSelectSubZone;
  final Set<String> selectedSubZoneIds;
  final String? activeSubZoneId;

  const ZoneItemWidget({
    super.key,
    required this.zone,
    this.subZones = const <SubZone>[],
    this.isSelected = false,
    this.isActiveZone = false,
    this.isProController = false,
    this.onToggleSelection,
    this.onSelectZone,
    this.onToggleSubZoneSelection,
    this.onSelectSubZone,
    this.selectedSubZoneIds = const <String>{},
    this.activeSubZoneId,
  });

  @override
  State<ZoneItemWidget> createState() => _ZoneItemWidgetState();
}

class _ZoneItemWidgetState extends State<ZoneItemWidget> {
  bool get _hasSubZones => widget.subZones.isNotEmpty;

  static const double _rowHorizontalPadding = 12.0;
  static const double _dotSize = 16.0;
  static const double _dotCenterX = _rowHorizontalPadding + (_dotSize / 2);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildZoneRow(context),
        if (_hasSubZones)
          ...widget.subZones.asMap().entries.map((MapEntry<int, SubZone> entry) {
            final int i = entry.key;
            final SubZone subZone = entry.value;
            return _buildSubZoneRow(
              context,
              subZone,
              isFirst: i == 0,
              isLast: i == widget.subZones.length - 1,
            );
          }),
      ],
    );
  }

  Widget _buildZoneRow(BuildContext context) {
    return GestureDetector(
      onTap: _hasSubZones ? null : widget.onSelectZone,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _rowHorizontalPadding,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          // color: widget.isActiveZone && !_hasSubZones ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: <Widget>[
            /// Zone color indicator dot
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: widget.zone.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: context.colorScheme.zone1Stroke,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),

            /// Zone name
            Expanded(
              child: FusionAppText(
                text: widget.zone.name,
                style: Theme.of(context).textTheme.l1Regular,
              ),
            ),

            /// Selection control: only if zone has NO subzones
            if (!_hasSubZones) _buildZoneSelectionControl(context),
            if (!_hasSubZones) const SizedBox(width: 8),

            /// Settings icon
            GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                  barrierColor: Colors.black54,
                  transitionDuration: const Duration(milliseconds: 200),
                  pageBuilder: (BuildContext buildContext, _, __) {
                    return SourceSelectAdditionalSettingsDialog(
                      zoneID: widget.zone.id,
                    );
                  },
                );
              },
              child: FusionIcon.icon(
                Icons.settings_outlined,
                size: 16,
                color: context.colorScheme.iconDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelectionControl(BuildContext context) {
    if (widget.isProController) {
      return GestureDetector(
        onTap: widget.onToggleSelection,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: widget.isSelected ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
              width: 2,
            ),
            color: widget.isSelected ? context.colorScheme.iconWhite : Colors.transparent,
          ),
          child: widget.isSelected ? Icon(Icons.check, size: 12, color: context.colorScheme.black) : null,
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onSelectZone,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isActiveZone ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
              width: 2,
            ),
          ),
          child:
              widget.isActiveZone
                  ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colorScheme.iconWhite,
                      ),
                    ),
                  )
                  : null,
        ),
      );
    }
  }

  Widget _buildSubZoneRow(
    BuildContext context,
    SubZone subZone, {
    required bool isFirst,
    required bool isLast,
  }) {
    final bool isSubZoneSelected = widget.selectedSubZoneIds.contains(subZone.id);
    final bool isSubZoneActive = widget.activeSubZoneId == subZone.id;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          /// Tree connector with curved corner
          SizedBox(
            width: _dotCenterX + _dotSize,
            child: CustomPaint(
              painter: _TreeLinePainter(
                color: context.colorScheme.strokeDark,
                isFirst: isFirst,
                isLast: isLast,
                lineX: _dotCenterX,
              ),
            ),
          ),

          /// Subzone content
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              margin: const EdgeInsets.only(bottom: 2, right: 28),
              decoration: BoxDecoration(
                // color: isSubZoneActive && !widget.isProController ? context.colorScheme.elevation2 : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(text: subZone.name, style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textBody)),
                  ),
                  _buildSubZoneSelectionControl(
                    context,
                    subZone,
                    isSubZoneSelected,
                    isSubZoneActive,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubZoneSelectionControl(
    BuildContext context,
    SubZone subZone,
    bool isSelected,
    bool isActive,
  ) {
    if (widget.isProController) {
      /// checkbox style selection for pro controllers
      return GestureDetector(
        onTap: () => widget.onToggleSubZoneSelection?.call(subZone.id),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
              width: 2,
            ),
            color: isSelected ? context.colorScheme.iconWhite : Colors.transparent,
          ),
          child: isSelected ? Icon(Icons.check, size: 12, color: context.colorScheme.textPrimary) : null,
        ),
      );
    } else {
      /// radio style selection for non-pro controllers
      return GestureDetector(
        onTap: () => widget.onSelectSubZone?.call(subZone.id),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
              width: 2,
            ),
          ),
          child:
              isActive
                  ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colorScheme.iconWhite,
                      ),
                    ),
                  )
                  : null,
        ),
      );
    }
  }
}

class _TreeLinePainter extends CustomPainter {
  final Color color;
  final bool isFirst;
  final bool isLast;
  final double lineX;

  _TreeLinePainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.lineX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final double midY = size.height / 2;
    const double cornerRadius = 8.0;

    final Path path = Path();

    // Always start from y=0 so lines connect seamlessly across rows
    path.moveTo(lineX, midY - cornerRadius);

    // Vertical line down to just before the curve
    // path.lineTo(lineX, midY - cornerRadius);

    // Rounded corner: from going-down to going-right
    path.quadraticBezierTo(
      lineX,
      midY, // control point
      lineX + cornerRadius,
      midY, // end point
    );

    // Horizontal line to right edge
    path.lineTo(size.width, midY);

    canvas.drawPath(path, paint);

    // Continue vertical line below midY for non-last subzones
    // if (!isLast) {
    canvas.drawLine(
      Offset(lineX, 0),
      isLast ? Offset(lineX, midY - cornerRadius) : Offset(lineX, size.height),
      paint,
    );
    // }
  }

  @override
  bool shouldRepaint(_TreeLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isFirst != isFirst || oldDelegate.isLast != isLast || oldDelegate.lineX != lineX;
}
