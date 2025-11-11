import 'package:flutter/widgets.dart';

import '../../../core/models/algorithm/algorithm_metadata.dart';

class AlgorithmCustomizationVm extends ChangeNotifier {
  final FusionAlgorithmsConfig config;

  AlgorithmCustomizationVm({required this.config});

  List<Algorithm> get availableAlgorithms => config.algorithms;

  Algorithm? selectedAlgorithm;

  void selectAlgorithm(Algorithm algorithm) {
    selectedAlgorithm = algorithm;
    notifyListeners();
  }
}
