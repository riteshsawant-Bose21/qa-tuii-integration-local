import 'dart:ui';

class WiringSerializationUtil {
  static final Deserializer<int> intDeserializer = Deserializer<int>(
    fromInt: (int value) => value,
    fromString: (String value) => int.tryParse(value),
    fromDouble: (double value) => value.toInt(),
    fromNum: (num value) => value.toInt(),
    fromBool: (bool value) => value ? 1 : 0,
  );

  static final Deserializer<double> doubleDeserializer = Deserializer<double>(
    fromDouble: (double value) => value,
    fromInt: (int value) => value.toDouble(),
    fromNum: (num value) => value.toDouble(),
    fromString: (String value) => double.tryParse(value),
    fromBool: (bool value) => value ? 1.0 : 0.0,
  );

  static final Deserializer<num> numDeserializer = Deserializer<num>(
    fromNum: (num value) => value,
    fromInt: (int value) => value,
    fromDouble: (double value) => value,
    fromString: (String value) => num.tryParse(value),
    fromBool: (bool value) => value ? 1 : 0,
  );

  static final Deserializer<bool> boolDeserializer = Deserializer<bool>(
    fromBool: (bool value) => value,
    fromInt: (int value) => value != 0,
    fromDouble: (double value) => value != 0.0,
    fromNum: (num value) => value != 0,
    fromString: (String value) {
      final String lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      return null;
    },
  );

  static final Deserializer<String> stringDeserializer = Deserializer<String>(
    fromString: (String value) => value,
    fromInt: (int value) => value.toString(),
    fromDouble: (double value) => value.toString(),
    fromNum: (num value) => value.toString(),
    fromBool: (bool value) => value.toString(),
    fromMap: (Map<dynamic, dynamic> value) => value.toString(),
  );

  static final Deserializer<Map<dynamic, dynamic>> mapDeserializer =
      Deserializer<Map<dynamic, dynamic>>(
        fromMap: (Map<dynamic, dynamic> map) => map,
      );

  static final Deserializer<List<dynamic>> listDeserializer =
      Deserializer<List<dynamic>>(
        fromString: (String value) {
          // comma separated
          return value.split(',').map((String e) => e.trim()).toList();
        },
      );

  static final Deserializer<Offset> offsetDeserializer = Deserializer<Offset>(
    fromMap: (Map<dynamic, dynamic> map) {
      final double? x = doubleDeserializer.deserialize(map['x']);
      final double? y = doubleDeserializer.deserialize(map['y']);
      if (x is double && y is double) {
        return Offset(x.toDouble(), y.toDouble());
      }
      return null;
    },
    fromString: (String value) {
      // Support string like "10,20"
      final List<String> parts = value.split(',');
      if (parts.length == 2) {
        final double? dx = doubleDeserializer.deserialize(parts[0].trim());
        final double? dy = doubleDeserializer.deserialize(parts[1].trim());
        if (dx != null && dy != null) {
          return Offset(dx, dy);
        }
      }
      return null;
    },
  );
}

class Deserializer<T> {
  final T? Function(Map<dynamic, dynamic> map)? fromMap;
  final T? Function(int value)? fromInt;
  final T? Function(String value)? fromString;
  final T? Function(double value)? fromDouble;
  final T? Function(num value)? fromNum;
  final T? Function(bool value)? fromBool;

  Deserializer({
    this.fromMap,
    this.fromInt,
    this.fromString,
    this.fromDouble,
    this.fromNum,
    this.fromBool,
  });

  T? deserialize(dynamic value) {
    if (value == null) return null;

    if (value is T) return value;

    if (value is Map && fromMap != null) return fromMap!(value);
    if (value is int && fromInt != null) return fromInt!(value);
    if (value is String && fromString != null) return fromString!(value);
    if (value is double && fromDouble != null) return fromDouble!(value);
    if (value is num && fromNum != null) return fromNum!(value);
    if (value is bool && fromBool != null) return fromBool!(value);

    return null;
  }
}
