import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Amplifier {
  final String id;
  final String name;
  final int channels;
  final double powerPerChannel;
  final MaterialColor color;
  final String assetPath;
  final double price;

  Amplifier({
    String? id,
    required this.name,
    required this.channels,
    required this.powerPerChannel,
    required this.color,
    this.assetPath = 'assets/images/amplifier.png',
    this.price = 1000.0,
  }) : id = id ?? const Uuid().v4();

  double get totalPower => channels * powerPerChannel;

  //copyWith
  Amplifier copyWith({
    String? name,
    int? channels,
    double? powerPerChannel,
    MaterialColor? color,
    String? assetPath,
    double? price,
  }) {
    return Amplifier(
      name: name ?? this.name,
      channels: channels ?? this.channels,
      powerPerChannel: powerPerChannel ?? this.powerPerChannel,
      color: color ?? this.color,
      assetPath: assetPath ?? this.assetPath,
      price: price ?? this.price,
    );
  }

  factory Amplifier.fromJson(Map<String, dynamic> json) {
    return Amplifier(
      name: json['name'] as String,
      channels: json['channels'] as int,
      powerPerChannel: (json['powerPerChannel'] as num).toDouble(),
      color: _materialColorFromHex(json['color'] as String),
      assetPath: json['assetPath'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'channels': channels,
      'powerPerChannel': powerPerChannel,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
      'assetPath': assetPath,
      'price': price,
    };
  }

  /// Helper to convert hex string to MaterialColor
  static MaterialColor _materialColorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // add full opacity if alpha missing
    }
    final int colorInt = int.parse(hex, radix: 16);
    final Color baseColor = Color(colorInt);

    // Generate MaterialColor from single Color
    return MaterialColor(baseColor.value, <int, Color>{
      50: baseColor.withOpacity(.1),
      100: baseColor.withOpacity(.2),
      200: baseColor.withOpacity(.3),
      300: baseColor.withOpacity(.4),
      400: baseColor.withOpacity(.5),
      500: baseColor.withOpacity(.6),
      600: baseColor.withOpacity(.7),
      700: baseColor.withOpacity(.8),
      800: baseColor.withOpacity(.9),
      900: baseColor.withOpacity(1),
    });
  }
}
