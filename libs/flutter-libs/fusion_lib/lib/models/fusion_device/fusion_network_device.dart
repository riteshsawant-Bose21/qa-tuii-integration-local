import 'package:equatable/equatable.dart';
import 'package:fusion_lib/generated/proto/fusion/websocket.pb.dart' as wsmodel;
import 'package:fusion_lib/generated/proto/google/protobuf/struct.pb.dart' as structpb;

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

  final String? preReleaseTag;

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
    this.preReleaseTag,
  });

  // String? get primaryDeviceVersion {
  //   if (!isPrimary) return null;

  //   if (preReleaseTag != null &&
  //       preReleaseTag!.isNotEmpty &&
  //       preReleaseTag!.toLowerCase() != 'unknown') {
  //     return "$softwareUpdateVersion-$preReleaseTag.$jenkinsBuildNumber";
  //   }

  //   return softwareUpdateVersion;
  // }

  factory FusionNetworkDevice.fromJson(Map<String, dynamic> json) {
    return FusionNetworkDevice(
      address: json['address'] as String? ?? '',
      id: json['id'] as String? ?? '',
      location: json['location'] as String? ?? '',
      name: json['name'] as String? ?? '',
      modelName: json['serial_number'] == "07323a09dabc1d39" ? "XLRPAL" : 'FM8Y', //json['model_name'] as String? ?? ''
      serialNumber: json['serial_number'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      macAddress: json['mac_address'] as String? ?? '',
      softwareUpdateVersion: json['software_update_version'] as String? ?? '',
      isDeviceCertificateValid: json['is_device_certificate_valid'] as bool? ?? false,
      fusionMonorepoBranch: json['fusion_monorepo_branch'] as String? ?? '',
      fusionMonorepoCommitHash: json['fusion_monorepo_commit_hash'] as String? ?? '',
      jenkinsBuildNumber: json['jenkins_build_number'] as String? ?? '',
      preReleaseTag: json['pre_release_tag'] as String?,
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
      'pre_release_tag': preReleaseTag,
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
    String? preReleaseTag,
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
      preReleaseTag: preReleaseTag ?? this.preReleaseTag,
    );
  }

  @override
  String toString() {
    return 'FusionNetworkDevice(address: $address, id: $id, name: $name, '
        'modelName: $modelName, serialNumber: $serialNumber, isPrimary: $isPrimary, '
        'macAddress: $macAddress, softwareUpdateVersion: $softwareUpdateVersion, '
        'isDeviceCertificateValid: $isDeviceCertificateValid, '
        'fusionMonorepoBranch: $fusionMonorepoBranch, '
        'fusionMonorepoCommitHash: $fusionMonorepoCommitHash, '
        'jenkinsBuildNumber: $jenkinsBuildNumber, '
        'preReleaseTag: $preReleaseTag)';
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
        other.jenkinsBuildNumber == jenkinsBuildNumber &&
        other.preReleaseTag == preReleaseTag;
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
      preReleaseTag,
    );
  }
}

class FirmwareUpdateCheckResult extends Equatable {
  final bool updateAvailable;
  final bool appUpdateRequired;
  final String? bundleId;
  final String? version;
  final String? releaseNotes;
  final String? minDesktopAppVersion;

  const FirmwareUpdateCheckResult({
    required this.updateAvailable,
    required this.appUpdateRequired,
    this.bundleId,
    this.version,
    this.releaseNotes,
    this.minDesktopAppVersion,
  });

  factory FirmwareUpdateCheckResult.fromJson(Map<String, dynamic> json) {
    return FirmwareUpdateCheckResult(
      updateAvailable: json['update_available'] as bool? ?? false,
      appUpdateRequired: json['app_update_required'] as bool? ?? false,
      bundleId: json['bundle_id'] as String?,
      version: json['version'] as String?,
      releaseNotes: json['release_notes'] as String?,
      minDesktopAppVersion: json['min_desktop_app_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'update_available': updateAvailable,
      'app_update_required': appUpdateRequired,
      'bundle_id': bundleId,
      'version': version,
      'release_notes': releaseNotes,
      'min_desktop_app_version': minDesktopAppVersion,
    };
  }

  @override
  List<Object?> get props => [
    updateAvailable,
    appUpdateRequired,
    bundleId,
    version,
    releaseNotes,
    minDesktopAppVersion,
  ];
}

class BundleDownloadUrlResult extends Equatable {
  final String downloadUrl;
  final String checksum;

  const BundleDownloadUrlResult({
    required this.downloadUrl,
    required this.checksum,
  });

  @override
  List<Object?> get props => [downloadUrl, checksum];

  factory BundleDownloadUrlResult.fromJson(Map<String, dynamic> json) {
    return BundleDownloadUrlResult(
      downloadUrl: json['download_url'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'download_url': downloadUrl,
      'checksum': checksum,
    };
  }

  String get downloadFileName => Uri.parse(downloadUrl).pathSegments.last;
}

class CloudDeviceRegisterResult {
  final String certificate;

  const CloudDeviceRegisterResult({
    required this.certificate,
  });

  factory CloudDeviceRegisterResult.fromJson(Map<String, dynamic> json) {
    return CloudDeviceRegisterResult(
      certificate: json['certificate'] as String? ?? '',
    );
  }
}

class FirmwareDeviceRebootStatus extends Equatable {
  final String serialNumber;
  final String currentBundleVersion;
  final String status;
  final String currentState;

  const FirmwareDeviceRebootStatus({
    required this.serialNumber,
    required this.currentBundleVersion,
    required this.status,
    required this.currentState,
  });

  @override
  List<Object?> get props => <Object?>[
    serialNumber,
    currentBundleVersion,
    status,
    currentState,
  ];

  bool get isSUCCESS => status.toUpperCase() == 'SUCCESS';
}

class DeviceUpdateProgressEvent extends Equatable {
  final String serialNumber;
  final String node;
  final String updateState;
  final String step;
  final String currentTask;
  final int progress;
  final String handler;
  final String timestamp;

  const DeviceUpdateProgressEvent({
    required this.serialNumber,
    required this.node,
    required this.updateState,
    required this.step,
    required this.currentTask,
    required this.progress,
    required this.handler,
    required this.timestamp,
  });

  factory DeviceUpdateProgressEvent.fromJson(Map<String, dynamic> json) {
    final String rawProgress = json['progress']?.toString() ?? '0';
    final int parsedProgress = int.tryParse(rawProgress) ?? 0;
    return DeviceUpdateProgressEvent(
      serialNumber: json['serial_number']?.toString() ?? '',
      node: json['node']?.toString() ?? '',
      updateState: json['update_state']?.toString() ?? '',
      step: json['step']?.toString() ?? '0/0',
      currentTask: json['current_task']?.toString() ?? '',
      progress: parsedProgress.clamp(0, 100),
      handler: json['handler']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  factory DeviceUpdateProgressEvent.fromProtoValue(structpb.Value value) {
    final structpb.Struct? payload = value.hasStructValue() ? value.structValue : null;
    final Map<String, structpb.Value> fields = payload?.fields ?? const {};

    final String rawProgress = _stringFromValue(fields['progress']) ?? _intFromValue(fields['progress']).toString();
    final int parsedProgress = int.tryParse(rawProgress) ?? 0;

    return DeviceUpdateProgressEvent(
      serialNumber: _stringFromValue(fields['serial_number']) ?? '',
      node: _stringFromValue(fields['node']) ?? '',
      updateState: _stringFromValue(fields['update_state']) ?? '',
      step: _stringFromValue(fields['step']) ?? '0/0',
      currentTask: _stringFromValue(fields['current_task']) ?? '',
      progress: parsedProgress.clamp(0, 100),
      handler: _stringFromValue(fields['handler']) ?? '',
      timestamp: _stringFromValue(fields['timestamp']) ?? '',
    );
  }

  factory DeviceUpdateProgressEvent.empty({required String serialNumber}) {
    return DeviceUpdateProgressEvent(
      serialNumber: serialNumber,
      currentTask: "Not yet started any task",
      node: 'Node will be assigned soon',
      handler: '',
      progress: 0,
      step: '0/0',
      timestamp: '',
      updateState: 'PENDING',
    );
  }

  bool get isCompleted => updateState.toUpperCase() == 'COMPLETED';
  bool get isSuccess => updateState.toUpperCase() == 'SUCCESS';
  bool get isFailed => updateState.contains('FAIL') || updateState.contains('ERROR');
  double get stepProgress => progress.clamp(0, 100) / 100.0;

  @override
  List<Object?> get props => <Object?>[
    serialNumber,
    node,
    updateState,
    step,
    currentTask,
    progress,
    handler,
    timestamp,
  ];

  DeviceUpdateProgressEvent copyWith({
    String? serialNumber,
    String? node,
    String? updateState,
    String? step,
    String? currentTask,
    int? progress,
    String? handler,
    String? timestamp,
  }) {
    final bool canStepOverwrite = updateState != "COMPLETED";

    return DeviceUpdateProgressEvent(
      serialNumber: serialNumber ?? this.serialNumber,
      node: node ?? this.node,
      updateState: updateState ?? this.updateState,
      step: canStepOverwrite ? (step ?? this.step) : this.step,
      currentTask: currentTask ?? this.currentTask,
      progress: progress ?? this.progress,
      handler: handler ?? this.handler,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class FirmwareUpdateProgressEvent extends Equatable {
  final String type;
  final String status;
  final int code;
  final String message;
  final String timestamp;
  final Map<String, DeviceUpdateProgressEvent> devicesBySerial;

  const FirmwareUpdateProgressEvent({
    required this.type,
    required this.status,
    required this.code,
    required this.message,
    required this.timestamp,
    required this.devicesBySerial,
  });

  bool get isUpdateProgress => type == 'update_progress';

  factory FirmwareUpdateProgressEvent.fromJson(Map<String, dynamic> json) {
    final Map<String, DeviceUpdateProgressEvent> devicesBySerial = <String, DeviceUpdateProgressEvent>{};
    final dynamic rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawData.entries) {
        final dynamic value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final DeviceUpdateProgressEvent parsed = DeviceUpdateProgressEvent.fromJson(value);
        final String serial = parsed.serialNumber.trim();
        final String key = serial.isNotEmpty ? serial : entry.key;
        devicesBySerial[key] = parsed;
      }
    }

    return FirmwareUpdateProgressEvent(
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      code: json['code'] is int ? json['code'] as int : int.tryParse(json['code']?.toString() ?? '') ?? 0,
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      devicesBySerial: devicesBySerial,
    );
  }

  factory FirmwareUpdateProgressEvent.fromWebSocketResponse(
    wsmodel.WebSocketResponse response,
  ) {
    final Map<String, DeviceUpdateProgressEvent> devicesBySerial = <String, DeviceUpdateProgressEvent>{};

    if (response.hasData() && response.data.hasStructValue()) {
      final Map<String, structpb.Value> entries = response.data.structValue.fields;
      for (final MapEntry<String, structpb.Value> entry in entries.entries) {
        if (!entry.value.hasStructValue()) {
          continue;
        }
        final DeviceUpdateProgressEvent parsed = DeviceUpdateProgressEvent.fromProtoValue(entry.value);
        final String serial = parsed.serialNumber.trim();
        final String key = serial.isNotEmpty ? serial : entry.key;
        devicesBySerial[key] = parsed;
      }
    }

    return FirmwareUpdateProgressEvent(
      type: response.type,
      status: response.status,
      code: response.code,
      message: response.message,
      timestamp: response.hasTimestamp() ? response.timestamp.toDateTime().toUtc().toIso8601String() : '',
      devicesBySerial: devicesBySerial,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    type,
    status,
    code,
    message,
    timestamp,
    devicesBySerial,
  ];
}

String? _stringFromValue(structpb.Value? value) {
  if (value == null) return null;
  if (value.hasStringValue()) return value.stringValue;
  if (value.hasNumberValue()) return value.numberValue.toString();
  if (value.hasBoolValue()) return value.boolValue.toString();
  return null;
}

int _intFromValue(structpb.Value? value) {
  if (value == null) return 0;
  if (value.hasNumberValue()) return value.numberValue.toInt();
  if (value.hasStringValue()) return int.tryParse(value.stringValue) ?? 0;
  return 0;
}
