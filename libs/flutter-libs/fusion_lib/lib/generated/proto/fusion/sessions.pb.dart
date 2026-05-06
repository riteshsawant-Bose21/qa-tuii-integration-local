// This is a generated file - do not edit.
//
// Generated from fusion/sessions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/struct.pb.dart' as $1;
import '../google/protobuf/timestamp.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SAPSession extends $pb.GeneratedMessage {
  factory SAPSession({
    $core.String? id,
    $core.String? origin,
    $0.Timestamp? timestamp,
    $1.Struct? description,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (origin != null) result.origin = origin;
    if (timestamp != null) result.timestamp = timestamp;
    if (description != null) result.description = description;
    return result;
  }

  SAPSession._();

  factory SAPSession.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SAPSession.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SAPSession',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.sessions.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'origin')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $0.Timestamp.create)
    ..aOM<$1.Struct>(4, _omitFieldNames ? '' : 'description',
        subBuilder: $1.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SAPSession clone() => SAPSession()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SAPSession copyWith(void Function(SAPSession) updates) =>
      super.copyWith((message) => updates(message as SAPSession)) as SAPSession;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SAPSession create() => SAPSession._();
  @$core.override
  SAPSession createEmptyInstance() => create();
  static $pb.PbList<SAPSession> createRepeated() => $pb.PbList<SAPSession>();
  @$core.pragma('dart2js:noInline')
  static SAPSession getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SAPSession>(create);
  static SAPSession? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get origin => $_getSZ(1);
  @$pb.TagNumber(2)
  set origin($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrigin() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrigin() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get timestamp => $_getN(2);
  @$pb.TagNumber(3)
  set timestamp($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureTimestamp() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.Struct get description => $_getN(3);
  @$pb.TagNumber(4)
  set description($1.Struct value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Struct ensureDescription() => $_ensure(3);
}

class SessionListResponse extends $pb.GeneratedMessage {
  factory SessionListResponse({
    $core.Iterable<$core.MapEntry<$core.String, SAPSession>>? sessions,
  }) {
    final result = create();
    if (sessions != null) result.sessions.addEntries(sessions);
    return result;
  }

  SessionListResponse._();

  factory SessionListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.sessions.v1'),
      createEmptyInstance: create)
    ..m<$core.String, SAPSession>(1, _omitFieldNames ? '' : 'sessions',
        entryClassName: 'SessionListResponse.SessionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: SAPSession.create,
        valueDefaultOrMaker: SAPSession.getDefault,
        packageName: const $pb.PackageName('fusion.sessions.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionListResponse clone() => SessionListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionListResponse copyWith(void Function(SessionListResponse) updates) =>
      super.copyWith((message) => updates(message as SessionListResponse))
          as SessionListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionListResponse create() => SessionListResponse._();
  @$core.override
  SessionListResponse createEmptyInstance() => create();
  static $pb.PbList<SessionListResponse> createRepeated() =>
      $pb.PbList<SessionListResponse>();
  @$core.pragma('dart2js:noInline')
  static SessionListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionListResponse>(create);
  static SessionListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, SAPSession> get sessions => $_getMap(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
