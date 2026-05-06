// This is a generated file - do not edit.
//
// Generated from fusion/devices.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class DeviceInfo extends $pb.GeneratedMessage {
  factory DeviceInfo({
    $core.String? address,
    $core.String? id,
    $core.String? location,
    $core.String? name,
    $core.String? modelName,
    $core.String? macAddress,
    $core.String? serialNumber,
    $core.bool? isPrimary,
    $core.String? firmwareVersion,
    $core.bool? isDeviceCertificateValid,
  }) {
    final result = create();
    if (address != null) result.address = address;
    if (id != null) result.id = id;
    if (location != null) result.location = location;
    if (name != null) result.name = name;
    if (modelName != null) result.modelName = modelName;
    if (macAddress != null) result.macAddress = macAddress;
    if (serialNumber != null) result.serialNumber = serialNumber;
    if (isPrimary != null) result.isPrimary = isPrimary;
    if (firmwareVersion != null) result.firmwareVersion = firmwareVersion;
    if (isDeviceCertificateValid != null)
      result.isDeviceCertificateValid = isDeviceCertificateValid;
    return result;
  }

  DeviceInfo._();

  factory DeviceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.devices.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'address')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'location')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'modelName')
    ..aOS(6, _omitFieldNames ? '' : 'macAddress')
    ..aOS(7, _omitFieldNames ? '' : 'serialNumber')
    ..aOB(8, _omitFieldNames ? '' : 'isPrimary')
    ..aOS(9, _omitFieldNames ? '' : 'firmwareVersion')
    ..aOB(10, _omitFieldNames ? '' : 'isDeviceCertificateValid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceInfo clone() => DeviceInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceInfo copyWith(void Function(DeviceInfo) updates) =>
      super.copyWith((message) => updates(message as DeviceInfo)) as DeviceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceInfo create() => DeviceInfo._();
  @$core.override
  DeviceInfo createEmptyInstance() => create();
  static $pb.PbList<DeviceInfo> createRepeated() => $pb.PbList<DeviceInfo>();
  @$core.pragma('dart2js:noInline')
  static DeviceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceInfo>(create);
  static DeviceInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get address => $_getSZ(0);
  @$pb.TagNumber(1)
  set address($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get location => $_getSZ(2);
  @$pb.TagNumber(3)
  set location($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocation() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocation() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get modelName => $_getSZ(4);
  @$pb.TagNumber(5)
  set modelName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModelName() => $_has(4);
  @$pb.TagNumber(5)
  void clearModelName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get macAddress => $_getSZ(5);
  @$pb.TagNumber(6)
  set macAddress($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMacAddress() => $_has(5);
  @$pb.TagNumber(6)
  void clearMacAddress() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get serialNumber => $_getSZ(6);
  @$pb.TagNumber(7)
  set serialNumber($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSerialNumber() => $_has(6);
  @$pb.TagNumber(7)
  void clearSerialNumber() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isPrimary => $_getBF(7);
  @$pb.TagNumber(8)
  set isPrimary($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsPrimary() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsPrimary() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get firmwareVersion => $_getSZ(8);
  @$pb.TagNumber(9)
  set firmwareVersion($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFirmwareVersion() => $_has(8);
  @$pb.TagNumber(9)
  void clearFirmwareVersion() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isDeviceCertificateValid => $_getBF(9);
  @$pb.TagNumber(10)
  set isDeviceCertificateValid($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsDeviceCertificateValid() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsDeviceCertificateValid() => $_clearField(10);
}

class DevicePatch extends $pb.GeneratedMessage {
  factory DevicePatch({
    $core.String? id,
    $core.String? location,
    $core.String? name,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (location != null) result.location = location;
    if (name != null) result.name = name;
    return result;
  }

  DevicePatch._();

  factory DevicePatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DevicePatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DevicePatch',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.devices.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'location')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DevicePatch clone() => DevicePatch()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DevicePatch copyWith(void Function(DevicePatch) updates) =>
      super.copyWith((message) => updates(message as DevicePatch))
          as DevicePatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DevicePatch create() => DevicePatch._();
  @$core.override
  DevicePatch createEmptyInstance() => create();
  static $pb.PbList<DevicePatch> createRepeated() => $pb.PbList<DevicePatch>();
  @$core.pragma('dart2js:noInline')
  static DevicePatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DevicePatch>(create);
  static DevicePatch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get location => $_getSZ(1);
  @$pb.TagNumber(2)
  set location($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocation() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocation() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);
}

class DeviceListResponse extends $pb.GeneratedMessage {
  factory DeviceListResponse({
    $core.Iterable<DeviceInfo>? devices,
  }) {
    final result = create();
    if (devices != null) result.devices.addAll(devices);
    return result;
  }

  DeviceListResponse._();

  factory DeviceListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.devices.v1'),
      createEmptyInstance: create)
    ..pc<DeviceInfo>(1, _omitFieldNames ? '' : 'devices', $pb.PbFieldType.PM,
        subBuilder: DeviceInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceListResponse clone() => DeviceListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceListResponse copyWith(void Function(DeviceListResponse) updates) =>
      super.copyWith((message) => updates(message as DeviceListResponse))
          as DeviceListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceListResponse create() => DeviceListResponse._();
  @$core.override
  DeviceListResponse createEmptyInstance() => create();
  static $pb.PbList<DeviceListResponse> createRepeated() =>
      $pb.PbList<DeviceListResponse>();
  @$core.pragma('dart2js:noInline')
  static DeviceListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceListResponse>(create);
  static DeviceListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DeviceInfo> get devices => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
