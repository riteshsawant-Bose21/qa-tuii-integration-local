import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/constants/assets_constants.dart';

class EventItemCard extends StatefulWidget {
  final FusionEvent eventData;
  final ProjectViewModel projectViewModel;
  final bool isSelected;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final Function(String eventId)? onSwitchChanged;
  final int index;

  const EventItemCard({
    this.isSelected = false,
    super.key,
    required this.eventData,
    this.onDelete,
    this.onTap,
    required this.index,
    this.onSwitchChanged,
    required this.projectViewModel,
  });

  @override
  State<EventItemCard> createState() => _EventItemCardState();
}

class _EventItemCardState extends State<EventItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "event_item_card_${widget.index}"),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
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

          /// Card container
          child: Container(
            decoration: BoxDecoration(
              color: widget.isSelected ? context.colorScheme.elevation3 : (_isHovered ? context.colorScheme.elevation2 : null),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected ? context.colorScheme.elevation5 : Colors.transparent,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: <Widget>[
                /// snapshot item draggable icon
                ReorderableDragStartListener(
                  index: widget.index,
                  child: Opacity(
                    opacity: 0.4,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: context.colorScheme.textPlaceholder,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FusionImage.asset(
                  Assets.playIcon,
                  width: 24,
                  height: 24,
                  assetColor: context.colorScheme.iconWhite,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: TitleTextFieldSwitcher(
                    value: widget.eventData.name,
                    hintText: "Event name",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11),
                    save: (String value) {
                      if (value.isNotEmpty) {
                        final FusionEvent newSnapshot = widget.eventData.copyWith(name: value);
                        widget.projectViewModel.updateEvent(event: newSnapshot);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),
                SemanticHelper.toggle(
                  testId: SemanticHelper.createTestId(SemanticTypes.toggle, "event_switch"),
                  value: widget.eventData.isEnabled,
                  child: FusionSwitch(
                    value: widget.eventData.isEnabled,
                    onChanged: (bool value) {
                      if (widget.onSwitchChanged != null) {
                        widget.onSwitchChanged!(widget.eventData.id);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Tooltip(
                  message: 'Delete Snapshot',
                  child: SemanticHelper.button(
                    testId: SemanticHelper.createTestId(SemanticTypes.button, "delete_event_snapshot"),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => FusionDialog(
                                title: 'Delete Snapshot?',
                                description: "This will remove '${widget.eventData.name}' from the Snapshot list.",
                                primaryButtonLabel: 'Delete',
                                secondaryButtonLabel: 'Cancel',
                                onSecondaryPressed: () {
                                  Navigator.of(context).pop();
                                },
                                onPrimaryPressed: () {
                                  if (widget.onDelete != null) {
                                    widget.onDelete!();
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                        );
                      },
                      child: FusionImage.asset(
                        Assets.deleteIcon,
                        width: 17,
                        height: 17,
                        assetColor: context.colorScheme.iconWhite,

                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
