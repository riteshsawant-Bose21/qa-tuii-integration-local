import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class EventActionRowHeader extends StatelessWidget {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  const EventActionRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double responsivePadding = screenWidth * 0.12;
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
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
              ),

              /// add actions
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
        BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final String? selectedEventId = _projectViewModel.selectedEventId;

            if (selectedEventId == null) {
              return const SizedBox.shrink();
            }

            final FusionEvent selectedEvent = _projectViewModel.getEventById(selectedEventId);

            final List<EventStates>? states = selectedEvent.states;

            /// Hide if null or not exactly 2 states
            if (states == null || states.length != 2) {
              return const SizedBox.shrink();
            }

            /// Maintain order as provided by backend
            final EventStates left = states.first;
            final EventStates right = states.last;

            final Map<bool, Widget> sliderChildren = <bool, Widget>{
              true: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FusionAppText(
                  text: left.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.fusionTextViewColor,
                  ),
                ),
              ),
              false: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FusionAppText(
                  text: right.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.fusionTextViewColor,
                  ),
                ),
              ),
            };

            return Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(
                bottom: 20,
                right: responsivePadding,
              ),
              child: CupertinoSlidingSegmentedControl<bool>(
                children: sliderChildren,
                groupValue: true, // replace with actual value from ViewModel

                onValueChanged: (bool? value) {
                  if (value == null) return;

                  /// TODO: update ViewModel with selected state
                  // _projectViewModel.updateStateValue(
                  //   selectedEventId,
                  //   value ? left.stateType : right.stateType,
                  // );
                },
              ),
            );
          },
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
