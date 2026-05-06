// This is a generated file - do not edit.
//
// Generated from fusion/health.proto.

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

class ClusterMember extends $pb.GeneratedMessage {
  factory ClusterMember({
    $core.String? name,
    $core.String? address,
    $core.int? port,
    $core.String? state,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (address != null) result.address = address;
    if (port != null) result.port = port;
    if (state != null) result.state = state;
    return result;
  }

  ClusterMember._();

  factory ClusterMember.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClusterMember.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClusterMember',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'address')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'port', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'state')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClusterMember clone() => ClusterMember()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClusterMember copyWith(void Function(ClusterMember) updates) =>
      super.copyWith((message) => updates(message as ClusterMember))
          as ClusterMember;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClusterMember create() => ClusterMember._();
  @$core.override
  ClusterMember createEmptyInstance() => create();
  static $pb.PbList<ClusterMember> createRepeated() =>
      $pb.PbList<ClusterMember>();
  @$core.pragma('dart2js:noInline')
  static ClusterMember getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClusterMember>(create);
  static ClusterMember? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get address => $_getSZ(1);
  @$pb.TagNumber(2)
  set address($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddress() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get port => $_getIZ(2);
  @$pb.TagNumber(3)
  set port($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearPort() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get state => $_getSZ(3);
  @$pb.TagNumber(4)
  set state($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);
}

class ClusterInfo extends $pb.GeneratedMessage {
  factory ClusterInfo({
    $core.int? memberCount,
    $core.int? aliveCount,
    $core.String? localNode,
    $core.Iterable<ClusterMember>? members,
    $0.Timestamp? lastUpdateTime,
    $core.int? suspectNodes,
    $core.int? deadNodes,
    $core.double? clusterHealth,
    $core.double? avgPingLatencyMs,
  }) {
    final result = create();
    if (memberCount != null) result.memberCount = memberCount;
    if (aliveCount != null) result.aliveCount = aliveCount;
    if (localNode != null) result.localNode = localNode;
    if (members != null) result.members.addAll(members);
    if (lastUpdateTime != null) result.lastUpdateTime = lastUpdateTime;
    if (suspectNodes != null) result.suspectNodes = suspectNodes;
    if (deadNodes != null) result.deadNodes = deadNodes;
    if (clusterHealth != null) result.clusterHealth = clusterHealth;
    if (avgPingLatencyMs != null) result.avgPingLatencyMs = avgPingLatencyMs;
    return result;
  }

  ClusterInfo._();

  factory ClusterInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClusterInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClusterInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'memberCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'aliveCount', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'localNode')
    ..pc<ClusterMember>(4, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM,
        subBuilder: ClusterMember.create)
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'lastUpdateTime',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(
        6, _omitFieldNames ? '' : 'suspectNodes', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'deadNodes', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        8, _omitFieldNames ? '' : 'clusterHealth', $pb.PbFieldType.OD)
    ..a<$core.double>(
        9, _omitFieldNames ? '' : 'avgPingLatencyMs', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClusterInfo clone() => ClusterInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClusterInfo copyWith(void Function(ClusterInfo) updates) =>
      super.copyWith((message) => updates(message as ClusterInfo))
          as ClusterInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClusterInfo create() => ClusterInfo._();
  @$core.override
  ClusterInfo createEmptyInstance() => create();
  static $pb.PbList<ClusterInfo> createRepeated() => $pb.PbList<ClusterInfo>();
  @$core.pragma('dart2js:noInline')
  static ClusterInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClusterInfo>(create);
  static ClusterInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get memberCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set memberCount($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get aliveCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set aliveCount($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAliveCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAliveCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get localNode => $_getSZ(2);
  @$pb.TagNumber(3)
  set localNode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocalNode() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalNode() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<ClusterMember> get members => $_getList(3);

  @$pb.TagNumber(5)
  $0.Timestamp get lastUpdateTime => $_getN(4);
  @$pb.TagNumber(5)
  set lastUpdateTime($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLastUpdateTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastUpdateTime() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureLastUpdateTime() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.int get suspectNodes => $_getIZ(5);
  @$pb.TagNumber(6)
  set suspectNodes($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSuspectNodes() => $_has(5);
  @$pb.TagNumber(6)
  void clearSuspectNodes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get deadNodes => $_getIZ(6);
  @$pb.TagNumber(7)
  set deadNodes($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDeadNodes() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeadNodes() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get clusterHealth => $_getN(7);
  @$pb.TagNumber(8)
  set clusterHealth($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasClusterHealth() => $_has(7);
  @$pb.TagNumber(8)
  void clearClusterHealth() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get avgPingLatencyMs => $_getN(8);
  @$pb.TagNumber(9)
  set avgPingLatencyMs($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAvgPingLatencyMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearAvgPingLatencyMs() => $_clearField(9);
}

class NodeHealth extends $pb.GeneratedMessage {
  factory NodeHealth({
    $core.String? status,
    $0.Timestamp? lastHeartbeat,
    $fixnum.Int64? uptimeSeconds,
    $0.Timestamp? startTime,
    $fixnum.Int64? healthCheckCount,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (lastHeartbeat != null) result.lastHeartbeat = lastHeartbeat;
    if (uptimeSeconds != null) result.uptimeSeconds = uptimeSeconds;
    if (startTime != null) result.startTime = startTime;
    if (healthCheckCount != null) result.healthCheckCount = healthCheckCount;
    return result;
  }

  NodeHealth._();

  factory NodeHealth.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeHealth.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeHealth',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'lastHeartbeat',
        subBuilder: $0.Timestamp.create)
    ..aInt64(3, _omitFieldNames ? '' : 'uptimeSeconds')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'startTime',
        subBuilder: $0.Timestamp.create)
    ..aInt64(5, _omitFieldNames ? '' : 'healthCheckCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeHealth clone() => NodeHealth()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeHealth copyWith(void Function(NodeHealth) updates) =>
      super.copyWith((message) => updates(message as NodeHealth)) as NodeHealth;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeHealth create() => NodeHealth._();
  @$core.override
  NodeHealth createEmptyInstance() => create();
  static $pb.PbList<NodeHealth> createRepeated() => $pb.PbList<NodeHealth>();
  @$core.pragma('dart2js:noInline')
  static NodeHealth getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeHealth>(create);
  static NodeHealth? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get lastHeartbeat => $_getN(1);
  @$pb.TagNumber(2)
  set lastHeartbeat($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLastHeartbeat() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastHeartbeat() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureLastHeartbeat() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get uptimeSeconds => $_getI64(2);
  @$pb.TagNumber(3)
  set uptimeSeconds($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUptimeSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearUptimeSeconds() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get startTime => $_getN(3);
  @$pb.TagNumber(4)
  set startTime($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStartTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTime() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureStartTime() => $_ensure(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get healthCheckCount => $_getI64(4);
  @$pb.TagNumber(5)
  set healthCheckCount($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHealthCheckCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearHealthCheckCount() => $_clearField(5);
}

class HealthCheckResponse extends $pb.GeneratedMessage {
  factory HealthCheckResponse({
    $core.String? status,
    NodeHealth? nodeHealth,
    $core.double? clusterHealth,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (nodeHealth != null) result.nodeHealth = nodeHealth;
    if (clusterHealth != null) result.clusterHealth = clusterHealth;
    return result;
  }

  HealthCheckResponse._();

  factory HealthCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HealthCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aOM<NodeHealth>(2, _omitFieldNames ? '' : 'nodeHealth',
        subBuilder: NodeHealth.create)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'clusterHealth', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthCheckResponse clone() => HealthCheckResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthCheckResponse copyWith(void Function(HealthCheckResponse) updates) =>
      super.copyWith((message) => updates(message as HealthCheckResponse))
          as HealthCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HealthCheckResponse create() => HealthCheckResponse._();
  @$core.override
  HealthCheckResponse createEmptyInstance() => create();
  static $pb.PbList<HealthCheckResponse> createRepeated() =>
      $pb.PbList<HealthCheckResponse>();
  @$core.pragma('dart2js:noInline')
  static HealthCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HealthCheckResponse>(create);
  static HealthCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  NodeHealth get nodeHealth => $_getN(1);
  @$pb.TagNumber(2)
  set nodeHealth(NodeHealth value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNodeHealth() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeHealth() => $_clearField(2);
  @$pb.TagNumber(2)
  NodeHealth ensureNodeHealth() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.double get clusterHealth => $_getN(2);
  @$pb.TagNumber(3)
  set clusterHealth($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClusterHealth() => $_has(2);
  @$pb.TagNumber(3)
  void clearClusterHealth() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
