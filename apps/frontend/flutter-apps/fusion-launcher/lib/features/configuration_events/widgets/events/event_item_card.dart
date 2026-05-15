import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/events/configation_events_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../viewModel/events_viewmodel/config_events_state.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';

class EventItemCard extends StatefulWidget {
  final FusionEvent eventData;
  final ConfigEventsViewmodel cubit;
  final bool isSelected;
  final bool isInControlMode;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final Future<void> Function()? onEventRecall;
  final Function(String eventId, bool isEnabled)? onSwitchChanged;
  final int index;

  const EventItemCard({
    this.isSelected = false,
    this.isInControlMode = false,
    super.key,
    required this.eventData,
    this.onDelete,
    this.onTap,
    this.onEventRecall,
    required this.index,
    this.onSwitchChanged,
    required this.cubit,
  });

  @override
  State<EventItemCard> createState() => _EventItemCardState();
}

class _EventItemCardState extends State<EventItemCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleRecallTap() {
    if (!widget.isInControlMode || widget.onEventRecall == null) return;
    widget.onEventRecall!();
  }

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
                    child: FusionIcon.icon(
                      semanticId: "${FusionTestKeys.instance.events_itm_card_drag_icon}_${widget.index}",
                      Icons.drag_indicator,
                      size: 16,
                      color: context.colorScheme.textPlaceholder,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: widget.isInControlMode ? 'Recall Event' : 'Enable control mode to recall',
                  child: BlocBuilder<ConfigEventsViewmodel, ConfigEventsState>(
                    builder: (BuildContext context, ConfigEventsState eventsState) {
                      final bool isRecalling = eventsState.recallingEventId == widget.eventData.id;
                      return GestureDetector(
                        onTap: widget.isInControlMode && !isRecalling ? _handleRecallTap : null,
                        onTapDown: widget.isInControlMode && !isRecalling ? (_) => setState(() => _isPressed = true) : null,
                        onTapUp: (_) => setState(() => _isPressed = false),
                        onTapCancel: () => setState(() => _isPressed = false),
                        child: AnimatedScale(
                          scale: _isPressed ? 0.6 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                isRecalling
                                    ? Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.colorScheme.iconWhite,
                                        ),
                                      ),
                                    )
                                    : FusionImageAuto(
                                      path: Assets.playIcon,
                                      semanticId: "${FusionTestKeys.instance.events_itm_card_play_icon}_${widget.index}",
                                      width: 24,
                                      height: 24,
                                      color: widget.isInControlMode ? context.colorScheme.iconWhite : context.colorScheme.iconWhite.withAlpha(80),
                                      fit: BoxFit.contain,
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: TitleTextFieldSwitcher(
                    value: widget.eventData.name,
                    hintText: "Event name",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11),
                    save: (String value) {
                      if (value.isNotEmpty) {
                        final FusionEvent newEvent = widget.eventData.copyWith(name: value);
                        widget.cubit.updateEvent(newEvent);
                      }
                      return true;
                    },
                  ),
                ),

                const SizedBox(width: 8),
                SemanticHelper.toggle(
                  testId: SemanticHelper.createTestId(SemanticTypes.toggle, "${FusionTestKeys.instance.eventsswitch}_${widget.index}"),
                  value: widget.eventData.isEnabled,
                  child: IgnorePointer(
                    ignoring: !widget.isInControlMode,
                    child: Opacity(
                      opacity: widget.isInControlMode ? 1.0 : 0.4,
                      child: FusionSwitch(
                        height: 22,
                        width: 36,
                        value: widget.eventData.isEnabled,
                        onChanged: (bool value) {
                          if (widget.onSwitchChanged != null) {
                            widget.onSwitchChanged!(widget.eventData.id, value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Tooltip(
                  message: 'Delete Event',
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => FusionDialog(
                              title: 'Delete Event?',
                              description: "This will remove '${widget.eventData.name}' from the Event list.",
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
                    child: FusionImageAuto(
                      path: Assets.deleteIcon,
                      semanticId: "${FusionTestKeys.instance.deletevent}_${widget.index}",
                      width: 17,
                      height: 17,
                      color: context.colorScheme.iconWhite,
                      fit: BoxFit.contain,
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
