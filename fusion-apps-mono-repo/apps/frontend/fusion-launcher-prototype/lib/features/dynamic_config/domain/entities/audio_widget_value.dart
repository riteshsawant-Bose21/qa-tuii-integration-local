class AudioWidgetValue {
  /// This holds an int, double, bool, or String.
  final dynamic value;

  /// Should be 'integer', 'float', 'bool', or 'string'.
  final String valueType;

  static const String integerValue = "integer";
  static const String floatValue = "float";
  static const String boolValue = "bool";
  static const String stringValue = "string";

  AudioWidgetValue._(this.value, this.valueType);

  factory AudioWidgetValue.from(dynamic newValue, String valueType) {
    switch (valueType.toLowerCase()) {
      case integerValue:
        return AudioWidgetValue._(
          newValue is int ? newValue : newValue.toInt(),
          integerValue,
        );
      case floatValue:
        return AudioWidgetValue._(
          newValue is double ? newValue : newValue.toDouble(),
          floatValue,
        );
      case boolValue:
        if (newValue is bool) {
          return AudioWidgetValue._(newValue, boolValue);
        } else if (newValue is String) {
          return AudioWidgetValue._(newValue.toLowerCase() == 'true', boolValue);
        } else if (newValue is num) {
          return AudioWidgetValue._(newValue != 0, boolValue);
        } else {
          return AudioWidgetValue._(false, boolValue);
        }
      case stringValue:
        return AudioWidgetValue._(
          newValue is String ? newValue : newValue.toString(),
          stringValue,
        );
      default:
        throw ArgumentError('Unsupported type: $valueType');
    }
  }

  @override
  String toString() => 'AudioWidgetValue($value, type: $valueType)';
}
