part of '../product_port_data.dart';

class PortInfo {
  final int port;
  final String label;
  PortInfo({
    required this.port,
    required this.label,
  });

  PortInfo copyWith({
    int? port,
    String? label,
  }) {
    return PortInfo(
      port: port ?? this.port,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'port': port,
      'label': label,
    };
  }

  factory PortInfo.fromMap(Map<String, dynamic> map) {
    return PortInfo(
      port: DeserializationUtil.intDeserializer.deserialize(map['port']) ?? 0,
      label: DeserializationUtil.stringDeserializer.deserialize(map['label']) ?? '',
    );
  }

  static List<PortInfo> fromList(dynamic raw) {
    var list = DeserializationUtil.listDeserializer.deserialize(raw);
    final portInfoList = <PortInfo>[];
    if (list != null) {
      for (var item in list) {
        final deserialized = DeserializationUtil.classDeserializer(PortInfo.fromMap).deserialize(item);
        if (deserialized != null) {
          portInfoList.add(deserialized);
        }
      }
    }
    return portInfoList;
  }

  @override
  String toString() => 'PortInfo(port: $port, label: $label)';

  @override
  bool operator ==(covariant PortInfo other) {
    if (identical(this, other)) return true;

    return other.port == port && other.label == label;
  }

  @override
  int get hashCode => port.hashCode ^ label.hashCode;
}
