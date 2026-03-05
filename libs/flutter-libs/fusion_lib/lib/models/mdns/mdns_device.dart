// device_model.dart
class MdnsDevice {
  final String name;
  final String ip;
  final int port;
  final Map<String, String> attributes;

  MdnsDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.attributes = const {},
  });

  @override
  String toString() => 'Device: $name ($ip:$port)';
}
