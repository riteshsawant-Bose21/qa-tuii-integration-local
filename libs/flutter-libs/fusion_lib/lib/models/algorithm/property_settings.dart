class PropertySetting {
  final String name;
  final dynamic value;
  final int? dimension;

  PropertySetting({required this.name, required this.value, this.dimension});

  PropertySetting copyWith({
    String? name,
    dynamic value,
    int? dimension,
  }) {
    return PropertySetting(
      name: name ?? this.name,
      value: value ?? this.value,
      dimension: dimension ?? this.dimension,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
      'dimension': dimension,
    };
  }

  factory PropertySetting.fromJson(Map<String, dynamic> json) {
    return PropertySetting(
      name: json['name'] as String,
      value: json['value'],
      dimension: json['dimension'] as int?,
    );
  }

  String get valueType {
    if (value is int) {
      return 'int';
    } else if (value is double) {
      return 'double';
    } else if (value is String) {
      return 'string';
    } else if (value is bool) {
      return 'bool';
    } else if (value is List) {
      return 'list';
    } else if (value is Map) {
      return 'map';
    } else {
      return 'unknown';
    }
  }
}
