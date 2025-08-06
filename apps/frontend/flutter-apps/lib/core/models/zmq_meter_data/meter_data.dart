enum MessageName {
  meterData('meter_data'),
  alarms('events');

  const MessageName(this.value);
  final String value;

  static MessageName fromString(String value) {
    switch (value) {
      case 'meter_data':
        return MessageName.meterData;
      case 'events':
        return MessageName.alarms;
      default:
        throw ArgumentError('Unknown MessageName: $value');
    }
  }
}

enum MeterFrequencyRate {
  hi('HI'),
  med('MED'),
  low('LOW');

  const MeterFrequencyRate(this.value);
  final String value;

  static MeterFrequencyRate fromString(String value) {
    switch (value) {
      case 'HI':
        return MeterFrequencyRate.hi;
      case 'MED':
        return MeterFrequencyRate.med;
      case 'LOW':
        return MeterFrequencyRate.low;
      default:
        throw ArgumentError('Unknown MeterFrequencyRate: $value');
    }
  }
}

class MeterDataModel {
  final MessageName messageName;
  final int packetId;
  final Parameters parameters;

  MeterDataModel({
    required this.messageName,
    required this.packetId,
    required this.parameters,
  });

  factory MeterDataModel.fromJson(Map<String, dynamic> json) {
    return MeterDataModel(
      messageName: MessageName.fromString(json['message_name']),
      packetId: json['packet_id'],
      parameters: Parameters.fromJson(json['parameters']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message_name': messageName.value,
      'packet_id': packetId,
      'parameters': parameters.toJson(),
    };
  }
}

class Parameters {
  final String name;
  final MeterFrequencyRate type;
  final int length;
  final List<ValueItem> value;

  Parameters({
    required this.name,
    required this.type,
    required this.length,
    required this.value,
  });

  factory Parameters.fromJson(Map<String, dynamic> json) {
    return Parameters(
      name: json['name'],
      type: MeterFrequencyRate.fromString(json['type']),
      length: json['length'],
      value: (json['value'] as List<dynamic>)
          .map((dynamic item) => ValueItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.value,
      'length': length,
      'value': value.map((ValueItem item) => item.toJson()).toList(),
    };
  }
}

class ValueItem {
  final String blockName;
  final String meterName;
  final String valueType;
  final dynamic dimensions;
  final dynamic value;

  ValueItem({
    required this.blockName,
    required this.meterName,
    required this.valueType,
    required this.dimensions,
    required this.value,
  });

  factory ValueItem.fromJson(Map<String, dynamic> json) {
    return ValueItem(
      blockName: json['block_name'],
      meterName: json['meter_name'],
      valueType: json['value_type'],
      dimensions: json['dimensions'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'block_name': blockName,
      'meter_name': meterName,
      'value_type': valueType,
      'dimensions': dimensions,
      'value': value,
    };
  }
}