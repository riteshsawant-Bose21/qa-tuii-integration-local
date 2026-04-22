import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import 'am_pm_toogle.dart';

enum ClockMode { hour, minute }

class TimePicker extends StatefulWidget {
  const TimePicker({
    required this.time,
    this.onChanged,
    this.onFieldFocused,
    this.onReady,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay>? onChanged;
  final ValueChanged<ClockMode>? onFieldFocused;
  final ValueChanged<TimePickerController>? onReady;
  final MainAxisAlignment mainAxisAlignment;

  @override
  State<TimePicker> createState() => TimePickerState();
}

class TimePickerController {
  TimePickerController({required this.focusHour, required this.focusMinute});
  final VoidCallback focusHour;
  final VoidCallback focusMinute;
}

class TimePickerState extends State<TimePicker> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final FocusNode _hourFocus;
  late final FocusNode _minuteFocus;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(
      text: widget.time.hourOfPeriod == 0 ? '12' : widget.time.hourOfPeriod.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: widget.time.minute.toString().padLeft(2, '0'),
    );
    _hourFocus =
        FocusNode()..addListener(() {
          if (_hourFocus.hasFocus) {
            widget.onFieldFocused?.call(ClockMode.hour);
          } else {
            _onHourFocusChange();
          }
          setState(() {});
        });

    _minuteFocus =
        FocusNode()..addListener(() {
          if (_minuteFocus.hasFocus) {
            widget.onFieldFocused?.call(ClockMode.minute);
          } else {
            _onMinuteFocusChange();
          }
          setState(() {});
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady?.call(
        TimePickerController(
          focusHour: () => _hourFocus.requestFocus(),
          focusMinute: () => _minuteFocus.requestFocus(),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant TimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time != widget.time) _syncControllersFromWidget();
  }

  void _syncControllersFromWidget() {
    final String h = widget.time.hourOfPeriod == 0 ? '12' : widget.time.hourOfPeriod.toString().padLeft(2, '0');
    final String m = widget.time.minute.toString().padLeft(2, '0');
    if (_hourController.text != h) _hourController.text = h;
    if (_minuteController.text != m) _minuteController.text = m;
  }

  void _onHourFocusChange() {
    if (!_hourFocus.hasFocus) _commitHour();
  }

  void _onMinuteFocusChange() {
    if (!_minuteFocus.hasFocus) _commitMinute();
  }

  void _commitHour() {
    int h = int.tryParse(_hourController.text) ?? widget.time.hourOfPeriod;
    if (h < 1) h = 1;
    if (h > 12) h = 12;
    final bool isAM = widget.time.period == DayPeriod.am;
    final int hour24 = isAM ? (h == 12 ? 0 : h) : (h == 12 ? 12 : h + 12);
    _hourController.text = h.toString().padLeft(2, '0');
    widget.onChanged?.call(TimeOfDay(hour: hour24, minute: widget.time.minute));
  }

  void _commitMinute() {
    int m = int.tryParse(_minuteController.text) ?? widget.time.minute;
    if (m < 0) m = 0;
    if (m > 59) m = 59;
    _minuteController.text = m.toString().padLeft(2, '0');
    widget.onChanged?.call(TimeOfDay(hour: widget.time.hour, minute: m));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAM = widget.time.period == DayPeriod.am;
    final Color borderColor = context.colorScheme.strokeLight;

    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      children: <Widget>[
        _TimeUnitBox(
          controller: _hourController,
          focusNode: _hourFocus,
          label: "Hour",
          borderColor: borderColor,
          onSubmitted: (_) => _commitHour(),
        ),
        const SizedBox(width: 6),
        FusionAppText(semanticId: 'timing_section_time_separator', text: ":", style: context.textTheme.labelLarge),
        const SizedBox(width: 6),
        _TimeUnitBox(
          controller: _minuteController,
          focusNode: _minuteFocus,
          label: "Minute",
          borderColor: borderColor,
          onSubmitted: (_) => _commitMinute(),
        ),
        const SizedBox(width: 10),
        AmPmToggle(
          isAM: isAM,
          borderColor: borderColor,
          onChanged: (bool selectAM) {
            final TimeOfDay newTime = TimeOfDay(
              hour: selectAM ? (isAM ? widget.time.hour : (widget.time.hour - 12) % 24) : (isAM ? (widget.time.hour + 12) % 24 : widget.time.hour),
              minute: widget.time.minute,
            );
            widget.onChanged?.call(newTime);
          },
        ),
      ],
    );
  }
}

class _TimeUnitBox extends StatefulWidget {
  const _TimeUnitBox({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.borderColor,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Color borderColor;
  final ValueChanged<String> onSubmitted;

  @override
  State<_TimeUnitBox> createState() => _TimeUnitBoxState();
}

class _TimeUnitBoxState extends State<_TimeUnitBox> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool hasFocus = widget.focusNode.hasFocus;

    return Column(
      children: <Widget>[
        MouseRegion(
          cursor: SystemMouseCursors.text,
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.borderColor,
                width: (hasFocus || _isHovering) ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: (hasFocus || _isHovering) ? context.colorScheme.elevation2 : Colors.transparent,
            ),
            child: TextField(
              cursorColor: context.colorScheme.elevation6,
              controller: widget.controller,
              focusNode: widget.focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 2,
              style: context.textTheme.h6Regular,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: widget.onSubmitted,
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                fillColor: Colors.transparent,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FusionAppText(
          semanticId: 'timing_section_hour_minute_label',
          text: widget.label,
          style: context.textTheme.l2Regular.copyWith(
            color: context.colorScheme.textBody,
          ),
        ),
      ],
    );
  }
}
