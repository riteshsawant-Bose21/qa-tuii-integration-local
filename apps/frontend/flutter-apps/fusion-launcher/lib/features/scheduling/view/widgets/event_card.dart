import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_utils/color_utils.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:intl/intl.dart';

import '../../viewmodel/scheduler_viewmodel.dart';
import '../sections/scheduler_form.dart';

class EventCard extends StatelessWidget {
  final CalendarEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final Color pillColor = ColorUtils.hexToColor(event.schedule.colorHex);

    return GestureDetector(
      onTap: () {
        // Navigator.of(context).pop();
        SchedulerForm.show(context, context.read<SchedulerViewmodel>(), initial: event.schedule);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: pillColor.withAlpha(155),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FusionAppText(
                text: '${DateFormat('hh:mm a').format(event.startTime)}  ${event.title}',
                style: context.textTheme.l1Regular,
                maxLine: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
