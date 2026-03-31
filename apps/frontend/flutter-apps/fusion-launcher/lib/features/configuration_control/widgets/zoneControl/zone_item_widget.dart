import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Widget displaying a single zone with its subzones
class ZoneItemWidget extends StatefulWidget {
  final Zone zone;
  final List<SubZone> subZones;
  final bool isSelected;
  final bool isActiveZone;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onSelectZone;

  const ZoneItemWidget({
    super.key,
    required this.zone,
    this.subZones = const <SubZone>[],
    this.isSelected = false,
    this.isActiveZone = false,
    this.onToggleSelection,
    this.onSelectZone,
  });

  @override
  State<ZoneItemWidget> createState() => _ZoneItemWidgetState();
}

class _ZoneItemWidgetState extends State<ZoneItemWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Zone row
        _buildZoneRow(context),

        /// Subzones (if expanded)
        if (_isExpanded && widget.subZones.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children:
                  widget.subZones.map((SubZone subZone) {
                    return _buildSubZoneRow(context, subZone);
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildZoneRow(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelectZone,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: widget.isActiveZone ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: <Widget>[
            /// Zone color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.zone.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),

            /// Expand/collapse button (if has subzones)
            if (widget.subZones.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: context.colorScheme.iconDefault,
                ),
              ),
            if (widget.subZones.isEmpty) const SizedBox(width: 16),

            /// Zone name
            Expanded(
              child: FusionAppText(
                text: widget.zone.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: widget.isActiveZone ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),

            /// Radio button (for single selection)
            GestureDetector(
              onTap: widget.onSelectZone,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isActiveZone ? context.colorScheme.primary : context.colorScheme.iconDefault,
                    width: 2,
                  ),
                ),
                child:
                    widget.isActiveZone
                        ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colorScheme.primary,
                            ),
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 8),

            /// Settings icon
            GestureDetector(
              onTap: () {
                // TODO: Open zone settings
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

  Widget _buildSubZoneRow(BuildContext context, SubZone subZone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          /// Connection line indicator
          Container(
            width: 12,
            height: 1,
            color: context.colorScheme.elevation3,
          ),
          const SizedBox(width: 8),

          /// Subzone name
          Expanded(
            child: FusionAppText(
              text: subZone.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),

          /// Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: false, // TODO: Track subzone selection
              onChanged: (_) {
                // TODO: Handle subzone selection
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: context.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
