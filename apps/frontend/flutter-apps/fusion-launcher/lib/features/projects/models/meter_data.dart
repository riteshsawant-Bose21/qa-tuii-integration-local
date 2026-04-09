import 'dart:convert';
import 'dart:ui';

class MeterBlock {
  final String blockName;
  final String meterName;
  final String valueType;
  final List<int> dimensions;
  final List<double> value;

  const MeterBlock({
    required this.blockName,
    required this.meterName,
    required this.valueType,
    required this.dimensions,
    required this.value,
  });

  static List<double> _parseDynamicList(dynamic value) {
    if (value == null) return <double>[];
    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        try {
          final dynamic parsed = jsonDecode(value);
          if (parsed is List) return _parseDynamicList(parsed);
        } catch (_) {}
      }
      final double? n = double.tryParse(value);
      if (n != null) return <double>[n];
      return <double>[];
    }
    if (value is List) {
      return value.map((dynamic e) {
        if (e is num) return e.toDouble();
        if (e is bool) return e ? 1.0 : 0.0;
        if (e is String) return double.tryParse(e) ?? 0.0;
        return 0.0;
      }).toList();
    } else if (value is num) {
      return <double>[value.toDouble()];
    } else if (value is bool) {
      return <double>[value ? 1.0 : 0.0];
    }
    return <double>[];
  }

  static List<int> _parseDimensions(dynamic value) {
    if (value == null) return <int>[];
    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        try {
          final dynamic parsed = jsonDecode(value);
          if (parsed is List) return _parseDimensions(parsed);
        } catch (_) {}
      }
      final int? n = int.tryParse(value);
      if (n != null) return <int>[n];
      return <int>[];
    }
    if (value is List) {
      return value.map((dynamic e) {
        if (e is num) return e.toInt();
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    } else if (value is num) {
      return <int>[value.toInt()];
    }
    return <int>[];
  }

  factory MeterBlock.fromMap(Map<String, dynamic> map) {
    return MeterBlock(
      blockName: map['block_name']?.toString() ?? '',
      meterName: map['meter_name']?.toString() ?? '',
      valueType: map['value_type']?.toString() ?? '',
      dimensions: _parseDimensions(map['dimensions']),
      value: _parseDynamicList(map['value']),
    );
  }

  String get displayName {
    final RegExpMatch? match = RegExp(r'^([A-Za-z_]+)').firstMatch(blockName);
    return match?.group(1) ?? blockName;
  }

  String get valueLabel {
    if (value.length == 1) return '${value[0].toStringAsFixed(1)} dB';
    return '${value.map((double v) => v.toStringAsFixed(1)).join(' / ')} dB';
  }

  Color get levelColor {
    final double peak = value.reduce((double a, double b) => a > b ? a : b);
    if (peak <= -100) return const Color(0xFF4A5568);
    if (peak <= -60) return const Color(0xFF48BB78);
    if (peak <= -20) return const Color(0xFFECC94B);
    return const Color(0xFFFC8181);
  }
}

class MeterPacket {
  final String name;
  final String messageName;
  final String deviceId;
  final String packetId;
  final String type;
  final int length;
  final List<MeterBlock> blocks;

  const MeterPacket({
    required this.name,
    required this.type,
    required this.length,
    required this.blocks,
    required this.messageName,
    required this.deviceId,
    required this.packetId,
  });

  factory MeterPacket.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? params = map['parameters'] as Map<String, dynamic>?;
    if (params == null) {
      return const MeterPacket(name: '', type: '', length: 0, blocks: <MeterBlock>[], messageName: '', deviceId: '', packetId: '');
    }
    return MeterPacket(
      name: params['name']?.toString() ?? '',
      type: params['type']?.toString() ?? '',
      length: (params['length'] is num) ? (params['length'] as num).toInt() : int.tryParse(params['length']?.toString() ?? '') ?? 0,
      blocks: _parseBlocks(params['value']),
      messageName: map['message_name']?.toString() ?? '',
      deviceId: map['device_id']?.toString() ?? '',
      packetId: map['packet_id']?.toString() ?? '',
    );
  }

  static List<MeterBlock> _parseBlocks(dynamic value) {
    if (value == null) return <MeterBlock>[];
    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        try {
          final dynamic parsed = jsonDecode(value);
          if (parsed is List) return _parseBlocks(parsed);
        } catch (_) {}
      }
      return <MeterBlock>[];
    }
    if (value is List) {
      return value
          .map((dynamic e) {
            if (e is Map<String, dynamic>) return MeterBlock.fromMap(e);
            if (e is String) {
              try {
                final dynamic m = jsonDecode(e);
                if (m is Map<String, dynamic>) return MeterBlock.fromMap(m);
              } catch (_) {}
            }
            return null;
          })
          .whereType<MeterBlock>()
          .toList();
    }
    return <MeterBlock>[];
  }

  //to json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'type': type,
      'length': length,
      'message_name': messageName,
      'device_id': deviceId,
      'packet_id': packetId,
      'blocks':
          blocks
              .map(
                (MeterBlock e) => <String, Object>{
                  'block_name': e.blockName,
                  'meter_name': e.meterName,
                  'value_type': e.valueType,
                  'dimensions': e.dimensions,
                  'value': e.value,
                },
              )
              .toList(),
    };
  }
}
