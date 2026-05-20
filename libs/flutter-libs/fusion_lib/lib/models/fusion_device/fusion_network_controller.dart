/// Model class representing a wall-controller discovered on the Fusion network.
///
/// Returned by `GET /controllers`. Example payload:
/// ```json
/// {
///   "id": "ctrl1",
///   "name": "WallController",
///   "address": "192.168.1.89:52436",
///   "version": "1.0.0"
/// }
/// ```
class FusionNetworkController {
  final String id;
  final String name;
  final String address;
  final String version;

  const FusionNetworkController({
    required this.id,
    required this.name,
    required this.address,
    this.version = '',
  });

  factory FusionNetworkController.fromJson(Map<String, dynamic> json) {
    return FusionNetworkController(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      version: json['version'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'version': version,
    };
  }

  FusionNetworkController copyWith({
    String? id,
    String? name,
    String? address,
    String? version,
  }) {
    return FusionNetworkController(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      version: version ?? this.version,
    );
  }

  @override
  String toString() => 'FusionNetworkController(id: $id, name: $name, address: $address, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FusionNetworkController && other.id == id && other.name == name && other.address == address && other.version == version;
  }

  @override
  int get hashCode => Object.hash(id, name, address, version);
}
