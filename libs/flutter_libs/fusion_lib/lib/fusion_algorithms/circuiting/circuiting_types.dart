/// Circuiting algorithm types

class InputSpeaker {
  final String model;
  final int quantity;
  final String tapSetting; // e.g. "lo-z" or "hi-z"
  final String area;

  const InputSpeaker({
    required this.model,
    required this.quantity,
    required this.tapSetting,
    required this.area,
  });

  Map<String, dynamic> toJson() => {
        'Model': model,
        'Quantity': quantity,
        'TapSetting': tapSetting,
        'Area': area,
      };

  factory InputSpeaker.fromJson(Map<String, dynamic> json) => InputSpeaker(
        model: json['Model'],
        quantity: json['Quantity'],
        tapSetting: json['TapSetting'],
        area: json['Area'],
      );
}

class CircuitAssignment {
  final String area;
  final int circuitId;
  final String model;
  final String mode; // "lo-z" or "hi-z"
  final double? tapWatts;
  final double? totalPower;
  final double? impedance;

  const CircuitAssignment({
    required this.area,
    required this.circuitId,
    required this.model,
    required this.mode,
    this.tapWatts,
    this.totalPower,
    this.impedance,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'Area': area,
      'CircuitID': circuitId,
      'Model': model,
      'Mode': mode,
    };
    
    if (tapWatts != null) json['TapWatts'] = tapWatts;
    if (totalPower != null) json['TotalPower'] = totalPower;
    if (impedance != null) json['Impedance'] = impedance;
    
    return json;
  }

  factory CircuitAssignment.fromJson(Map<String, dynamic> json) => CircuitAssignment(
        area: json['Area'],
        circuitId: json['CircuitID'],
        model: json['Model'],
        mode: json['Mode'],
        tapWatts: json['TapWatts']?.toDouble(),
        totalPower: json['TotalPower']?.toDouble(),
        impedance: json['Impedance']?.toDouble(),
      );
}
