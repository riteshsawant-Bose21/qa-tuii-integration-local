class GainConfig {
  final bool exists;
  final GainValue value;

  GainConfig({
    required this.exists,
    required this.value,
  });

  factory GainConfig.fromJson(Map<String, dynamic> json) {
    return GainConfig(
      exists: json['exists'] ?? false,
      value: GainValue.fromJson(json['value'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'value': value.toJson(),
    };
  }
}
class GainValue {
  final int gain;
  final bool mute;

  GainValue({
    required this.gain,
    required this.mute,
  });

  factory GainValue.fromJson(Map<String, dynamic> json) {
    return GainValue(
      gain: json['gain'] ?? 0,
      mute: json['mute'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gain': gain,
      'mute': mute,
    };
  }
}
