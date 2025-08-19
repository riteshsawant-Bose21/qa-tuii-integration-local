import 'package:uuid/uuid.dart';

enum FusionDeviceSetupStatus {
  completed,
  notStarted,
}

class FusionDevice {
  final String id;
  final String name;
  final String location;
  final String? localIp;
  final String? cloudId;
  final bool isClaimed;
  final FusionDeviceSetupStatus status;
  final double price;

  FusionDevice({
    String? id,
    required this.name,
    required this.location,
    required this.status,
    this.localIp,
    this.price = 1000,
    this.cloudId,
    this.isClaimed = false,
  }) : id = id ?? const Uuid().v4();

  @override
  String toString() {
    return 'FusionDevice{id: $id, name: $name, location: $location, status: $status, address: $localIp  , xyte_cloud_id: $cloudId, is_claimed: $isClaimed, price: $price}';
  }


  //copy with
  FusionDevice copyWith({
    String? id,
    String? name,
    String? location,
    FusionDeviceSetupStatus? status,
    String? localIp,
    String? cloudId,
    bool? isClaimed,
  }) {
    return FusionDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      localIp: localIp ?? this.localIp,
      cloudId: cloudId ?? this.cloudId,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }



  //from json
  factory FusionDevice.fromJson(Map<String, dynamic> json) {
    return FusionDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      status: FusionDeviceSetupStatus.values.firstWhere(
        (FusionDeviceSetupStatus e) => e.name == json['status'],
        orElse: () => FusionDeviceSetupStatus.notStarted,
      ),
      localIp: json['address'] as String?,
      cloudId: json['xyte_cloud_id'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? false,
    );
  }

  //to json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'status': status.name,
      'location': location,
      'address': localIp,
      'xyte_cloud_id': cloudId,
      'is_claimed': isClaimed,
    };
  }
}
