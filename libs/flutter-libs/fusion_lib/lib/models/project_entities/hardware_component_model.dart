import 'dart:math';
import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:uuid/uuid.dart';

import 'location_model.dart';

/// Base class for any hardware component
abstract class HardwareComponent {
  final String id;
  final String name;
  Offset pos;
  final String assetImagePath;
  final LocationModel locationEntity;
  final double price;
  final String hardwareName;

  /// Todo: add zAxis to x and y position (create a 3D position class)
  double zAxis;

  static final Uuid _uuid = const Uuid();

  HardwareComponent({
    String? id,
    required this.name,
    Offset? pos,
    double? zAxis,
    required this.assetImagePath,
    required this.locationEntity,
    required this.price,
    required this.hardwareName,
  }) : id = id ?? getShortId(),
       zAxis = zAxis ?? 0.0,
       pos = pos ?? const Offset(0, 0);

  //generate a short unique ID with timestamp
  static String getShortId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HardwareComponent) return false;
    return id == other.id && name == other.name && pos == other.pos && assetImagePath == other.assetImagePath && locationEntity == other.locationEntity;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ pos.hashCode ^ assetImagePath.hashCode ^ locationEntity.hashCode;
  }

  HardwareComponent copyWith({
    String? id,
    String? name,
    Offset? pos,
    double? zAxis,
    String? assetImagePath,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
  });
}

extension TotalPrice on List<HardwareComponent> {
  double get totalPrice {
    return fold(0.0, (double previousValue, HardwareComponent element) => previousValue + element.price);
  }
}
