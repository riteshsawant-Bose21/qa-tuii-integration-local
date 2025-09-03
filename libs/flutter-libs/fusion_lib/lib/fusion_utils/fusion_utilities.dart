import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class FusionUtils {
  //singleton
  FusionUtils._internal();
  static final FusionUtils _instance = FusionUtils._internal();
  factory FusionUtils() => _instance;

  //generate  uuid
  static String generateUUID() {
    return const Uuid().v4();
  }

  //generate a short uuid
  static int shortUUID() {
    return int.parse(shortStringUUID());
  }

  //short String UUID
  static String shortStringUUID() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(999999);
    return '$timestamp$random';
  }

  //generate two random colors from Colors.primaries
  static List<Color> randomColors() => <Color>[
    Colors.primaries[Random().nextInt(Colors.primaries.length)],
    Colors.primaries[Random().nextInt(Colors.primaries.length)],
  ];
}
