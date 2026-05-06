// This is a generated file - do not edit.
//
// Generated from fusion/vip.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/timestamp.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CurrentVIPResponse extends $pb.GeneratedMessage {
  factory CurrentVIPResponse({
    $core.String? local,
    $core.String? vip,
  }) {
    final result = create();
    if (local != null) result.local = local;
    if (vip != null) result.vip = vip;
    return result;
  }

  CurrentVIPResponse._();

  factory CurrentVIPResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CurrentVIPResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CurrentVIPResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.vip.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'local')
    ..aOS(2, _omitFieldNames ? '' : 'vip')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentVIPResponse clone() => CurrentVIPResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentVIPResponse copyWith(void Function(CurrentVIPResponse) updates) =>
      super.copyWith((message) => updates(message as CurrentVIPResponse))
          as CurrentVIPResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CurrentVIPResponse create() => CurrentVIPResponse._();
  @$core.override
  CurrentVIPResponse createEmptyInstance() => create();
  static $pb.PbList<CurrentVIPResponse> createRepeated() =>
      $pb.PbList<CurrentVIPResponse>();
  @$core.pragma('dart2js:noInline')
  static CurrentVIPResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CurrentVIPResponse>(create);
  static CurrentVIPResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get local => $_getSZ(0);
  @$pb.TagNumber(1)
  set local($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLocal() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocal() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get vip => $_getSZ(1);
  @$pb.TagNumber(2)
  set vip($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVip() => $_has(1);
  @$pb.TagNumber(2)
  void clearVip() => $_clearField(2);
}

class VIPNodeResult extends $pb.GeneratedMessage {
  factory VIPNodeResult({
    $core.String? node,
    $core.String? host,
    $core.String? phase,
    $core.bool? success,
    $core.int? statusCode,
    $core.String? error,
    $0.Timestamp? startedAt,
    $0.Timestamp? completedAt,
  }) {
    final result = create();
    if (node != null) result.node = node;
    if (host != null) result.host = host;
    if (phase != null) result.phase = phase;
    if (success != null) result.success = success;
    if (statusCode != null) result.statusCode = statusCode;
    if (error != null) result.error = error;
    if (startedAt != null) result.startedAt = startedAt;
    if (completedAt != null) result.completedAt = completedAt;
    return result;
  }

  VIPNodeResult._();

  factory VIPNodeResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VIPNodeResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VIPNodeResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.vip.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'node')
    ..aOS(2, _omitFieldNames ? '' : 'host')
    ..aOS(3, _omitFieldNames ? '' : 'phase')
    ..aOB(4, _omitFieldNames ? '' : 'success')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'statusCode', $pb.PbFieldType.O3)
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(8, _omitFieldNames ? '' : 'completedAt',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VIPNodeResult clone() => VIPNodeResult()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VIPNodeResult copyWith(void Function(VIPNodeResult) updates) =>
      super.copyWith((message) => updates(message as VIPNodeResult))
          as VIPNodeResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VIPNodeResult create() => VIPNodeResult._();
  @$core.override
  VIPNodeResult createEmptyInstance() => create();
  static $pb.PbList<VIPNodeResult> createRepeated() =>
      $pb.PbList<VIPNodeResult>();
  @$core.pragma('dart2js:noInline')
  static VIPNodeResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VIPNodeResult>(create);
  static VIPNodeResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get node => $_getSZ(0);
  @$pb.TagNumber(1)
  set node($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get host => $_getSZ(1);
  @$pb.TagNumber(2)
  set host($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHost() => $_has(1);
  @$pb.TagNumber(2)
  void clearHost() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get phase => $_getSZ(2);
  @$pb.TagNumber(3)
  set phase($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPhase() => $_has(2);
  @$pb.TagNumber(3)
  void clearPhase() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get success => $_getBF(3);
  @$pb.TagNumber(4)
  set success($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSuccess() => $_has(3);
  @$pb.TagNumber(4)
  void clearSuccess() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get statusCode => $_getIZ(4);
  @$pb.TagNumber(5)
  set statusCode($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStatusCode() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatusCode() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.Timestamp get startedAt => $_getN(6);
  @$pb.TagNumber(7)
  set startedAt($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasStartedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearStartedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureStartedAt() => $_ensure(6);

  @$pb.TagNumber(8)
  $0.Timestamp get completedAt => $_getN(7);
  @$pb.TagNumber(8)
  set completedAt($0.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCompletedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCompletedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Timestamp ensureCompletedAt() => $_ensure(7);
}

class VIPOperationStatus extends $pb.GeneratedMessage {
  factory VIPOperationStatus({
    $core.String? id,
    $core.String? desiredVip,
    $core.String? statusHost,
    $core.String? observedVip,
    $core.String? observedHolder,
    $core.String? phase,
    $core.String? message,
    $0.Timestamp? startedAt,
    $0.Timestamp? completedAt,
    $core.Iterable<$core.MapEntry<$core.String, VIPNodeResult>>? nodeResults,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (desiredVip != null) result.desiredVip = desiredVip;
    if (statusHost != null) result.statusHost = statusHost;
    if (observedVip != null) result.observedVip = observedVip;
    if (observedHolder != null) result.observedHolder = observedHolder;
    if (phase != null) result.phase = phase;
    if (message != null) result.message = message;
    if (startedAt != null) result.startedAt = startedAt;
    if (completedAt != null) result.completedAt = completedAt;
    if (nodeResults != null) result.nodeResults.addEntries(nodeResults);
    return result;
  }

  VIPOperationStatus._();

  factory VIPOperationStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VIPOperationStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VIPOperationStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.vip.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'desiredVip')
    ..aOS(3, _omitFieldNames ? '' : 'statusHost')
    ..aOS(4, _omitFieldNames ? '' : 'observedVip')
    ..aOS(5, _omitFieldNames ? '' : 'observedHolder')
    ..aOS(6, _omitFieldNames ? '' : 'phase')
    ..aOS(7, _omitFieldNames ? '' : 'message')
    ..aOM<$0.Timestamp>(8, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(9, _omitFieldNames ? '' : 'completedAt',
        subBuilder: $0.Timestamp.create)
    ..m<$core.String, VIPNodeResult>(10, _omitFieldNames ? '' : 'nodeResults',
        entryClassName: 'VIPOperationStatus.NodeResultsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: VIPNodeResult.create,
        valueDefaultOrMaker: VIPNodeResult.getDefault,
        packageName: const $pb.PackageName('fusion.vip.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VIPOperationStatus clone() => VIPOperationStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VIPOperationStatus copyWith(void Function(VIPOperationStatus) updates) =>
      super.copyWith((message) => updates(message as VIPOperationStatus))
          as VIPOperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VIPOperationStatus create() => VIPOperationStatus._();
  @$core.override
  VIPOperationStatus createEmptyInstance() => create();
  static $pb.PbList<VIPOperationStatus> createRepeated() =>
      $pb.PbList<VIPOperationStatus>();
  @$core.pragma('dart2js:noInline')
  static VIPOperationStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VIPOperationStatus>(create);
  static VIPOperationStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get desiredVip => $_getSZ(1);
  @$pb.TagNumber(2)
  set desiredVip($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDesiredVip() => $_has(1);
  @$pb.TagNumber(2)
  void clearDesiredVip() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get statusHost => $_getSZ(2);
  @$pb.TagNumber(3)
  set statusHost($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatusHost() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusHost() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get observedVip => $_getSZ(3);
  @$pb.TagNumber(4)
  set observedVip($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasObservedVip() => $_has(3);
  @$pb.TagNumber(4)
  void clearObservedVip() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get observedHolder => $_getSZ(4);
  @$pb.TagNumber(5)
  set observedHolder($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasObservedHolder() => $_has(4);
  @$pb.TagNumber(5)
  void clearObservedHolder() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get phase => $_getSZ(5);
  @$pb.TagNumber(6)
  set phase($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPhase() => $_has(5);
  @$pb.TagNumber(6)
  void clearPhase() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get message => $_getSZ(6);
  @$pb.TagNumber(7)
  set message($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessage() => $_clearField(7);

  @$pb.TagNumber(8)
  $0.Timestamp get startedAt => $_getN(7);
  @$pb.TagNumber(8)
  set startedAt($0.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStartedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearStartedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Timestamp ensureStartedAt() => $_ensure(7);

  @$pb.TagNumber(9)
  $0.Timestamp get completedAt => $_getN(8);
  @$pb.TagNumber(9)
  set completedAt($0.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasCompletedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCompletedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.Timestamp ensureCompletedAt() => $_ensure(8);

  @$pb.TagNumber(10)
  $pb.PbMap<$core.String, VIPNodeResult> get nodeResults => $_getMap(9);
}

class VIPApplyStatus extends $pb.GeneratedMessage {
  factory VIPApplyStatus({
    $core.String? desiredVip,
    $core.String? phase,
    $core.String? message,
    $0.Timestamp? startedAt,
    $0.Timestamp? completedAt,
  }) {
    final result = create();
    if (desiredVip != null) result.desiredVip = desiredVip;
    if (phase != null) result.phase = phase;
    if (message != null) result.message = message;
    if (startedAt != null) result.startedAt = startedAt;
    if (completedAt != null) result.completedAt = completedAt;
    return result;
  }

  VIPApplyStatus._();

  factory VIPApplyStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VIPApplyStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VIPApplyStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.vip.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'desiredVip')
    ..aOS(2, _omitFieldNames ? '' : 'phase')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'completedAt',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VIPApplyStatus clone() => VIPApplyStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VIPApplyStatus copyWith(void Function(VIPApplyStatus) updates) =>
      super.copyWith((message) => updates(message as VIPApplyStatus))
          as VIPApplyStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VIPApplyStatus create() => VIPApplyStatus._();
  @$core.override
  VIPApplyStatus createEmptyInstance() => create();
  static $pb.PbList<VIPApplyStatus> createRepeated() =>
      $pb.PbList<VIPApplyStatus>();
  @$core.pragma('dart2js:noInline')
  static VIPApplyStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VIPApplyStatus>(create);
  static VIPApplyStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get desiredVip => $_getSZ(0);
  @$pb.TagNumber(1)
  set desiredVip($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDesiredVip() => $_has(0);
  @$pb.TagNumber(1)
  void clearDesiredVip() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get phase => $_getSZ(1);
  @$pb.TagNumber(2)
  set phase($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPhase() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhase() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get startedAt => $_getN(3);
  @$pb.TagNumber(4)
  set startedAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStartedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureStartedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $0.Timestamp get completedAt => $_getN(4);
  @$pb.TagNumber(5)
  set completedAt($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCompletedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompletedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureCompletedAt() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
