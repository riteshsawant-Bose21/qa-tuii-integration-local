// This is a generated file - do not edit.
//
// Generated from fusion/version.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class EndpointListResponse extends $pb.GeneratedMessage {
  factory EndpointListResponse({
    $core.Iterable<$core.String>? routes,
  }) {
    final result = create();
    if (routes != null) result.routes.addAll(routes);
    return result;
  }

  EndpointListResponse._();

  factory EndpointListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EndpointListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EndpointListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'routes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndpointListResponse clone() =>
      EndpointListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndpointListResponse copyWith(void Function(EndpointListResponse) updates) =>
      super.copyWith((message) => updates(message as EndpointListResponse))
          as EndpointListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EndpointListResponse create() => EndpointListResponse._();
  @$core.override
  EndpointListResponse createEmptyInstance() => create();
  static $pb.PbList<EndpointListResponse> createRepeated() =>
      $pb.PbList<EndpointListResponse>();
  @$core.pragma('dart2js:noInline')
  static EndpointListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EndpointListResponse>(create);
  static EndpointListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get routes => $_getList(0);
}

class ServerInfoResponse extends $pb.GeneratedMessage {
  factory ServerInfoResponse({
    $core.String? name,
    $core.String? version,
    $core.String? commit,
    $core.String? buildTime,
    $core.String? nodeId,
    $core.Iterable<$core.String>? endpoints,
    $core.int? clusterSize,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (commit != null) result.commit = commit;
    if (buildTime != null) result.buildTime = buildTime;
    if (nodeId != null) result.nodeId = nodeId;
    if (endpoints != null) result.endpoints.addAll(endpoints);
    if (clusterSize != null) result.clusterSize = clusterSize;
    return result;
  }

  ServerInfoResponse._();

  factory ServerInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'commit')
    ..aOS(4, _omitFieldNames ? '' : 'buildTime')
    ..aOS(5, _omitFieldNames ? '' : 'nodeId')
    ..pPS(6, _omitFieldNames ? '' : 'endpoints')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'clusterSize', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerInfoResponse clone() => ServerInfoResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerInfoResponse copyWith(void Function(ServerInfoResponse) updates) =>
      super.copyWith((message) => updates(message as ServerInfoResponse))
          as ServerInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerInfoResponse create() => ServerInfoResponse._();
  @$core.override
  ServerInfoResponse createEmptyInstance() => create();
  static $pb.PbList<ServerInfoResponse> createRepeated() =>
      $pb.PbList<ServerInfoResponse>();
  @$core.pragma('dart2js:noInline')
  static ServerInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerInfoResponse>(create);
  static ServerInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get commit => $_getSZ(2);
  @$pb.TagNumber(3)
  set commit($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommit() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get buildTime => $_getSZ(3);
  @$pb.TagNumber(4)
  set buildTime($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBuildTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearBuildTime() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nodeId => $_getSZ(4);
  @$pb.TagNumber(5)
  set nodeId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNodeId() => $_has(4);
  @$pb.TagNumber(5)
  void clearNodeId() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get endpoints => $_getList(5);

  @$pb.TagNumber(7)
  $core.int get clusterSize => $_getIZ(6);
  @$pb.TagNumber(7)
  set clusterSize($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasClusterSize() => $_has(6);
  @$pb.TagNumber(7)
  void clearClusterSize() => $_clearField(7);
}

class VersionResponse extends $pb.GeneratedMessage {
  factory VersionResponse({
    $core.String? name,
    $core.String? version,
    $core.String? commit,
    $core.String? buildTime,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (commit != null) result.commit = commit;
    if (buildTime != null) result.buildTime = buildTime;
    return result;
  }

  VersionResponse._();

  factory VersionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VersionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'commit')
    ..aOS(4, _omitFieldNames ? '' : 'buildTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse clone() => VersionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse copyWith(void Function(VersionResponse) updates) =>
      super.copyWith((message) => updates(message as VersionResponse))
          as VersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VersionResponse create() => VersionResponse._();
  @$core.override
  VersionResponse createEmptyInstance() => create();
  static $pb.PbList<VersionResponse> createRepeated() =>
      $pb.PbList<VersionResponse>();
  @$core.pragma('dart2js:noInline')
  static VersionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VersionResponse>(create);
  static VersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get commit => $_getSZ(2);
  @$pb.TagNumber(3)
  set commit($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommit() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get buildTime => $_getSZ(3);
  @$pb.TagNumber(4)
  set buildTime($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBuildTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearBuildTime() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
