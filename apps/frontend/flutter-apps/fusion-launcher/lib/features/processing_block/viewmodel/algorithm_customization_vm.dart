import 'package:flutter/widgets.dart';

import '../../../core/models/algorithm/algorithm_metadata.dart';

class AlgorithmCustomizationVm extends ChangeNotifier {
  final FusionAlgorithmsConfig config;

  AlgorithmCustomizationVm({required this.config}) {
    selectedAlgorithm = availableAlgorithms.isNotEmpty ? availableAlgorithms.first : null;
  }

  final List<String> _allowedAlgorithms = <String>[
    "delay",
    "compressor",
    "limiter",
    "agc",
    "feedback_suppression",
    "graphic_eq",
    "tone_control",
    "peq",
    "gain",
    "gate",
  ];

  List<Algorithm> get availableAlgorithms => config.algorithms.where((Algorithm e) => _allowedAlgorithms.contains(e.name)).toList();

  Algorithm? selectedAlgorithm;

  void selectAlgorithm(Algorithm algorithm) {
    selectedAlgorithm = algorithm;
    notifyListeners();
  }
}
