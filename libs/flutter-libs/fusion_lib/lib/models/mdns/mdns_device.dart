// device_model.dart
class MdnsDevice {
  final String name; // display label from mDNS instance name
  final String hostname; // SRV target
  final String ip; // A record
  final int port;
  final String stableId; // TXT id if available, else hostname
  final Map<String, String> attributes;
  final DateTime lastSeen;

  MdnsDevice({
    required this.name,
    required this.hostname,
    required this.ip,
    required this.port,
    required this.stableId,
    required this.lastSeen,
    this.attributes = const {},
  });

  MdnsDevice copyWith({
    String? name,
    String? hostname,
    String? ip,
    int? port,
    String? stableId,
    Map<String, String>? attributes,
    DateTime? lastSeen,
  }) {
    return MdnsDevice(
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      stableId: stableId ?? this.stableId,
      attributes: attributes ?? this.attributes,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  String toString() => '$name ($ip:$port)';
}
