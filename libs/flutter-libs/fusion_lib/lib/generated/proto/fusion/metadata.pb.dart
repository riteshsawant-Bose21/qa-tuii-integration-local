// This is a generated file - do not edit.
//
// Generated from fusion/metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class VersionInfo extends $pb.GeneratedMessage {
  factory VersionInfo({
    $fixnum.Int64? epoch,
    $fixnum.Int64? counter,
    $core.String? nodeId,
  }) {
    final result = create();
    if (epoch != null) result.epoch = epoch;
    if (counter != null) result.counter = counter;
    if (nodeId != null) result.nodeId = nodeId;
    return result;
  }

  VersionInfo._();

  factory VersionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VersionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.metadata.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'epoch', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'counter', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'nodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionInfo clone() => VersionInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionInfo copyWith(void Function(VersionInfo) updates) =>
      super.copyWith((message) => updates(message as VersionInfo))
          as VersionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VersionInfo create() => VersionInfo._();
  @$core.override
  VersionInfo createEmptyInstance() => create();
  static $pb.PbList<VersionInfo> createRepeated() => $pb.PbList<VersionInfo>();
  @$core.pragma('dart2js:noInline')
  static VersionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VersionInfo>(create);
  static VersionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get epoch => $_getI64(0);
  @$pb.TagNumber(1)
  set epoch($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpoch() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpoch() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get counter => $_getI64(1);
  @$pb.TagNumber(2)
  set counter($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCounter() => $_has(1);
  @$pb.TagNumber(2)
  void clearCounter() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set nodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNodeId() => $_clearField(3);
}

class DatabaseMetadata extends $pb.GeneratedMessage {
  factory DatabaseMetadata({
    VersionInfo? version,
    $core.String? activeSnapshot,
    $core.String? hash,
    $core.bool? valid,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (activeSnapshot != null) result.activeSnapshot = activeSnapshot;
    if (hash != null) result.hash = hash;
    if (valid != null) result.valid = valid;
    return result;
  }

  DatabaseMetadata._();

  factory DatabaseMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DatabaseMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DatabaseMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.metadata.v1'),
      createEmptyInstance: create)
    ..aOM<VersionInfo>(1, _omitFieldNames ? '' : 'version',
        subBuilder: VersionInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'activeSnapshot')
    ..aOS(3, _omitFieldNames ? '' : 'hash')
    ..aOB(4, _omitFieldNames ? '' : 'valid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DatabaseMetadata clone() => DatabaseMetadata()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DatabaseMetadata copyWith(void Function(DatabaseMetadata) updates) =>
      super.copyWith((message) => updates(message as DatabaseMetadata))
          as DatabaseMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DatabaseMetadata create() => DatabaseMetadata._();
  @$core.override
  DatabaseMetadata createEmptyInstance() => create();
  static $pb.PbList<DatabaseMetadata> createRepeated() =>
      $pb.PbList<DatabaseMetadata>();
  @$core.pragma('dart2js:noInline')
  static DatabaseMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DatabaseMetadata>(create);
  static DatabaseMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  VersionInfo get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(VersionInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  VersionInfo ensureVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get activeSnapshot => $_getSZ(1);
  @$pb.TagNumber(2)
  set activeSnapshot($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActiveSnapshot() => $_has(1);
  @$pb.TagNumber(2)
  void clearActiveSnapshot() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hash => $_getSZ(2);
  @$pb.TagNumber(3)
  set hash($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHash() => $_has(2);
  @$pb.TagNumber(3)
  void clearHash() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get valid => $_getBF(3);
  @$pb.TagNumber(4)
  set valid($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasValid() => $_has(3);
  @$pb.TagNumber(4)
  void clearValid() => $_clearField(4);
}

class DatabaseMetadataResponse extends $pb.GeneratedMessage {
  factory DatabaseMetadataResponse({
    DatabaseMetadata? metadata,
  }) {
    final result = create();
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  DatabaseMetadataResponse._();

  factory DatabaseMetadataResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DatabaseMetadataResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DatabaseMetadataResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.metadata.v1'),
      createEmptyInstance: create)
    ..aOM<DatabaseMetadata>(1, _omitFieldNames ? '' : 'metadata',
        subBuilder: DatabaseMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DatabaseMetadataResponse clone() =>
      DatabaseMetadataResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DatabaseMetadataResponse copyWith(
          void Function(DatabaseMetadataResponse) updates) =>
      super.copyWith((message) => updates(message as DatabaseMetadataResponse))
          as DatabaseMetadataResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DatabaseMetadataResponse create() => DatabaseMetadataResponse._();
  @$core.override
  DatabaseMetadataResponse createEmptyInstance() => create();
  static $pb.PbList<DatabaseMetadataResponse> createRepeated() =>
      $pb.PbList<DatabaseMetadataResponse>();
  @$core.pragma('dart2js:noInline')
  static DatabaseMetadataResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DatabaseMetadataResponse>(create);
  static DatabaseMetadataResponse? _defaultInstance;

  @$pb.TagNumber(1)
  DatabaseMetadata get metadata => $_getN(0);
  @$pb.TagNumber(1)
  set metadata(DatabaseMetadata value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMetadata() => $_has(0);
  @$pb.TagNumber(1)
  void clearMetadata() => $_clearField(1);
  @$pb.TagNumber(1)
  DatabaseMetadata ensureMetadata() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
