import 'dart:convert';

/// Main configuration class for audio algorithms
class FusionAlgorithmsConfig {
  final String version;
  final List<Algorithm> algorithms;

  FusionAlgorithmsConfig({
    required this.version,
    required this.algorithms,
  });

  factory FusionAlgorithmsConfig.fromJson(Map<String, dynamic> json) {
    return FusionAlgorithmsConfig(
      version: json['version'] as String,
      algorithms: (json['algorithms'] as List<dynamic>)
          .map((dynamic e) => Algorithm.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'algorithms': algorithms.map((Algorithm e) => e.toJson()).toList(),
    };
  }

  factory FusionAlgorithmsConfig.fromJsonString(String jsonString) {
    return FusionAlgorithmsConfig.fromJson(json.decode(jsonString));
  }

  String toJsonString() {
    return json.encode(toJson());
  }
}

/// Represents an audio processing algorithm
class Algorithm {
  final String name;
  final List<Property>? properties;
  final List<Terminal>? terminals;
  final List<Parameter>? parameters;
  final List<Telemetry>? telemetry;

  Algorithm({
    required this.name,
    this.properties,
    this.terminals,
    this.parameters,
    this.telemetry,
  });

  factory Algorithm.fromJson(Map<String, dynamic> json) {
    return Algorithm(
      name: json['name'] as String,
      properties: json['properties'] != null
          ? (json['properties'] as List<dynamic>)
          .map((dynamic e) => Property.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      terminals: json['terminals'] != null
          ? (json['terminals'] as List<dynamic>)
          .map((dynamic e) => Terminal.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      parameters: json['parameters'] != null
          ? (json['parameters'] as List<dynamic>)
          .map((dynamic e) => Parameter.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      telemetry: json['telemetry'] != null
          ? (json['telemetry'] as List<dynamic>)
          .map((dynamic e) => Telemetry.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name,
    };

    if (properties != null) {
      data['properties'] = properties!.map((Property e) => e.toJson()).toList();
    }
    if (terminals != null) {
      data['terminals'] = terminals!.map((Terminal e) => e.toJson()).toList();
    }
    if (parameters != null) {
      data['parameters'] = parameters!.map((Parameter e) => e.toJson()).toList();
    }
    if (telemetry != null) {
      data['telemetry'] = telemetry!.map((Telemetry e) => e.toJson()).toList();
    }

    return data;
  }
}

/// Represents a property of an algorithm
class Property {
  final String name;
  final String valueType;
  final dynamic defaultValue;
  final dynamic minimumValue;
  final dynamic maximumValue;
  final int? maximumLength;
  final List<dynamic>? allowedValues;

  Property({
    required this.name,
    required this.valueType,
    this.defaultValue,
    this.minimumValue,
    this.maximumValue,
    this.maximumLength,
    this.allowedValues,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      name: json['name'] as String,
      valueType: json['value_type'] as String,
      defaultValue: json['default_value'],
      minimumValue: json['minimum_value'],
      maximumValue: json['maximum_value'],
      maximumLength: json['maximum_length'] as int?,
      allowedValues: json['allowed_values'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name,
      'value_type': valueType,
    };

    if (defaultValue != null) data['default_value'] = defaultValue;
    if (minimumValue != null) data['minimum_value'] = minimumValue;
    if (maximumValue != null) data['maximum_value'] = maximumValue;
    if (maximumLength != null) data['maximum_length'] = maximumLength;
    if (allowedValues != null) data['allowed_values'] = allowedValues;

    return data;
  }
}

/// Represents a terminal (input/output) of an algorithm
class Terminal {
  final String name;
  final String signalType;
  final String direction;
  final dynamic channels;
  final int? minimumChannels;
  final int? maximumChannels;
  final String? bypassSource;

  Terminal({
    required this.name,
    required this.signalType,
    required this.direction,
    this.channels,
    this.minimumChannels,
    this.maximumChannels,
    this.bypassSource,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      name: json['name'] as String,
      signalType: json['signal_type'] as String,
      direction: json['direction'] as String,
      channels: json['channels'],
      minimumChannels: json['minimum_channels'] as int?,
      maximumChannels: json['maximum_channels'] as int?,
      bypassSource: json['bypass_source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name,
      'signal_type': signalType,
      'direction': direction,
    };

    if (channels != null) data['channels'] = channels;
    if (minimumChannels != null) data['minimum_channels'] = minimumChannels;
    if (maximumChannels != null) data['maximum_channels'] = maximumChannels;
    if (bypassSource != null) data['bypass_source'] = bypassSource;

    return data;
  }
}

/// Represents a parameter of an algorithm
class Parameter {
  final String name;
  final String valueType;
  final List<dynamic>? dimensions;
  final dynamic defaultValue;
  final dynamic minimumValue;
  final dynamic maximumValue;
  final int? minimumLength;
  final int? maximumLength;
  final List<String>? allowedValues;

  Parameter({
    required this.name,
    required this.valueType,
    this.dimensions,
    this.defaultValue,
    this.minimumValue,
    this.maximumValue,
    this.minimumLength,
    this.maximumLength,
    this.allowedValues,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      name: json['name'] as String,
      valueType: json['value_type'] as String,
      dimensions: json['dimensions'] as List<dynamic>?,
      defaultValue: json['default_value'],
      minimumValue: json['minimum_value'],
      maximumValue: json['maximum_value'],
      minimumLength: json['minimum_length'] as int?,
      maximumLength: json['maximum_length'] as int?,
      allowedValues: json['allowed_values'] != null
          ? (json['allowed_values'] as List<dynamic>).cast<String>()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name,
      'value_type': valueType,
    };

    if (dimensions != null) data['dimensions'] = dimensions;
    if (defaultValue != null) data['default_value'] = defaultValue;
    if (minimumValue != null) data['minimum_value'] = minimumValue;
    if (maximumValue != null) data['maximum_value'] = maximumValue;
    if (minimumLength != null) data['minimum_length'] = minimumLength;
    if (maximumLength != null) data['maximum_length'] = maximumLength;
    if (allowedValues != null) data['allowed_values'] = allowedValues;

    return data;
  }
}

/// Represents telemetry data for an algorithm
class Telemetry {
  final String name;
  final List<dynamic>? dimensions;
  final String valueType;
  final dynamic defaultValue;
  final dynamic minimumValue;
  final dynamic maximumValue;
  final String? telemetryType;
  final String? periodType;

  Telemetry({
    required this.name,
    this.dimensions,
    required this.valueType,
    this.defaultValue,
    this.minimumValue,
    this.maximumValue,
    this.telemetryType,
    this.periodType,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      name: json['name'] as String,
      dimensions: json['dimensions'] as List<dynamic>?,
      valueType: json['value_type'] as String,
      defaultValue: json['default_value'],
      minimumValue: json['minimum_value'],
      maximumValue: json['maximum_value'],
      telemetryType: json['telemetry_type'] as String?,
      periodType: json['period_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name,
      'value_type': valueType,
    };

    if (dimensions != null) data['dimensions'] = dimensions;
    if (defaultValue != null) data['default_value'] = defaultValue;
    if (minimumValue != null) data['minimum_value'] = minimumValue;
    if (maximumValue != null) data['maximum_value'] = maximumValue;
    if (telemetryType != null) data['telemetry_type'] = telemetryType;
    if (periodType != null) data['period_type'] = periodType;

    return data;
  }
}

/// Extension methods for easier access to specific algorithms
extension AudioAlgorithmsConfigExtension on FusionAlgorithmsConfig {
  /// Get algorithm by name
  Algorithm? getAlgorithm(String name) {
    try {
      return algorithms.firstWhere((Algorithm algorithm) => algorithm.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all algorithm names
  List<String> get algorithmNames => algorithms.map((Algorithm e) => e.name).toList();

  /// Check if algorithm exists
  bool hasAlgorithm(String name) => getAlgorithm(name) != null;
}

/// Extension methods for Algorithm class
extension AlgorithmExtension on Algorithm {
  /// Get parameter by name
  Parameter? getParameter(String name) {
    if (parameters == null) return null;
    try {
      return parameters!.firstWhere((Parameter param) => param.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get property by name
  Property? getProperty(String name) {
    if (properties == null) return null;
    try {
      return properties!.firstWhere((Property prop) => prop.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get terminal by name
  Terminal? getTerminal(String name) {
    if (terminals == null) return null;
    try {
      return terminals!.firstWhere((Terminal terminal) => terminal.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get telemetry by name
  Telemetry? getTelemetry(String name) {
    if (telemetry == null) return null;
    try {
      return telemetry!.firstWhere((Telemetry tel) => tel.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all parameter names
  List<String> get parameterNames =>
      parameters?.map((Parameter e) => e.name).toList() ?? <String>[];

  /// Get all terminal names
  List<String> get terminalNames =>
      terminals?.map((Terminal e) => e.name).toList() ?? <String>[];
}