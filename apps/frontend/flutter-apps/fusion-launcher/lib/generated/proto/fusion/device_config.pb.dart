// This is a generated file - do not edit.
//
// Generated from fusion/device_config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/struct.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// DroConditionedOutputEnvelope models the configurator response envelope seen in
/// fusion-dsp-configurator-prototype/outputs/*.json.
///
/// This is not the same thing as the PUT /device deployment package. The
/// deployment package may be assembled from this conditioned output plus other
/// launcher-managed sections.
class DroConditionedOutputEnvelope extends $pb.GeneratedMessage {
  factory DroConditionedOutputEnvelope({
    $core.String? requestId,
    $core.String? responseId,
    $core.int? statusCode,
    $core.String? statusMessage,
    $core.String? version,
    DroConditionedOutput? result,
  }) {
    final result$ = create();
    if (requestId != null) result$.requestId = requestId;
    if (responseId != null) result$.responseId = responseId;
    if (statusCode != null) result$.statusCode = statusCode;
    if (statusMessage != null) result$.statusMessage = statusMessage;
    if (version != null) result$.version = version;
    if (result != null) result$.result = result;
    return result$;
  }

  DroConditionedOutputEnvelope._();

  factory DroConditionedOutputEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroConditionedOutputEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroConditionedOutputEnvelope',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOS(2, _omitFieldNames ? '' : 'responseId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'statusCode', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'statusMessage')
    ..aOS(5, _omitFieldNames ? '' : 'version')
    ..aOM<DroConditionedOutput>(6, _omitFieldNames ? '' : 'result',
        subBuilder: DroConditionedOutput.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroConditionedOutputEnvelope clone() =>
      DroConditionedOutputEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroConditionedOutputEnvelope copyWith(
          void Function(DroConditionedOutputEnvelope) updates) =>
      super.copyWith(
              (message) => updates(message as DroConditionedOutputEnvelope))
          as DroConditionedOutputEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroConditionedOutputEnvelope create() =>
      DroConditionedOutputEnvelope._();
  @$core.override
  DroConditionedOutputEnvelope createEmptyInstance() => create();
  static $pb.PbList<DroConditionedOutputEnvelope> createRepeated() =>
      $pb.PbList<DroConditionedOutputEnvelope>();
  @$core.pragma('dart2js:noInline')
  static DroConditionedOutputEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DroConditionedOutputEnvelope>(create);
  static DroConditionedOutputEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get responseId => $_getSZ(1);
  @$pb.TagNumber(2)
  set responseId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseId() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get statusMessage => $_getSZ(3);
  @$pb.TagNumber(4)
  set statusMessage($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStatusMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatusMessage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get version => $_getSZ(4);
  @$pb.TagNumber(5)
  set version($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  DroConditionedOutput get result => $_getN(5);
  @$pb.TagNumber(6)
  set result(DroConditionedOutput value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasResult() => $_has(5);
  @$pb.TagNumber(6)
  void clearResult() => $_clearField(6);
  @$pb.TagNumber(6)
  DroConditionedOutput ensureResult() => $_ensure(5);
}

/// DroConditionedOutput is the current best representation of the "result"
/// object emitted by the DSP configurator.
class DroConditionedOutput extends $pb.GeneratedMessage {
  factory DroConditionedOutput({
    $core.Iterable<DroConditionedDevice>? devices,
    $core.Iterable<DroAes67Stream>? aes67Streams,
    $core.Iterable<DroDeviceConnection>? deviceConnections,
    $core.Iterable<DroIoPort>? ioPorts,
    $core.Iterable<DroLatency>? latencies,
    $core.double? totalCost,
  }) {
    final result = create();
    if (devices != null) result.devices.addAll(devices);
    if (aes67Streams != null) result.aes67Streams.addAll(aes67Streams);
    if (deviceConnections != null)
      result.deviceConnections.addAll(deviceConnections);
    if (ioPorts != null) result.ioPorts.addAll(ioPorts);
    if (latencies != null) result.latencies.addAll(latencies);
    if (totalCost != null) result.totalCost = totalCost;
    return result;
  }

  DroConditionedOutput._();

  factory DroConditionedOutput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroConditionedOutput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroConditionedOutput',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..pc<DroConditionedDevice>(
        1, _omitFieldNames ? '' : 'devices', $pb.PbFieldType.PM,
        subBuilder: DroConditionedDevice.create)
    ..pc<DroAes67Stream>(
        2, _omitFieldNames ? '' : 'aes67Streams', $pb.PbFieldType.PM,
        subBuilder: DroAes67Stream.create)
    ..pc<DroDeviceConnection>(
        3, _omitFieldNames ? '' : 'deviceConnections', $pb.PbFieldType.PM,
        subBuilder: DroDeviceConnection.create)
    ..pc<DroIoPort>(4, _omitFieldNames ? '' : 'ioPorts', $pb.PbFieldType.PM,
        subBuilder: DroIoPort.create)
    ..pc<DroLatency>(5, _omitFieldNames ? '' : 'latencies', $pb.PbFieldType.PM,
        subBuilder: DroLatency.create)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'totalCost', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroConditionedOutput clone() =>
      DroConditionedOutput()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroConditionedOutput copyWith(void Function(DroConditionedOutput) updates) =>
      super.copyWith((message) => updates(message as DroConditionedOutput))
          as DroConditionedOutput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroConditionedOutput create() => DroConditionedOutput._();
  @$core.override
  DroConditionedOutput createEmptyInstance() => create();
  static $pb.PbList<DroConditionedOutput> createRepeated() =>
      $pb.PbList<DroConditionedOutput>();
  @$core.pragma('dart2js:noInline')
  static DroConditionedOutput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DroConditionedOutput>(create);
  static DroConditionedOutput? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DroConditionedDevice> get devices => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<DroAes67Stream> get aes67Streams => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<DroDeviceConnection> get deviceConnections => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<DroIoPort> get ioPorts => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<DroLatency> get latencies => $_getList(4);

  @$pb.TagNumber(6)
  $core.double get totalCost => $_getN(5);
  @$pb.TagNumber(6)
  set totalCost($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalCost() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalCost() => $_clearField(6);
}

/// DeviceConfigurationPackage is the first-pass typed contract for PUT /device.
///
/// It intentionally separates the DRO-conditioned output from the additional
/// deployment information generated by Fusion Connect / launcher.
class DeviceConfigurationPackage extends $pb.GeneratedMessage {
  factory DeviceConfigurationPackage({
    DroConditionedOutput? droConditionedOutput,
    FusionConnectAdditions? fusionConnectAdditions,
  }) {
    final result = create();
    if (droConditionedOutput != null)
      result.droConditionedOutput = droConditionedOutput;
    if (fusionConnectAdditions != null)
      result.fusionConnectAdditions = fusionConnectAdditions;
    return result;
  }

  DeviceConfigurationPackage._();

  factory DeviceConfigurationPackage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceConfigurationPackage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceConfigurationPackage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOM<DroConditionedOutput>(
        1, _omitFieldNames ? '' : 'droConditionedOutput',
        subBuilder: DroConditionedOutput.create)
    ..aOM<FusionConnectAdditions>(
        2, _omitFieldNames ? '' : 'fusionConnectAdditions',
        subBuilder: FusionConnectAdditions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceConfigurationPackage clone() =>
      DeviceConfigurationPackage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceConfigurationPackage copyWith(
          void Function(DeviceConfigurationPackage) updates) =>
      super.copyWith(
              (message) => updates(message as DeviceConfigurationPackage))
          as DeviceConfigurationPackage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceConfigurationPackage create() => DeviceConfigurationPackage._();
  @$core.override
  DeviceConfigurationPackage createEmptyInstance() => create();
  static $pb.PbList<DeviceConfigurationPackage> createRepeated() =>
      $pb.PbList<DeviceConfigurationPackage>();
  @$core.pragma('dart2js:noInline')
  static DeviceConfigurationPackage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceConfigurationPackage>(create);
  static DeviceConfigurationPackage? _defaultInstance;

  @$pb.TagNumber(1)
  DroConditionedOutput get droConditionedOutput => $_getN(0);
  @$pb.TagNumber(1)
  set droConditionedOutput(DroConditionedOutput value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDroConditionedOutput() => $_has(0);
  @$pb.TagNumber(1)
  void clearDroConditionedOutput() => $_clearField(1);
  @$pb.TagNumber(1)
  DroConditionedOutput ensureDroConditionedOutput() => $_ensure(0);

  @$pb.TagNumber(2)
  FusionConnectAdditions get fusionConnectAdditions => $_getN(1);
  @$pb.TagNumber(2)
  set fusionConnectAdditions(FusionConnectAdditions value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFusionConnectAdditions() => $_has(1);
  @$pb.TagNumber(2)
  void clearFusionConnectAdditions() => $_clearField(2);
  @$pb.TagNumber(2)
  FusionConnectAdditions ensureFusionConnectAdditions() => $_ensure(1);
}

/// FusionConnectAdditions captures the extra deployment-time information added
/// outside the raw DRO-conditioned output.
class FusionConnectAdditions extends $pb.GeneratedMessage {
  factory FusionConnectAdditions({
    $core.Iterable<FusionConnectAudioStream>? audioStreams,
    FusionConnectAudioSettings? settings,
  }) {
    final result = create();
    if (audioStreams != null) result.audioStreams.addAll(audioStreams);
    if (settings != null) result.settings = settings;
    return result;
  }

  FusionConnectAdditions._();

  factory FusionConnectAdditions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FusionConnectAdditions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FusionConnectAdditions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..pc<FusionConnectAudioStream>(
        1, _omitFieldNames ? '' : 'audioStreams', $pb.PbFieldType.PM,
        subBuilder: FusionConnectAudioStream.create)
    ..aOM<FusionConnectAudioSettings>(2, _omitFieldNames ? '' : 'settings',
        subBuilder: FusionConnectAudioSettings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAdditions clone() =>
      FusionConnectAdditions()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAdditions copyWith(
          void Function(FusionConnectAdditions) updates) =>
      super.copyWith((message) => updates(message as FusionConnectAdditions))
          as FusionConnectAdditions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FusionConnectAdditions create() => FusionConnectAdditions._();
  @$core.override
  FusionConnectAdditions createEmptyInstance() => create();
  static $pb.PbList<FusionConnectAdditions> createRepeated() =>
      $pb.PbList<FusionConnectAdditions>();
  @$core.pragma('dart2js:noInline')
  static FusionConnectAdditions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FusionConnectAdditions>(create);
  static FusionConnectAdditions? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FusionConnectAudioStream> get audioStreams => $_getList(0);

  @$pb.TagNumber(2)
  FusionConnectAudioSettings get settings => $_getN(1);
  @$pb.TagNumber(2)
  set settings(FusionConnectAudioSettings value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSettings() => $_has(1);
  @$pb.TagNumber(2)
  void clearSettings() => $_clearField(2);
  @$pb.TagNumber(2)
  FusionConnectAudioSettings ensureSettings() => $_ensure(1);
}

/// DroConditionedDevice comes from the configurator result and owns the deployable
/// DSP static configuration for one device.
class DroConditionedDevice extends $pb.GeneratedMessage {
  factory DroConditionedDevice({
    $core.String? id,
    $core.String? label,
    $core.String? deviceType,
    $core.String? location,
    $core.double? cost,
    $core.Iterable<DroCore>? cores,
    $core.Iterable<$0.ListValue>? connectionsDeviceIn,
    $core.Iterable<$0.ListValue>? connectionsDeviceOut,
    StaticConfiguration? dspStaticConfig,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (deviceType != null) result.deviceType = deviceType;
    if (location != null) result.location = location;
    if (cost != null) result.cost = cost;
    if (cores != null) result.cores.addAll(cores);
    if (connectionsDeviceIn != null)
      result.connectionsDeviceIn.addAll(connectionsDeviceIn);
    if (connectionsDeviceOut != null)
      result.connectionsDeviceOut.addAll(connectionsDeviceOut);
    if (dspStaticConfig != null) result.dspStaticConfig = dspStaticConfig;
    return result;
  }

  DroConditionedDevice._();

  factory DroConditionedDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroConditionedDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroConditionedDevice',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'deviceType')
    ..aOS(4, _omitFieldNames ? '' : 'location')
    ..a<$core.double>(5, _omitFieldNames ? '' : 'cost', $pb.PbFieldType.OD)
    ..pc<DroCore>(6, _omitFieldNames ? '' : 'cores', $pb.PbFieldType.PM,
        subBuilder: DroCore.create)
    ..pc<$0.ListValue>(
        7, _omitFieldNames ? '' : 'connectionsDeviceIn', $pb.PbFieldType.PM,
        subBuilder: $0.ListValue.create)
    ..pc<$0.ListValue>(
        8, _omitFieldNames ? '' : 'connectionsDeviceOut', $pb.PbFieldType.PM,
        subBuilder: $0.ListValue.create)
    ..aOM<StaticConfiguration>(9, _omitFieldNames ? '' : 'dspStaticConfig',
        subBuilder: StaticConfiguration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroConditionedDevice clone() =>
      DroConditionedDevice()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroConditionedDevice copyWith(void Function(DroConditionedDevice) updates) =>
      super.copyWith((message) => updates(message as DroConditionedDevice))
          as DroConditionedDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroConditionedDevice create() => DroConditionedDevice._();
  @$core.override
  DroConditionedDevice createEmptyInstance() => create();
  static $pb.PbList<DroConditionedDevice> createRepeated() =>
      $pb.PbList<DroConditionedDevice>();
  @$core.pragma('dart2js:noInline')
  static DroConditionedDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DroConditionedDevice>(create);
  static DroConditionedDevice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deviceType => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceType() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get location => $_getSZ(3);
  @$pb.TagNumber(4)
  set location($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLocation() => $_has(3);
  @$pb.TagNumber(4)
  void clearLocation() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get cost => $_getN(4);
  @$pb.TagNumber(5)
  set cost($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCost() => $_has(4);
  @$pb.TagNumber(5)
  void clearCost() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<DroCore> get cores => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$0.ListValue> get connectionsDeviceIn => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$0.ListValue> get connectionsDeviceOut => $_getList(7);

  @$pb.TagNumber(9)
  StaticConfiguration get dspStaticConfig => $_getN(8);
  @$pb.TagNumber(9)
  set dspStaticConfig(StaticConfiguration value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasDspStaticConfig() => $_has(8);
  @$pb.TagNumber(9)
  void clearDspStaticConfig() => $_clearField(9);
  @$pb.TagNumber(9)
  StaticConfiguration ensureDspStaticConfig() => $_ensure(8);
}

class DroCore extends $pb.GeneratedMessage {
  factory DroCore({
    $core.String? label,
    $core.double? utilAlgs,
    $core.double? utilDeviceConnect,
    $core.double? utilTaskConnect,
    $core.double? utilTotal,
    $core.Iterable<$core.String>? blockIds,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (utilAlgs != null) result.utilAlgs = utilAlgs;
    if (utilDeviceConnect != null) result.utilDeviceConnect = utilDeviceConnect;
    if (utilTaskConnect != null) result.utilTaskConnect = utilTaskConnect;
    if (utilTotal != null) result.utilTotal = utilTotal;
    if (blockIds != null) result.blockIds.addAll(blockIds);
    return result;
  }

  DroCore._();

  factory DroCore.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroCore.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroCore',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..a<$core.double>(2, _omitFieldNames ? '' : 'utilAlgs', $pb.PbFieldType.OD)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'utilDeviceConnect', $pb.PbFieldType.OD)
    ..a<$core.double>(
        4, _omitFieldNames ? '' : 'utilTaskConnect', $pb.PbFieldType.OD)
    ..a<$core.double>(5, _omitFieldNames ? '' : 'utilTotal', $pb.PbFieldType.OD)
    ..pPS(6, _omitFieldNames ? '' : 'blockIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroCore clone() => DroCore()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroCore copyWith(void Function(DroCore) updates) =>
      super.copyWith((message) => updates(message as DroCore)) as DroCore;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroCore create() => DroCore._();
  @$core.override
  DroCore createEmptyInstance() => create();
  static $pb.PbList<DroCore> createRepeated() => $pb.PbList<DroCore>();
  @$core.pragma('dart2js:noInline')
  static DroCore getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DroCore>(create);
  static DroCore? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get utilAlgs => $_getN(1);
  @$pb.TagNumber(2)
  set utilAlgs($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUtilAlgs() => $_has(1);
  @$pb.TagNumber(2)
  void clearUtilAlgs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get utilDeviceConnect => $_getN(2);
  @$pb.TagNumber(3)
  set utilDeviceConnect($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUtilDeviceConnect() => $_has(2);
  @$pb.TagNumber(3)
  void clearUtilDeviceConnect() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get utilTaskConnect => $_getN(3);
  @$pb.TagNumber(4)
  set utilTaskConnect($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUtilTaskConnect() => $_has(3);
  @$pb.TagNumber(4)
  void clearUtilTaskConnect() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get utilTotal => $_getN(4);
  @$pb.TagNumber(5)
  set utilTotal($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUtilTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearUtilTotal() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get blockIds => $_getList(5);
}

class DroAes67Stream extends $pb.GeneratedMessage {
  factory DroAes67Stream({
    $core.String? streamId,
    $core.String? streamName,
    $core.String? direction,
    $core.String? multicastDestinationIp,
    $core.String? sourceDevice,
    $core.int? channels,
    $core.String? description,
    $core.String? destinationDevice,
  }) {
    final result = create();
    if (streamId != null) result.streamId = streamId;
    if (streamName != null) result.streamName = streamName;
    if (direction != null) result.direction = direction;
    if (multicastDestinationIp != null)
      result.multicastDestinationIp = multicastDestinationIp;
    if (sourceDevice != null) result.sourceDevice = sourceDevice;
    if (channels != null) result.channels = channels;
    if (description != null) result.description = description;
    if (destinationDevice != null) result.destinationDevice = destinationDevice;
    return result;
  }

  DroAes67Stream._();

  factory DroAes67Stream.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroAes67Stream.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroAes67Stream',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'streamId')
    ..aOS(2, _omitFieldNames ? '' : 'streamName')
    ..aOS(3, _omitFieldNames ? '' : 'direction')
    ..aOS(4, _omitFieldNames ? '' : 'multicastDestinationIp')
    ..aOS(5, _omitFieldNames ? '' : 'sourceDevice')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'channels', $pb.PbFieldType.OU3)
    ..aOS(7, _omitFieldNames ? '' : 'description')
    ..aOS(8, _omitFieldNames ? '' : 'destinationDevice')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroAes67Stream clone() => DroAes67Stream()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroAes67Stream copyWith(void Function(DroAes67Stream) updates) =>
      super.copyWith((message) => updates(message as DroAes67Stream))
          as DroAes67Stream;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroAes67Stream create() => DroAes67Stream._();
  @$core.override
  DroAes67Stream createEmptyInstance() => create();
  static $pb.PbList<DroAes67Stream> createRepeated() =>
      $pb.PbList<DroAes67Stream>();
  @$core.pragma('dart2js:noInline')
  static DroAes67Stream getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DroAes67Stream>(create);
  static DroAes67Stream? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get streamId => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStreamId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get streamName => $_getSZ(1);
  @$pb.TagNumber(2)
  set streamName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStreamName() => $_has(1);
  @$pb.TagNumber(2)
  void clearStreamName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get direction => $_getSZ(2);
  @$pb.TagNumber(3)
  set direction($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDirection() => $_has(2);
  @$pb.TagNumber(3)
  void clearDirection() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get multicastDestinationIp => $_getSZ(3);
  @$pb.TagNumber(4)
  set multicastDestinationIp($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMulticastDestinationIp() => $_has(3);
  @$pb.TagNumber(4)
  void clearMulticastDestinationIp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get sourceDevice => $_getSZ(4);
  @$pb.TagNumber(5)
  set sourceDevice($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSourceDevice() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourceDevice() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get channels => $_getIZ(5);
  @$pb.TagNumber(6)
  set channels($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChannels() => $_has(5);
  @$pb.TagNumber(6)
  void clearChannels() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get description => $_getSZ(6);
  @$pb.TagNumber(7)
  set description($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDescription() => $_has(6);
  @$pb.TagNumber(7)
  void clearDescription() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get destinationDevice => $_getSZ(7);
  @$pb.TagNumber(8)
  set destinationDevice($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDestinationDevice() => $_has(7);
  @$pb.TagNumber(8)
  void clearDestinationDevice() => $_clearField(8);
}

class DroDeviceConnection extends $pb.GeneratedMessage {
  factory DroDeviceConnection({
    $core.String? sourceDevice,
    $core.String? destinationDevice,
    $core.int? channels,
    $core.String? sourcePort,
  }) {
    final result = create();
    if (sourceDevice != null) result.sourceDevice = sourceDevice;
    if (destinationDevice != null) result.destinationDevice = destinationDevice;
    if (channels != null) result.channels = channels;
    if (sourcePort != null) result.sourcePort = sourcePort;
    return result;
  }

  DroDeviceConnection._();

  factory DroDeviceConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroDeviceConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroDeviceConnection',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceDevice')
    ..aOS(2, _omitFieldNames ? '' : 'destinationDevice')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'channels', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'sourcePort')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroDeviceConnection clone() => DroDeviceConnection()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroDeviceConnection copyWith(void Function(DroDeviceConnection) updates) =>
      super.copyWith((message) => updates(message as DroDeviceConnection))
          as DroDeviceConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroDeviceConnection create() => DroDeviceConnection._();
  @$core.override
  DroDeviceConnection createEmptyInstance() => create();
  static $pb.PbList<DroDeviceConnection> createRepeated() =>
      $pb.PbList<DroDeviceConnection>();
  @$core.pragma('dart2js:noInline')
  static DroDeviceConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DroDeviceConnection>(create);
  static DroDeviceConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceDevice => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceDevice($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceDevice() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get destinationDevice => $_getSZ(1);
  @$pb.TagNumber(2)
  set destinationDevice($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDestinationDevice() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestinationDevice() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get channels => $_getIZ(2);
  @$pb.TagNumber(3)
  set channels($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannels() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannels() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sourcePort => $_getSZ(3);
  @$pb.TagNumber(4)
  set sourcePort($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourcePort() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourcePort() => $_clearField(4);
}

class DroIoPort extends $pb.GeneratedMessage {
  factory DroIoPort({
    $core.String? ioId,
    $core.String? deviceId,
    $core.String? portType,
    $core.Iterable<$core.int>? portNums,
  }) {
    final result = create();
    if (ioId != null) result.ioId = ioId;
    if (deviceId != null) result.deviceId = deviceId;
    if (portType != null) result.portType = portType;
    if (portNums != null) result.portNums.addAll(portNums);
    return result;
  }

  DroIoPort._();

  factory DroIoPort.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroIoPort.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroIoPort',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ioId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'portType')
    ..p<$core.int>(4, _omitFieldNames ? '' : 'portNums', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroIoPort clone() => DroIoPort()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroIoPort copyWith(void Function(DroIoPort) updates) =>
      super.copyWith((message) => updates(message as DroIoPort)) as DroIoPort;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroIoPort create() => DroIoPort._();
  @$core.override
  DroIoPort createEmptyInstance() => create();
  static $pb.PbList<DroIoPort> createRepeated() => $pb.PbList<DroIoPort>();
  @$core.pragma('dart2js:noInline')
  static DroIoPort getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DroIoPort>(create);
  static DroIoPort? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ioId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ioId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get portType => $_getSZ(2);
  @$pb.TagNumber(3)
  set portType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPortType() => $_has(2);
  @$pb.TagNumber(3)
  void clearPortType() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.int> get portNums => $_getList(3);
}

/// Latency is still provisional because no non-empty example was available in
/// the inspected configurator outputs. The shape will need refinement once a
/// real latency entry is mapped.
class DroLatency extends $pb.GeneratedMessage {
  factory DroLatency({
    $core.Iterable<$core.MapEntry<$core.String, $0.Value>>? values,
  }) {
    final result = create();
    if (values != null) result.values.addEntries(values);
    return result;
  }

  DroLatency._();

  factory DroLatency.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DroLatency.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DroLatency',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..m<$core.String, $0.Value>(1, _omitFieldNames ? '' : 'values',
        entryClassName: 'DroLatency.ValuesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: $0.Value.create,
        valueDefaultOrMaker: $0.Value.getDefault,
        packageName: const $pb.PackageName('fusion.deviceconfig.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroLatency clone() => DroLatency()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DroLatency copyWith(void Function(DroLatency) updates) =>
      super.copyWith((message) => updates(message as DroLatency)) as DroLatency;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DroLatency create() => DroLatency._();
  @$core.override
  DroLatency createEmptyInstance() => create();
  static $pb.PbList<DroLatency> createRepeated() => $pb.PbList<DroLatency>();
  @$core.pragma('dart2js:noInline')
  static DroLatency getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DroLatency>(create);
  static DroLatency? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $0.Value> get values => $_getMap(0);
}

class FusionConnectAudioStream extends $pb.GeneratedMessage {
  factory FusionConnectAudioStream({
    $core.String? sourceDeviceUid,
    $core.String? destDeviceUid,
    FusionConnectAudioStreamProperties? properties,
  }) {
    final result = create();
    if (sourceDeviceUid != null) result.sourceDeviceUid = sourceDeviceUid;
    if (destDeviceUid != null) result.destDeviceUid = destDeviceUid;
    if (properties != null) result.properties = properties;
    return result;
  }

  FusionConnectAudioStream._();

  factory FusionConnectAudioStream.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FusionConnectAudioStream.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FusionConnectAudioStream',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceDeviceUid')
    ..aOS(2, _omitFieldNames ? '' : 'destDeviceUid')
    ..aOM<FusionConnectAudioStreamProperties>(
        3, _omitFieldNames ? '' : 'properties',
        subBuilder: FusionConnectAudioStreamProperties.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAudioStream clone() =>
      FusionConnectAudioStream()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAudioStream copyWith(
          void Function(FusionConnectAudioStream) updates) =>
      super.copyWith((message) => updates(message as FusionConnectAudioStream))
          as FusionConnectAudioStream;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FusionConnectAudioStream create() => FusionConnectAudioStream._();
  @$core.override
  FusionConnectAudioStream createEmptyInstance() => create();
  static $pb.PbList<FusionConnectAudioStream> createRepeated() =>
      $pb.PbList<FusionConnectAudioStream>();
  @$core.pragma('dart2js:noInline')
  static FusionConnectAudioStream getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FusionConnectAudioStream>(create);
  static FusionConnectAudioStream? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceDeviceUid => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceDeviceUid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceDeviceUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceDeviceUid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get destDeviceUid => $_getSZ(1);
  @$pb.TagNumber(2)
  set destDeviceUid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDestDeviceUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestDeviceUid() => $_clearField(2);

  @$pb.TagNumber(3)
  FusionConnectAudioStreamProperties get properties => $_getN(2);
  @$pb.TagNumber(3)
  set properties(FusionConnectAudioStreamProperties value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProperties() => $_has(2);
  @$pb.TagNumber(3)
  void clearProperties() => $_clearField(3);
  @$pb.TagNumber(3)
  FusionConnectAudioStreamProperties ensureProperties() => $_ensure(2);
}

class FusionConnectAudioStreamProperties extends $pb.GeneratedMessage {
  factory FusionConnectAudioStreamProperties({
    $core.String? streamName,
    $core.String? destIp,
    $core.int? channels,
    $core.int? sourcePort,
    $core.bool? isSource,
    $core.bool? isFusionConnect,
  }) {
    final result = create();
    if (streamName != null) result.streamName = streamName;
    if (destIp != null) result.destIp = destIp;
    if (channels != null) result.channels = channels;
    if (sourcePort != null) result.sourcePort = sourcePort;
    if (isSource != null) result.isSource = isSource;
    if (isFusionConnect != null) result.isFusionConnect = isFusionConnect;
    return result;
  }

  FusionConnectAudioStreamProperties._();

  factory FusionConnectAudioStreamProperties.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FusionConnectAudioStreamProperties.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FusionConnectAudioStreamProperties',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'streamName')
    ..aOS(2, _omitFieldNames ? '' : 'destIp')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'channels', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'sourcePort', $pb.PbFieldType.OU3)
    ..aOB(5, _omitFieldNames ? '' : 'isSource')
    ..aOB(6, _omitFieldNames ? '' : 'isFusionConnect')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAudioStreamProperties clone() =>
      FusionConnectAudioStreamProperties()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAudioStreamProperties copyWith(
          void Function(FusionConnectAudioStreamProperties) updates) =>
      super.copyWith((message) =>
              updates(message as FusionConnectAudioStreamProperties))
          as FusionConnectAudioStreamProperties;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FusionConnectAudioStreamProperties create() =>
      FusionConnectAudioStreamProperties._();
  @$core.override
  FusionConnectAudioStreamProperties createEmptyInstance() => create();
  static $pb.PbList<FusionConnectAudioStreamProperties> createRepeated() =>
      $pb.PbList<FusionConnectAudioStreamProperties>();
  @$core.pragma('dart2js:noInline')
  static FusionConnectAudioStreamProperties getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FusionConnectAudioStreamProperties>(
          create);
  static FusionConnectAudioStreamProperties? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get streamName => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStreamName() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get destIp => $_getSZ(1);
  @$pb.TagNumber(2)
  set destIp($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDestIp() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestIp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get channels => $_getIZ(2);
  @$pb.TagNumber(3)
  set channels($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannels() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannels() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sourcePort => $_getIZ(3);
  @$pb.TagNumber(4)
  set sourcePort($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourcePort() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourcePort() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isSource => $_getBF(4);
  @$pb.TagNumber(5)
  set isSource($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsSource() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isFusionConnect => $_getBF(5);
  @$pb.TagNumber(6)
  set isFusionConnect($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsFusionConnect() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsFusionConnect() => $_clearField(6);
}

class FusionConnectAudioSettings extends $pb.GeneratedMessage {
  factory FusionConnectAudioSettings({
    $core.Iterable<$core.MapEntry<$core.String, AudioBlockSettings>>? audio,
  }) {
    final result = create();
    if (audio != null) result.audio.addEntries(audio);
    return result;
  }

  FusionConnectAudioSettings._();

  factory FusionConnectAudioSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FusionConnectAudioSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FusionConnectAudioSettings',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..m<$core.String, AudioBlockSettings>(1, _omitFieldNames ? '' : 'audio',
        entryClassName: 'FusionConnectAudioSettings.AudioEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: AudioBlockSettings.create,
        valueDefaultOrMaker: AudioBlockSettings.getDefault,
        packageName: const $pb.PackageName('fusion.deviceconfig.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAudioSettings clone() =>
      FusionConnectAudioSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FusionConnectAudioSettings copyWith(
          void Function(FusionConnectAudioSettings) updates) =>
      super.copyWith(
              (message) => updates(message as FusionConnectAudioSettings))
          as FusionConnectAudioSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FusionConnectAudioSettings create() => FusionConnectAudioSettings._();
  @$core.override
  FusionConnectAudioSettings createEmptyInstance() => create();
  static $pb.PbList<FusionConnectAudioSettings> createRepeated() =>
      $pb.PbList<FusionConnectAudioSettings>();
  @$core.pragma('dart2js:noInline')
  static FusionConnectAudioSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FusionConnectAudioSettings>(create);
  static FusionConnectAudioSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, AudioBlockSettings> get audio => $_getMap(0);
}

class AudioBlockSettings extends $pb.GeneratedMessage {
  factory AudioBlockSettings({
    $core.Iterable<$core.MapEntry<$core.String, $0.Value>>? parameters,
  }) {
    final result = create();
    if (parameters != null) result.parameters.addEntries(parameters);
    return result;
  }

  AudioBlockSettings._();

  factory AudioBlockSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioBlockSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioBlockSettings',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..m<$core.String, $0.Value>(1, _omitFieldNames ? '' : 'parameters',
        entryClassName: 'AudioBlockSettings.ParametersEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: $0.Value.create,
        valueDefaultOrMaker: $0.Value.getDefault,
        packageName: const $pb.PackageName('fusion.deviceconfig.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioBlockSettings clone() => AudioBlockSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioBlockSettings copyWith(void Function(AudioBlockSettings) updates) =>
      super.copyWith((message) => updates(message as AudioBlockSettings))
          as AudioBlockSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioBlockSettings create() => AudioBlockSettings._();
  @$core.override
  AudioBlockSettings createEmptyInstance() => create();
  static $pb.PbList<AudioBlockSettings> createRepeated() =>
      $pb.PbList<AudioBlockSettings>();
  @$core.pragma('dart2js:noInline')
  static AudioBlockSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioBlockSettings>(create);
  static AudioBlockSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $0.Value> get parameters => $_getMap(0);
}

/// StaticConfiguration mirrors the conditioned DSP output shape currently stored
/// under result.devices[*].dsp_static_config.
class StaticConfiguration extends $pb.GeneratedMessage {
  factory StaticConfiguration({
    SessionConfiguration? session,
    $core.Iterable<AudioTask>? audioTasks,
    $core.Iterable<TaskConnection>? taskConnections,
    $core.Iterable<ParameterSetting>? parameterSettings,
  }) {
    final result = create();
    if (session != null) result.session = session;
    if (audioTasks != null) result.audioTasks.addAll(audioTasks);
    if (taskConnections != null) result.taskConnections.addAll(taskConnections);
    if (parameterSettings != null)
      result.parameterSettings.addAll(parameterSettings);
    return result;
  }

  StaticConfiguration._();

  factory StaticConfiguration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StaticConfiguration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StaticConfiguration',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOM<SessionConfiguration>(1, _omitFieldNames ? '' : 'session',
        subBuilder: SessionConfiguration.create)
    ..pc<AudioTask>(2, _omitFieldNames ? '' : 'audioTasks', $pb.PbFieldType.PM,
        subBuilder: AudioTask.create)
    ..pc<TaskConnection>(
        3, _omitFieldNames ? '' : 'taskConnections', $pb.PbFieldType.PM,
        subBuilder: TaskConnection.create)
    ..pc<ParameterSetting>(
        4, _omitFieldNames ? '' : 'parameterSettings', $pb.PbFieldType.PM,
        subBuilder: ParameterSetting.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StaticConfiguration clone() => StaticConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StaticConfiguration copyWith(void Function(StaticConfiguration) updates) =>
      super.copyWith((message) => updates(message as StaticConfiguration))
          as StaticConfiguration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StaticConfiguration create() => StaticConfiguration._();
  @$core.override
  StaticConfiguration createEmptyInstance() => create();
  static $pb.PbList<StaticConfiguration> createRepeated() =>
      $pb.PbList<StaticConfiguration>();
  @$core.pragma('dart2js:noInline')
  static StaticConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StaticConfiguration>(create);
  static StaticConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  SessionConfiguration get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(SessionConfiguration value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionConfiguration ensureSession() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<AudioTask> get audioTasks => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<TaskConnection> get taskConnections => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<ParameterSetting> get parameterSettings => $_getList(3);
}

class SessionConfiguration extends $pb.GeneratedMessage {
  factory SessionConfiguration({
    $core.Iterable<PropertySetting>? propertySettings,
  }) {
    final result = create();
    if (propertySettings != null)
      result.propertySettings.addAll(propertySettings);
    return result;
  }

  SessionConfiguration._();

  factory SessionConfiguration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionConfiguration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionConfiguration',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..pc<PropertySetting>(
        1, _omitFieldNames ? '' : 'propertySettings', $pb.PbFieldType.PM,
        subBuilder: PropertySetting.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionConfiguration clone() =>
      SessionConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionConfiguration copyWith(void Function(SessionConfiguration) updates) =>
      super.copyWith((message) => updates(message as SessionConfiguration))
          as SessionConfiguration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionConfiguration create() => SessionConfiguration._();
  @$core.override
  SessionConfiguration createEmptyInstance() => create();
  static $pb.PbList<SessionConfiguration> createRepeated() =>
      $pb.PbList<SessionConfiguration>();
  @$core.pragma('dart2js:noInline')
  static SessionConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionConfiguration>(create);
  static SessionConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PropertySetting> get propertySettings => $_getList(0);
}

class AudioTask extends $pb.GeneratedMessage {
  factory AudioTask({
    $core.String? name,
    $core.Iterable<PropertySetting>? propertySettings,
    $core.Iterable<Block>? blocks,
    $core.Iterable<BlockConnection>? blockConnections,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (propertySettings != null)
      result.propertySettings.addAll(propertySettings);
    if (blocks != null) result.blocks.addAll(blocks);
    if (blockConnections != null)
      result.blockConnections.addAll(blockConnections);
    return result;
  }

  AudioTask._();

  factory AudioTask.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioTask.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioTask',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pc<PropertySetting>(
        2, _omitFieldNames ? '' : 'propertySettings', $pb.PbFieldType.PM,
        subBuilder: PropertySetting.create)
    ..pc<Block>(3, _omitFieldNames ? '' : 'blocks', $pb.PbFieldType.PM,
        subBuilder: Block.create)
    ..pc<BlockConnection>(
        4, _omitFieldNames ? '' : 'blockConnections', $pb.PbFieldType.PM,
        subBuilder: BlockConnection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTask clone() => AudioTask()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTask copyWith(void Function(AudioTask) updates) =>
      super.copyWith((message) => updates(message as AudioTask)) as AudioTask;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioTask create() => AudioTask._();
  @$core.override
  AudioTask createEmptyInstance() => create();
  static $pb.PbList<AudioTask> createRepeated() => $pb.PbList<AudioTask>();
  @$core.pragma('dart2js:noInline')
  static AudioTask getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioTask>(create);
  static AudioTask? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<PropertySetting> get propertySettings => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<Block> get blocks => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<BlockConnection> get blockConnections => $_getList(3);
}

class Block extends $pb.GeneratedMessage {
  factory Block({
    $core.String? name,
    $core.String? algorithm,
    $core.Iterable<PropertySetting>? propertySettings,
    $core.Iterable<TerminalChannels>? terminalChannels,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (algorithm != null) result.algorithm = algorithm;
    if (propertySettings != null)
      result.propertySettings.addAll(propertySettings);
    if (terminalChannels != null)
      result.terminalChannels.addAll(terminalChannels);
    return result;
  }

  Block._();

  factory Block.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Block.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Block',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'algorithm')
    ..pc<PropertySetting>(
        3, _omitFieldNames ? '' : 'propertySettings', $pb.PbFieldType.PM,
        subBuilder: PropertySetting.create)
    ..pc<TerminalChannels>(
        4, _omitFieldNames ? '' : 'terminalChannels', $pb.PbFieldType.PM,
        subBuilder: TerminalChannels.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Block clone() => Block()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Block copyWith(void Function(Block) updates) =>
      super.copyWith((message) => updates(message as Block)) as Block;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Block create() => Block._();
  @$core.override
  Block createEmptyInstance() => create();
  static $pb.PbList<Block> createRepeated() => $pb.PbList<Block>();
  @$core.pragma('dart2js:noInline')
  static Block getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Block>(create);
  static Block? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get algorithm => $_getSZ(1);
  @$pb.TagNumber(2)
  set algorithm($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlgorithm() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlgorithm() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<PropertySetting> get propertySettings => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<TerminalChannels> get terminalChannels => $_getList(3);
}

class PropertySetting extends $pb.GeneratedMessage {
  factory PropertySetting({
    $core.String? name,
    $0.Value? value,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (value != null) result.value = value;
    return result;
  }

  PropertySetting._();

  factory PropertySetting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PropertySetting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PropertySetting',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Value>(2, _omitFieldNames ? '' : 'value',
        subBuilder: $0.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PropertySetting clone() => PropertySetting()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PropertySetting copyWith(void Function(PropertySetting) updates) =>
      super.copyWith((message) => updates(message as PropertySetting))
          as PropertySetting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PropertySetting create() => PropertySetting._();
  @$core.override
  PropertySetting createEmptyInstance() => create();
  static $pb.PbList<PropertySetting> createRepeated() =>
      $pb.PbList<PropertySetting>();
  @$core.pragma('dart2js:noInline')
  static PropertySetting getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PropertySetting>(create);
  static PropertySetting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Value get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($0.Value value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Value ensureValue() => $_ensure(1);
}

class TerminalChannels extends $pb.GeneratedMessage {
  factory TerminalChannels({
    $core.String? name,
    $core.int? channels,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (channels != null) result.channels = channels;
    return result;
  }

  TerminalChannels._();

  factory TerminalChannels.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TerminalChannels.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TerminalChannels',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'channels', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TerminalChannels clone() => TerminalChannels()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TerminalChannels copyWith(void Function(TerminalChannels) updates) =>
      super.copyWith((message) => updates(message as TerminalChannels))
          as TerminalChannels;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TerminalChannels create() => TerminalChannels._();
  @$core.override
  TerminalChannels createEmptyInstance() => create();
  static $pb.PbList<TerminalChannels> createRepeated() =>
      $pb.PbList<TerminalChannels>();
  @$core.pragma('dart2js:noInline')
  static TerminalChannels getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TerminalChannels>(create);
  static TerminalChannels? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get channels => $_getIZ(1);
  @$pb.TagNumber(2)
  set channels($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannels() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannels() => $_clearField(2);
}

class BlockConnection extends $pb.GeneratedMessage {
  factory BlockConnection({
    $core.String? sourceBlock,
    $core.String? outputTerminal,
    $core.int? outputChannel,
    $core.String? destinationBlock,
    $core.String? inputTerminal,
    $core.int? inputChannel,
  }) {
    final result = create();
    if (sourceBlock != null) result.sourceBlock = sourceBlock;
    if (outputTerminal != null) result.outputTerminal = outputTerminal;
    if (outputChannel != null) result.outputChannel = outputChannel;
    if (destinationBlock != null) result.destinationBlock = destinationBlock;
    if (inputTerminal != null) result.inputTerminal = inputTerminal;
    if (inputChannel != null) result.inputChannel = inputChannel;
    return result;
  }

  BlockConnection._();

  factory BlockConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BlockConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BlockConnection',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceBlock')
    ..aOS(2, _omitFieldNames ? '' : 'outputTerminal')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'outputChannel', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'destinationBlock')
    ..aOS(5, _omitFieldNames ? '' : 'inputTerminal')
    ..a<$core.int>(
        6, _omitFieldNames ? '' : 'inputChannel', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlockConnection clone() => BlockConnection()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlockConnection copyWith(void Function(BlockConnection) updates) =>
      super.copyWith((message) => updates(message as BlockConnection))
          as BlockConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlockConnection create() => BlockConnection._();
  @$core.override
  BlockConnection createEmptyInstance() => create();
  static $pb.PbList<BlockConnection> createRepeated() =>
      $pb.PbList<BlockConnection>();
  @$core.pragma('dart2js:noInline')
  static BlockConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BlockConnection>(create);
  static BlockConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceBlock => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceBlock($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceBlock() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceBlock() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get outputTerminal => $_getSZ(1);
  @$pb.TagNumber(2)
  set outputTerminal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutputTerminal() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutputTerminal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get outputChannel => $_getIZ(2);
  @$pb.TagNumber(3)
  set outputChannel($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOutputChannel() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputChannel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get destinationBlock => $_getSZ(3);
  @$pb.TagNumber(4)
  set destinationBlock($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDestinationBlock() => $_has(3);
  @$pb.TagNumber(4)
  void clearDestinationBlock() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get inputTerminal => $_getSZ(4);
  @$pb.TagNumber(5)
  set inputTerminal($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInputTerminal() => $_has(4);
  @$pb.TagNumber(5)
  void clearInputTerminal() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get inputChannel => $_getIZ(5);
  @$pb.TagNumber(6)
  set inputChannel($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasInputChannel() => $_has(5);
  @$pb.TagNumber(6)
  void clearInputChannel() => $_clearField(6);
}

class TaskConnection extends $pb.GeneratedMessage {
  factory TaskConnection({
    $core.String? sourceTask,
    $core.String? outputBlock,
    $core.int? outputChannel,
    $core.String? destinationTask,
    $core.String? inputBlock,
    $core.int? inputChannel,
  }) {
    final result = create();
    if (sourceTask != null) result.sourceTask = sourceTask;
    if (outputBlock != null) result.outputBlock = outputBlock;
    if (outputChannel != null) result.outputChannel = outputChannel;
    if (destinationTask != null) result.destinationTask = destinationTask;
    if (inputBlock != null) result.inputBlock = inputBlock;
    if (inputChannel != null) result.inputChannel = inputChannel;
    return result;
  }

  TaskConnection._();

  factory TaskConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskConnection',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceTask')
    ..aOS(2, _omitFieldNames ? '' : 'outputBlock')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'outputChannel', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'destinationTask')
    ..aOS(5, _omitFieldNames ? '' : 'inputBlock')
    ..a<$core.int>(
        6, _omitFieldNames ? '' : 'inputChannel', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskConnection clone() => TaskConnection()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskConnection copyWith(void Function(TaskConnection) updates) =>
      super.copyWith((message) => updates(message as TaskConnection))
          as TaskConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskConnection create() => TaskConnection._();
  @$core.override
  TaskConnection createEmptyInstance() => create();
  static $pb.PbList<TaskConnection> createRepeated() =>
      $pb.PbList<TaskConnection>();
  @$core.pragma('dart2js:noInline')
  static TaskConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskConnection>(create);
  static TaskConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceTask => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceTask($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceTask() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceTask() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get outputBlock => $_getSZ(1);
  @$pb.TagNumber(2)
  set outputBlock($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutputBlock() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutputBlock() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get outputChannel => $_getIZ(2);
  @$pb.TagNumber(3)
  set outputChannel($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOutputChannel() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputChannel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get destinationTask => $_getSZ(3);
  @$pb.TagNumber(4)
  set destinationTask($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDestinationTask() => $_has(3);
  @$pb.TagNumber(4)
  void clearDestinationTask() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get inputBlock => $_getSZ(4);
  @$pb.TagNumber(5)
  set inputBlock($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInputBlock() => $_has(4);
  @$pb.TagNumber(5)
  void clearInputBlock() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get inputChannel => $_getIZ(5);
  @$pb.TagNumber(6)
  set inputChannel($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasInputChannel() => $_has(5);
  @$pb.TagNumber(6)
  void clearInputChannel() => $_clearField(6);
}

class ParameterSetting extends $pb.GeneratedMessage {
  factory ParameterSetting({
    $core.String? target,
    $core.String? name,
    $core.Iterable<$core.int>? index,
    $0.Value? value,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (name != null) result.name = name;
    if (index != null) result.index.addAll(index);
    if (value != null) result.value = value;
    return result;
  }

  ParameterSetting._();

  factory ParameterSetting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParameterSetting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParameterSetting',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.deviceconfig.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'target')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..p<$core.int>(3, _omitFieldNames ? '' : 'index', $pb.PbFieldType.KU3)
    ..aOM<$0.Value>(4, _omitFieldNames ? '' : 'value',
        subBuilder: $0.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParameterSetting clone() => ParameterSetting()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParameterSetting copyWith(void Function(ParameterSetting) updates) =>
      super.copyWith((message) => updates(message as ParameterSetting))
          as ParameterSetting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParameterSetting create() => ParameterSetting._();
  @$core.override
  ParameterSetting createEmptyInstance() => create();
  static $pb.PbList<ParameterSetting> createRepeated() =>
      $pb.PbList<ParameterSetting>();
  @$core.pragma('dart2js:noInline')
  static ParameterSetting getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParameterSetting>(create);
  static ParameterSetting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get target => $_getSZ(0);
  @$pb.TagNumber(1)
  set target($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.int> get index => $_getList(2);

  @$pb.TagNumber(4)
  $0.Value get value => $_getN(3);
  @$pb.TagNumber(4)
  set value($0.Value value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Value ensureValue() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
