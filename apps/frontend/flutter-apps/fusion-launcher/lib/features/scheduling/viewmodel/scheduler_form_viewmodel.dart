import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'scheduler_viewmodel.dart';

class SchedulerFormViewModel extends ChangeNotifier {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();

  final SchedulerViewmodel viewModel;
  final ScheduleConfig? initial;
  SchedulerFormViewModel({required this.viewModel, required this.initial}) {
    if (initial != null) {
      name.text = initial!.name;
      color = initial!.colorHex;
      startDate = initial!.startDate;
      endDate = initial!.endDate;
      startTime = TimeOfDay(hour: initial!.time.hour, minute: initial!.time.minute);
      endTime = TimeOfDay(hour: initial!.time.hour + 1, minute: initial!.time.minute);
      recurrenceType = initial!.recurrence;
      for (final int day in initial!.weeklyDays) {
        recurrenceDays.add(RecurrenceDay.values.firstWhere((RecurrenceDay element) => element.value == day));
      }
    }
    name.addListener(() {
      notifyListeners();
    });
  }

  String? _color;

  String? get color => _color;

  set color(String? value) {
    _color = value;
    notifyListeners();
  }

  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  set startDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  set endDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay get startTime => _startTime;
  set startTime(TimeOfDay value) {
    _startTime = value;
    notifyListeners();
  }

  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  TimeOfDay get endTime => _endTime;
  set endTime(TimeOfDay value) {
    _endTime = value;

    notifyListeners();
  }

  RecurrenceType _recurrenceType = RecurrenceType.none;
  RecurrenceType get recurrenceType => _recurrenceType;
  set recurrenceType(RecurrenceType value) {
    _recurrenceType = value;
    notifyListeners();
  }

  final List<RecurrenceDay> _recurrenceDays = <RecurrenceDay>[];

  List<RecurrenceDay> get recurrenceDays => _recurrenceDays;
  void addRecurrenceDay(RecurrenceDay day) {
    if (!_recurrenceDays.contains(day)) {
      _recurrenceDays.add(day);
      notifyListeners();
    }
  }

  void removeRecurrenceDay(RecurrenceDay day) {
    if (_recurrenceDays.contains(day)) {
      _recurrenceDays.remove(day);
      notifyListeners();
    }
  }

  Future<bool> submit(ScheduleConfig? initial) async {
    if (!key.currentState!.validate()) {
      return false;
    }

    if (initial != null) {
      viewModel.updateSchedule(
        initial.copyWith(
          name: name.text,
          colorHex: color!,
          startDate: startDate!,
          time: DateTime(
            startDate!.year,
            startDate!.month,
            startDate!.day,
            startTime.hour,
            startTime.minute,
          ),
          endDate: endDate!,
          recurrence: recurrenceType,
          weeklyDays: recurrenceDays.map((RecurrenceDay e) => e.value).toList(),
        ),
      );
      return true;
    }
    viewModel.addSchedule(
      ScheduleConfig(
        id: "SCHEDULE_${FusionUtils.shortUUID()}",
        name: name.text,
        colorHex: color!,
        startDate: startDate!,
        time: DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
          startTime.hour,
          startTime.minute,
        ),
        endDate: endDate!,
        recurrence: recurrenceType,
        weeklyDays: recurrenceDays.map((RecurrenceDay e) => e.value).toList(),
      ),
    );
    return true;
  }

  bool get canEnableSubmit {
    return name.text.isNotEmpty && color != null && startDate != null && endDate != null;
  }
}
