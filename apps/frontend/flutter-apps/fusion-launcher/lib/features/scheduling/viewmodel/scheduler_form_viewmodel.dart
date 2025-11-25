import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/model/schedule_model.dart';

class SchedulerFormViewModel extends ChangeNotifier {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
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

  TimeOfDay? _startTime;
  TimeOfDay? get startTime => _startTime;
  set startTime(TimeOfDay? value) {
    _startTime = value;
    notifyListeners();
  }

  TimeOfDay? _endTime;
  TimeOfDay? get endTime => _endTime;
  set endTime(TimeOfDay? value) {
    _endTime = value;

    notifyListeners();
  }

  RecurrenceType _recurrenceType = RecurrenceType.none;
  RecurrenceType get recurrenceType => _recurrenceType;
  set recurrenceType(RecurrenceType value) {
    _recurrenceType = value;
    notifyListeners();
  }

  Future<void> submit() async {
    if (!key.currentState!.validate()) {
      return;
    }

    // Further submission logic goes here
  }
}
