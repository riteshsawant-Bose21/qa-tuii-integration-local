import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_building_view/spl_panel.dart';

/// Controller for managing bidirectional communication between SPL Panel and SPL Range Slider
class SplRangeController extends ChangeNotifier {
  SplPanelData _panelData = const SplPanelData();

  /// Current upper limit value
  double get upperLimit => _panelData.splUpperDb;

  /// Current lower limit value
  double get lowerLimit => _panelData.splLowerDb;

  /// Update both limits simultaneously (typically called by slider)
  void setRange(double lower, double upper) {
    if (upperLimit != lower || lowerLimit != upper) {
      _panelData = _panelData.copyWith(
        splLowerDb: lower,
        splUpperDb: upper,
      );
      notifyListeners();
    }
  }

  /// onChanged callback for RangeSlider
  void onMappingDataChanged(SplPanelData panelData) {
    _panelData = panelData;
    notifyListeners();
  }

  SplPanelData getPanelData() => _panelData;
}
