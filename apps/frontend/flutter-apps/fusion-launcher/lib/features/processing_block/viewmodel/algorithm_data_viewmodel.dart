import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/features/processing_block/data/algorithm_layout_data.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';

class AlgorithmDataViewmodel extends ChangeNotifier {
  final String algorithmId;
  final FusionAlgorithmsConfig config;

  AlgorithmDataViewmodel({required this.algorithmId, required this.config}) {
    algorithm = config.algorithms.firstWhereOrNull((Algorithm element) => element.name == algorithmId);
    layout = AlgorithmLayoutData.getForAlgorithm(algorithmId);
  }

  Algorithm? algorithm;
  PBLayout? layout;
}
