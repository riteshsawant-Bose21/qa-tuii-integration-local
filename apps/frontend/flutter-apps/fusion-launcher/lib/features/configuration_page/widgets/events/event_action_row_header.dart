import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class EventActionRowHeader extends StatelessWidget {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  const EventActionRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double responsivePadding = screenWidth * 0.12; // Responsive calculation instead of hardcoded 170

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.grey.withAlpha(100),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FusionAppText(
                text: "Actions",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
              ),
              // add actions
              GestureDetector(
                onTap: () {
                  final String eventId = _projectViewModel.selectedEventId!;

                  final FusionEvent selectedEvent = _projectViewModel.getEventById(eventId);
                  if (selectedEvent.isComplete) {
                    final SceneActionModel action = SceneActionModel();
                    _projectViewModel.addActionToEvent(eventId: eventId, action: action);
                  } else {
                    FusionToast.error(context, message: "Please complete the event trigger details before adding actions.");
                  }
                },
                child: const Icon(Icons.add, size: 16),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(top: 8, bottom: 8, right: responsivePadding),
          child: CupertinoSlidingSegmentedControl<bool>(
            children: <bool, Widget>{
              true: const Text(
                "Yes",
              ),
              false: const Text(
                "No",
              ),
            },
            onValueChanged: (_) {
              // onValueChangedhandler?.onValueChanged(item, !((handler?.getValue(item) ?? true) as bool));
            },
            groupValue: true,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Theme.of(context).colorScheme.grey.withAlpha(40),
          child: Row(
            children: <Widget>[
              SizedBox(width: screenWidth * 0.02), // Responsive width instead of hardcoded 30
              const _HeaderCell(text: "Action Type"),
              SizedBox(width: screenWidth * 0.02), // Responsive spacing instead of hardcoded 16

              const _HeaderCell(text: "Action Item"),
              SizedBox(width: screenWidth * 0.02),

              const _HeaderCell(text: "Param / Action"),
              SizedBox(width: screenWidth * 0.02),

              const _HeaderCell(
                text: "Value",
              ),
              SizedBox(width: screenWidth * 0.04), // Responsive spacing instead of hardcoded 64
            ],
          ),
        ),
      ],
    );
  }
}

/// Header cell widget
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FusionAppText(
        text: text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Theme.of(context).colorScheme.fusionTextViewColor,
        ),
        maxLine: 1,
      ),
    );
  }
}
