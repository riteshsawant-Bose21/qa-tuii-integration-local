/// Model class representing a Fusion network device discovered on the network.
class FusionNetworkDevice {
  /// The IP address of the device.
  final String address;

  /// The unique identifier for this device instance.
  final String id;

  /// The location of the device (can be empty).
  final String location;

  /// The name of the device.
  final String name;

  /// the model name of the device
  final String modelName;

  /// The serial number of the device.
  final String serialNumber;

  /// Whether this device is the primary device.
  final bool isPrimary;

  /// The MAC address of the device.
  final String macAddress;

  /// The software update version available for the device.
  final String softwareUpdateVersion;

  /// Whether the device certificate is valid.
  final bool isDeviceCertificateValid;

  /// The monorepo branch running on the device.
  final String fusionMonorepoBranch;

  /// The monorepo commit hash running on the device.
  final String fusionMonorepoCommitHash;

  /// The Jenkins build number running on the device.
  final String jenkinsBuildNumber;

  const FusionNetworkDevice({
    required this.address,
    required this.id,
    this.location = '',
    required this.name,
    this.modelName = '',
    required this.serialNumber,
    this.isPrimary = false,
    this.macAddress = '',
    this.softwareUpdateVersion = '',
    this.isDeviceCertificateValid = false,
    this.fusionMonorepoBranch = '',
    this.fusionMonorepoCommitHash = '',
    this.jenkinsBuildNumber = '',
  });

  factory FusionNetworkDevice.fromJson(Map<String, dynamic> json) {
    return FusionNetworkDevice(
      address: json['address'] as String? ?? '',
      id: json['id'] as String? ?? '',
      location: json['location'] as String? ?? '',
      name: json['name'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      serialNumber: json['serial_number'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      macAddress: json['mac_address'] as String? ?? '',
      softwareUpdateVersion: json['software_update_version'] as String? ?? '',
      isDeviceCertificateValid: json['is_device_certificate_valid'] as bool? ?? false,
      fusionMonorepoBranch: json['fusion_monorepo_branch'] as String? ?? '',
      fusionMonorepoCommitHash: json['fusion_monorepo_commit_hash'] as String? ?? '',
      jenkinsBuildNumber: json['jenkins_build_number'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'id': id,
      'location': location,
      'name': name,
      'model_name': modelName,
      'serial_number': serialNumber,
      'is_primary': isPrimary,
      'mac_address': macAddress,
      'software_update_version': softwareUpdateVersion,
      'is_device_certificate_valid': isDeviceCertificateValid,
      'fusion_monorepo_branch': fusionMonorepoBranch,
      'fusion_monorepo_commit_hash': fusionMonorepoCommitHash,
      'jenkins_build_number': jenkinsBuildNumber,
    };
  }

  FusionNetworkDevice copyWith({
    String? address,
    String? id,
    String? location,
    String? name,
    String? modelName,
    String? serialNumber,
    bool? isPrimary,
    String? macAddress,
    String? softwareUpdateVersion,
    bool? isDeviceCertificateValid,
    String? fusionMonorepoBranch,
    String? fusionMonorepoCommitHash,
    String? jenkinsBuildNumber,
  }) {
    return FusionNetworkDevice(
      address: address ?? this.address,
      id: id ?? this.id,
      location: location ?? this.location,
      name: name ?? this.name,
      modelName: modelName ?? this.modelName,
      serialNumber: serialNumber ?? this.serialNumber,
      isPrimary: isPrimary ?? this.isPrimary,
      macAddress: macAddress ?? this.macAddress,
      softwareUpdateVersion: softwareUpdateVersion ?? this.softwareUpdateVersion,
      isDeviceCertificateValid: isDeviceCertificateValid ?? this.isDeviceCertificateValid,
      fusionMonorepoBranch: fusionMonorepoBranch ?? this.fusionMonorepoBranch,
      fusionMonorepoCommitHash: fusionMonorepoCommitHash ?? this.fusionMonorepoCommitHash,
      jenkinsBuildNumber: jenkinsBuildNumber ?? this.jenkinsBuildNumber,
    );
  }

  @override
  String toString() {
    return 'FusionNetworkDevice(address: $address, id: $id, name: $name, '
        'modelName: $modelName, serialNumber: $serialNumber, isPrimary: $isPrimary, '
        'macAddress: $macAddress, softwareUpdateVersion: $softwareUpdateVersion, '
        'isDeviceCertificateValid: $isDeviceCertificateValid, '
        'fusionMonorepoBranch: $fusionMonorepoBranch)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FusionNetworkDevice &&
        other.address == address &&
        other.id == id &&
        other.location == location &&
        other.name == name &&
        other.modelName == modelName &&
        other.serialNumber == serialNumber &&
        other.isPrimary == isPrimary &&
        other.macAddress == macAddress &&
        other.softwareUpdateVersion == softwareUpdateVersion &&
        other.isDeviceCertificateValid == isDeviceCertificateValid &&
        other.fusionMonorepoBranch == fusionMonorepoBranch &&
        other.fusionMonorepoCommitHash == fusionMonorepoCommitHash &&
        other.jenkinsBuildNumber == jenkinsBuildNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      address,
      id,
      location,
      name,
      modelName,
      serialNumber,
      isPrimary,
      macAddress,
      softwareUpdateVersion,
      isDeviceCertificateValid,
      fusionMonorepoBranch,
      fusionMonorepoCommitHash,
      jenkinsBuildNumber,
    );
  }
}
