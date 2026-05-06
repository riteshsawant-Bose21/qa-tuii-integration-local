// This is a generated file - do not edit.
//
// Generated from fusion/software_update.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/timestamp.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SoftwareUpdateBundle extends $pb.GeneratedMessage {
  factory SoftwareUpdateBundle({
    $core.String? filename,
    $core.String? checksum,
    $fixnum.Int64? sizeBytes,
    $0.Timestamp? uploaded,
    $core.String? sourceIp,
    $core.String? syncId,
  }) {
    final result = create();
    if (filename != null) result.filename = filename;
    if (checksum != null) result.checksum = checksum;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (uploaded != null) result.uploaded = uploaded;
    if (sourceIp != null) result.sourceIp = sourceIp;
    if (syncId != null) result.syncId = syncId;
    return result;
  }

  SoftwareUpdateBundle._();

  factory SoftwareUpdateBundle.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SoftwareUpdateBundle.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SoftwareUpdateBundle',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.softwareupdate.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..aOS(2, _omitFieldNames ? '' : 'checksum')
    ..aInt64(3, _omitFieldNames ? '' : 'sizeBytes')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'uploaded',
        subBuilder: $0.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'sourceIp')
    ..aOS(6, _omitFieldNames ? '' : 'syncId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateBundle clone() =>
      SoftwareUpdateBundle()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateBundle copyWith(void Function(SoftwareUpdateBundle) updates) =>
      super.copyWith((message) => updates(message as SoftwareUpdateBundle))
          as SoftwareUpdateBundle;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateBundle create() => SoftwareUpdateBundle._();
  @$core.override
  SoftwareUpdateBundle createEmptyInstance() => create();
  static $pb.PbList<SoftwareUpdateBundle> createRepeated() =>
      $pb.PbList<SoftwareUpdateBundle>();
  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateBundle getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SoftwareUpdateBundle>(create);
  static SoftwareUpdateBundle? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get checksum => $_getSZ(1);
  @$pb.TagNumber(2)
  set checksum($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChecksum() => $_has(1);
  @$pb.TagNumber(2)
  void clearChecksum() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get uploaded => $_getN(3);
  @$pb.TagNumber(4)
  set uploaded($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUploaded() => $_has(3);
  @$pb.TagNumber(4)
  void clearUploaded() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureUploaded() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get sourceIp => $_getSZ(4);
  @$pb.TagNumber(5)
  set sourceIp($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSourceIp() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourceIp() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get syncId => $_getSZ(5);
  @$pb.TagNumber(6)
  set syncId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSyncId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSyncId() => $_clearField(6);
}

class SoftwareUpdateUploadResponse extends $pb.GeneratedMessage {
  factory SoftwareUpdateUploadResponse({
    $core.String? filename,
    $core.String? checksum,
    $fixnum.Int64? sizeBytes,
    $0.Timestamp? uploaded,
  }) {
    final result = create();
    if (filename != null) result.filename = filename;
    if (checksum != null) result.checksum = checksum;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (uploaded != null) result.uploaded = uploaded;
    return result;
  }

  SoftwareUpdateUploadResponse._();

  factory SoftwareUpdateUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SoftwareUpdateUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SoftwareUpdateUploadResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.softwareupdate.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..aOS(2, _omitFieldNames ? '' : 'checksum')
    ..aInt64(3, _omitFieldNames ? '' : 'sizeBytes')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'uploaded',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateUploadResponse clone() =>
      SoftwareUpdateUploadResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateUploadResponse copyWith(
          void Function(SoftwareUpdateUploadResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SoftwareUpdateUploadResponse))
          as SoftwareUpdateUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateUploadResponse create() =>
      SoftwareUpdateUploadResponse._();
  @$core.override
  SoftwareUpdateUploadResponse createEmptyInstance() => create();
  static $pb.PbList<SoftwareUpdateUploadResponse> createRepeated() =>
      $pb.PbList<SoftwareUpdateUploadResponse>();
  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SoftwareUpdateUploadResponse>(create);
  static SoftwareUpdateUploadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get checksum => $_getSZ(1);
  @$pb.TagNumber(2)
  set checksum($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChecksum() => $_has(1);
  @$pb.TagNumber(2)
  void clearChecksum() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get uploaded => $_getN(3);
  @$pb.TagNumber(4)
  set uploaded($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUploaded() => $_has(3);
  @$pb.TagNumber(4)
  void clearUploaded() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureUploaded() => $_ensure(3);
}

class SoftwareUpdateListResponse extends $pb.GeneratedMessage {
  factory SoftwareUpdateListResponse({
    $core.Iterable<SoftwareUpdateBundle>? bundles,
  }) {
    final result = create();
    if (bundles != null) result.bundles.addAll(bundles);
    return result;
  }

  SoftwareUpdateListResponse._();

  factory SoftwareUpdateListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SoftwareUpdateListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SoftwareUpdateListResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.softwareupdate.v1'),
      createEmptyInstance: create)
    ..pc<SoftwareUpdateBundle>(
        1, _omitFieldNames ? '' : 'bundles', $pb.PbFieldType.PM,
        subBuilder: SoftwareUpdateBundle.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateListResponse clone() =>
      SoftwareUpdateListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateListResponse copyWith(
          void Function(SoftwareUpdateListResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SoftwareUpdateListResponse))
          as SoftwareUpdateListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateListResponse create() => SoftwareUpdateListResponse._();
  @$core.override
  SoftwareUpdateListResponse createEmptyInstance() => create();
  static $pb.PbList<SoftwareUpdateListResponse> createRepeated() =>
      $pb.PbList<SoftwareUpdateListResponse>();
  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SoftwareUpdateListResponse>(create);
  static SoftwareUpdateListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SoftwareUpdateBundle> get bundles => $_getList(0);
}

class SoftwareUpdateErrorResponse extends $pb.GeneratedMessage {
  factory SoftwareUpdateErrorResponse({
    $core.String? error,
    $core.String? message,
  }) {
    final result = create();
    if (error != null) result.error = error;
    if (message != null) result.message = message;
    return result;
  }

  SoftwareUpdateErrorResponse._();

  factory SoftwareUpdateErrorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SoftwareUpdateErrorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SoftwareUpdateErrorResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.softwareupdate.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'error')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateErrorResponse clone() =>
      SoftwareUpdateErrorResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoftwareUpdateErrorResponse copyWith(
          void Function(SoftwareUpdateErrorResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SoftwareUpdateErrorResponse))
          as SoftwareUpdateErrorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateErrorResponse create() =>
      SoftwareUpdateErrorResponse._();
  @$core.override
  SoftwareUpdateErrorResponse createEmptyInstance() => create();
  static $pb.PbList<SoftwareUpdateErrorResponse> createRepeated() =>
      $pb.PbList<SoftwareUpdateErrorResponse>();
  @$core.pragma('dart2js:noInline')
  static SoftwareUpdateErrorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SoftwareUpdateErrorResponse>(create);
  static SoftwareUpdateErrorResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get error => $_getSZ(0);
  @$pb.TagNumber(1)
  set error($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class SwUpdateInfo extends $pb.GeneratedMessage {
  factory SwUpdateInfo({
    $core.String? serialNumber,
    $core.String? currentBundleVersion,
    $core.String? previousBundleVersion,
    $core.String? mount,
    $core.String? previousMount,
    $core.String? status,
    $core.String? currentState,
    $core.String? bootPartition,
    $core.String? previousBootPartition,
    $core.String? error,
    $core.String? updatedAt,
  }) {
    final result = create();
    if (serialNumber != null) result.serialNumber = serialNumber;
    if (currentBundleVersion != null)
      result.currentBundleVersion = currentBundleVersion;
    if (previousBundleVersion != null)
      result.previousBundleVersion = previousBundleVersion;
    if (mount != null) result.mount = mount;
    if (previousMount != null) result.previousMount = previousMount;
    if (status != null) result.status = status;
    if (currentState != null) result.currentState = currentState;
    if (bootPartition != null) result.bootPartition = bootPartition;
    if (previousBootPartition != null)
      result.previousBootPartition = previousBootPartition;
    if (error != null) result.error = error;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  SwUpdateInfo._();

  factory SwUpdateInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SwUpdateInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SwUpdateInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.softwareupdate.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serialNumber')
    ..aOS(2, _omitFieldNames ? '' : 'currentBundleVersion')
    ..aOS(3, _omitFieldNames ? '' : 'previousBundleVersion')
    ..aOS(4, _omitFieldNames ? '' : 'mount')
    ..aOS(5, _omitFieldNames ? '' : 'previousMount')
    ..aOS(6, _omitFieldNames ? '' : 'status')
    ..aOS(7, _omitFieldNames ? '' : 'currentState')
    ..aOS(8, _omitFieldNames ? '' : 'bootPartition')
    ..aOS(9, _omitFieldNames ? '' : 'previousBootPartition')
    ..aOS(10, _omitFieldNames ? '' : 'error')
    ..aOS(11, _omitFieldNames ? '' : 'updatedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwUpdateInfo clone() => SwUpdateInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwUpdateInfo copyWith(void Function(SwUpdateInfo) updates) =>
      super.copyWith((message) => updates(message as SwUpdateInfo))
          as SwUpdateInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SwUpdateInfo create() => SwUpdateInfo._();
  @$core.override
  SwUpdateInfo createEmptyInstance() => create();
  static $pb.PbList<SwUpdateInfo> createRepeated() =>
      $pb.PbList<SwUpdateInfo>();
  @$core.pragma('dart2js:noInline')
  static SwUpdateInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SwUpdateInfo>(create);
  static SwUpdateInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serialNumber => $_getSZ(0);
  @$pb.TagNumber(1)
  set serialNumber($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSerialNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearSerialNumber() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get currentBundleVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set currentBundleVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrentBundleVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrentBundleVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get previousBundleVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set previousBundleVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreviousBundleVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreviousBundleVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mount => $_getSZ(3);
  @$pb.TagNumber(4)
  set mount($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMount() => $_has(3);
  @$pb.TagNumber(4)
  void clearMount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get previousMount => $_getSZ(4);
  @$pb.TagNumber(5)
  set previousMount($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPreviousMount() => $_has(4);
  @$pb.TagNumber(5)
  void clearPreviousMount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get status => $_getSZ(5);
  @$pb.TagNumber(6)
  set status($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get currentState => $_getSZ(6);
  @$pb.TagNumber(7)
  set currentState($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrentState() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrentState() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get bootPartition => $_getSZ(7);
  @$pb.TagNumber(8)
  set bootPartition($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBootPartition() => $_has(7);
  @$pb.TagNumber(8)
  void clearBootPartition() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get previousBootPartition => $_getSZ(8);
  @$pb.TagNumber(9)
  set previousBootPartition($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPreviousBootPartition() => $_has(8);
  @$pb.TagNumber(9)
  void clearPreviousBootPartition() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get error => $_getSZ(9);
  @$pb.TagNumber(10)
  set error($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasError() => $_has(9);
  @$pb.TagNumber(10)
  void clearError() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get updatedAt => $_getSZ(10);
  @$pb.TagNumber(11)
  set updatedAt($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasUpdatedAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearUpdatedAt() => $_clearField(11);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
