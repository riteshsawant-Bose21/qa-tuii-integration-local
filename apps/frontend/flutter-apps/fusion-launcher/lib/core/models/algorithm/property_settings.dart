class PropertySetting{
  final String name;
  final dynamic value;

  PropertySetting({required this.name, required this.value});

  PropertySetting copyWith({
    String? name,
    dynamic value,
  }) {
    return PropertySetting(
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
    };
  }

  factory PropertySetting.fromJson(Map<String, dynamic> json) {
    return PropertySetting(
      name: json['name'] as String,
      value: json['value'],
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