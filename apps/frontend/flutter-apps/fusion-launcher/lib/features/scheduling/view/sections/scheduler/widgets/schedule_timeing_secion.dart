import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/sheduler_calendar.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/time_picker.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/weekly_day_section.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_switch.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scheduler_config.dart';

import '../../../../viewmodel/scheduler_form_viewmodel.dart';
import 'date_field.dart';
import 'inline_clock_picker.dart';

class ScheduleTimingSection extends StatefulWidget {
  const ScheduleTimingSection({super.key, required this.formViewModel});
  final SchedulerFormViewModel formViewModel;

  @override
  State<ScheduleTimingSection> createState() => ScheduleTimingSectionState();
}

class ScheduleTimingSectionState extends State<ScheduleTimingSection> {
  bool _dateRangeEnabled = false;
  bool _showInlineClock = false;
  DateFieldTarget? _openField;
  final GlobalKey _calendarKey = GlobalKey();
  ClockMode _clockMode = ClockMode.hour;
  TimePickerController? _timePickerController;
  @override
  void initState() {
    super.initState();
    _dateRangeEnabled = widget.formViewModel.startDate != null || widget.formViewModel.endDate != null;
    if (!_dateRangeEnabled && widget.formViewModel.recurrenceType != RecurrenceType.none && widget.formViewModel.startDate == null) {
      widget.formViewModel.startDate = DateTime.now();
    }
  }

  void _scrollToCalendar() {
    Future<Null>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final BuildContext? calendarContext = _calendarKey.currentContext;
      if (calendarContext != null) {
        Scrollable.ensureVisible(
          calendarContext,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final SchedulerFormViewModel formViewModel = widget.formViewModel;
    final RecurrenceType type = formViewModel.recurrenceType;
    final bool isOnce = type == RecurrenceType.none;
    final bool isWeekly = type == RecurrenceType.weekly;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Set Time header
          Row(
            children: <Widget>[
              FusionAppText(
                semanticId: 'scheduler_form_timing_section_label',
                text: "Set Time",
                style: context.textTheme.b3Medium,
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() => _showInlineClock = !_showInlineClock);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FusionIcon.icon(
                    semanticId: 'scheduler_form_timing_section_time_input_type_icon',
                    _showInlineClock ? Icons.keyboard_alt_outlined : Icons.access_time,
                    size: 16,
                    color: context.colorScheme.iconDefault,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeOut,
            child: SizedBox(
              width: double.infinity,
              child:
                  _showInlineClock
                      ? SemanticHelper.container(
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.container,
                          "scheduler_form_timing_section_inline_clock",
                        ),
                        value: '${formViewModel.startTime.hour}:${formViewModel.startTime.minute}',
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InlineClockPicker(
                            mode: _clockMode,
                            time: formViewModel.startTime,
                            onChanged: (TimeOfDay value) {
                              formViewModel.startTime = value;
                            },
                            onHourSelected: () {
                              _timePickerController?.focusMinute();
                            },
                          ),
                        ),
                      )
                      : const SizedBox(width: double.infinity),
            ),
          ),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_time_input"),
            value: '${formViewModel.startTime.hour}:${formViewModel.startTime.minute}',
            child: TimePicker(
              mainAxisAlignment: _showInlineClock ? MainAxisAlignment.center : MainAxisAlignment.start,
              time: formViewModel.startTime,
              onChanged: (TimeOfDay value) {
                formViewModel.startTime = value;
              },
              onFieldFocused: (ClockMode mode) {
                if (_clockMode != mode) {
                  setState(() => _clockMode = mode);
                }
              },
              onReady: (TimePickerController controller) {
                _timePickerController = controller;
              },
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
          const SizedBox(height: 20),

          /// Weekly only: On Days
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: isWeekly ? const WeeklyDaySelection() : const SizedBox.shrink(),
          ),

          /// Once → single Set Date.  Weekly/Daily → toggleable Set Date Range.
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_date_input"),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: isOnce ? _buildSingleDate(context, formViewModel) : _buildDateRange(context, formViewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar({
    required DateTime? selectedDate,
    required DateTime? minDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    final TextStyle baseDayStyle = context.textTheme.l1Regular.withColor(
      context.colorScheme.textPrimary,
    );

    return CalendarWithOverlayPickers(
      key: _calendarKey,
      selectedDate: selectedDate,
      minDate: minDate,
      onPicked: onPicked,
      baseDayStyle: baseDayStyle,
    );
  }

  Widget _buildSingleDate(
    BuildContext context,
    SchedulerFormViewModel formViewModel,
  ) {
    return Column(
      key: const ValueKey<String>('single_date'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(semanticId: 'scheduler_form_timing_section_date_input_label', text: "Set Date", style: context.textTheme.b3Medium),
        const SizedBox(height: 8),
        DateFieldBox(
          semanticId: 'single',
          target: DateFieldTarget.single,
          selectedDate: formViewModel.startDate,
          isOpen: _openField == DateFieldTarget.single,

          hasError: false,
          onTap: () {
            setState(() {
              _openField = _openField == DateFieldTarget.single ? null : DateFieldTarget.single;
            });
            if (_openField != null) _scrollToCalendar();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child:
              _openField == DateFieldTarget.single
                  ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SemanticHelper.container(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.container,
                        "scheduler_form_timing_section_date_input_calendar",
                      ),
                      child: _buildCalendar(
                        selectedDate: formViewModel.startDate,
                        minDate: null,
                        onPicked: (DateTime date) {
                          formViewModel.startDate = date;
                          formViewModel.endDate = date;
                          setState(() => _openField = null);
                        },
                      ),
                    ),
                  )
                  : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildDateRange(
    BuildContext context,
    SchedulerFormViewModel formViewModel,
  ) {
    return Column(
      key: const ValueKey<String>('date_range'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            FusionSwitch(
              semanticId: 'scheduler_form_timing_section_date_range_input_switch',
              width: 44,
              height: 24,
              value: _dateRangeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _dateRangeEnabled = value;
                  if (!value) {
                    formViewModel.startDate = DateTime.now();
                    formViewModel.endDate = null;
                    _openField = null;
                  } else {
                    formViewModel.startDate = null;
                    formViewModel.endDate = null;
                    _openField = null;
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            FusionAppText(
              semanticId: 'scheduler_form_timing_section_date_range_input_label',
              text: "Set Date Range",
              style: context.textTheme.b3Medium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: _dateRangeEnabled ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !_dateRangeEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            semanticId: 'scheduler_form_timing_section_date_range_input_from_label',
                            text: "From",
                            style: context.textTheme.l1Medium,
                          ),
                          const SizedBox(height: 8),
                          DateFieldBox(
                            semanticId: 'from',
                            target: DateFieldTarget.from,
                            selectedDate: formViewModel.startDate,
                            hasError: false,
                            isOpen: _openField == DateFieldTarget.from,
                            onTap: () {
                              setState(() {
                                _openField = _openField == DateFieldTarget.from ? null : DateFieldTarget.from;
                              });
                              if (_openField != null) _scrollToCalendar();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: "To",
                            style: context.textTheme.l1Medium,
                          ),
                          const SizedBox(height: 8),
                          DateFieldBox(
                            semanticId: 'to',
                            target: DateFieldTarget.to,
                            selectedDate: formViewModel.endDate,
                            hasError: false,
                            isOpen: _openField == DateFieldTarget.to,
                            onTap: () {
                              setState(() {
                                _openField = _openField == DateFieldTarget.to ? null : DateFieldTarget.to;
                              });
                              if (_openField != null) _scrollToCalendar();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child:
                      _openField == DateFieldTarget.from || _openField == DateFieldTarget.to
                          ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildCalendar(
                              selectedDate: _openField == DateFieldTarget.from ? formViewModel.startDate : formViewModel.endDate,
                              minDate: _openField == DateFieldTarget.to ? formViewModel.startDate : null,
                              onPicked: (DateTime date) {
                                if (_openField == DateFieldTarget.from) {
                                  formViewModel.startDate = date;
                                } else {
                                  formViewModel.endDate = date;
                                }
                                setState(() => _openField = null);
                              },
                            ),
                          )
                          : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
