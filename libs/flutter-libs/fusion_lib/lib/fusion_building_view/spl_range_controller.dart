import 'package:flutter/foundation.dart';

/// Controller for managing bidirectional communication between SPL Panel and SPL Range Slider
class SplRangeController extends ChangeNotifier {
  double _upperLimit = 90.0;
  double _lowerLimit = 45.0;

  /// Current upper limit value
  double get upperLimit => _upperLimit;

  /// Current lower limit value
  double get lowerLimit => _lowerLimit;

  /// Update upper limit (typically called by slider or panel)
  void setUpperLimit(double value) {
    if (_upperLimit != value && value >= _lowerLimit) {
      _upperLimit = value;
      notifyListeners();
    }
  }

  /// Update lower limit (typically called by slider or panel)
  void setLowerLimit(double value) {
    if (_lowerLimit != value && value <= _upperLimit) {
      _lowerLimit = value;
      notifyListeners();
    }
  }

  /// Update both limits simultaneously (typically called by slider)
  void setRange(double lower, double upper) {
    if (_lowerLimit != lower || _upperLimit != upper) {
      _lowerLimit = lower;
      _upperLimit = upper;
      notifyListeners();
    }
  }

  /// Reset to default values
  void reset({double? defaultUpper, double? defaultLower}) {
    setRange(
      defaultLower ?? 45.0,
      defaultUpper ?? 90.0,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
