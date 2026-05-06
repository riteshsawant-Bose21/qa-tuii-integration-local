// ─────────────────────────────────────────────────────────────
// Inline Floor Dropdown
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/floor_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'CommonWidgets/create_zone_icon_text-button.dart';

class InlineFloorDropdown extends StatefulWidget {
  const InlineFloorDropdown({
    required this.floors,
    required this.selectedFloor,
    required this.onFloorSelected,
    required this.onAddNewFloor,
  });

  final List<FloorModel> floors;
  final FloorModel? selectedFloor;
  final ValueChanged<FloorModel> onFloorSelected;
  final VoidCallback onAddNewFloor;

  @override
  State<InlineFloorDropdown> createState() => InlineFloorDropdownState();
}

class InlineFloorDropdownState extends State<InlineFloorDropdown> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => setState(() => _isOpen = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colorScheme.strokeLight, width: 1),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: widget.selectedFloor?.name ?? 'Select Floor',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: widget.selectedFloor == null ? context.colorScheme.onSurface.withAlpha(155) : context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: context.colorScheme.iconDefault,
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen) ...<Widget>[
            const SizedBox(height: 2),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                color: context.colorScheme.elevation2,
              ),
              child: Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() => _isOpen = false);
                      widget.onAddNewFloor();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: FusionIconTextButton(
                        icon: LucideIcons.plus200,
                        label: 'Add New Floor',
                        semanticId: 'add_new_floor_inline',
                        iconSize: 13,
                        onTap: () {
                          setState(() => _isOpen = false);
                          widget.onAddNewFloor();
                        },
                        iconColor: context.colorScheme.primaryWhite,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  Divider(height: 0, thickness: 0.5, color: context.colorScheme.strokeLight),
                  ...widget.floors.map((FloorModel floor) {
                    return GestureDetector(
                      onTap: () {
                        widget.onFloorSelected(floor);
                        setState(() => _isOpen = false);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: widget.selectedFloor?.id == floor.id ? context.colorScheme.elevation3 : Colors.transparent,
                        child: FusionAppText(
                          text: floor.name,
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
