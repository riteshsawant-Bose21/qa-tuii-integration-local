class InputConfig {
  final bool exists;
  final InputValue value;

  InputConfig({
    required this.exists,
    required this.value,
  });

  factory InputConfig.fromJson(Map<String, dynamic> json,String funcID) {
    return InputConfig(
      exists: json['exists'] ?? false,
      value: InputValue.fromJson(json['value'][funcID] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'value': value.toJson(),
    };
  }
}

class InputValue {
  final int input;

  InputValue({
    required this.input,
  });

  factory InputValue.fromJson(Map<String, dynamic> json) {
    return InputValue(
      input: json['input'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
    };
  }
}