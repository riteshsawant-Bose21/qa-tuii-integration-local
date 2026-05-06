// This is a generated file - do not edit.
//
// Generated from fusion/websocket.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/struct.pb.dart' as $0;
import '../google/protobuf/timestamp.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class WebSocketRequest extends $pb.GeneratedMessage {
  factory WebSocketRequest({
    $core.String? id,
    $core.int? version,
    $core.String? type,
    $0.Value? data,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (version != null) result.version = version;
    if (type != null) result.type = type;
    if (data != null) result.data = data;
    return result;
  }

  WebSocketRequest._();

  factory WebSocketRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebSocketRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebSocketRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.websocket.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOM<$0.Value>(4, _omitFieldNames ? '' : 'data',
        subBuilder: $0.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketRequest clone() => WebSocketRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketRequest copyWith(void Function(WebSocketRequest) updates) =>
      super.copyWith((message) => updates(message as WebSocketRequest))
          as WebSocketRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebSocketRequest create() => WebSocketRequest._();
  @$core.override
  WebSocketRequest createEmptyInstance() => create();
  static $pb.PbList<WebSocketRequest> createRepeated() =>
      $pb.PbList<WebSocketRequest>();
  @$core.pragma('dart2js:noInline')
  static WebSocketRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebSocketRequest>(create);
  static WebSocketRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Value get data => $_getN(3);
  @$pb.TagNumber(4)
  set data($0.Value value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Value ensureData() => $_ensure(3);
}

class WebSocketResponse extends $pb.GeneratedMessage {
  factory WebSocketResponse({
    $core.String? id,
    $core.int? version,
    $core.String? type,
    $core.int? code,
    $core.String? status,
    $core.String? message,
    $0.Value? data,
    $1.Timestamp? timestamp,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (version != null) result.version = version;
    if (type != null) result.type = type;
    if (code != null) result.code = code;
    if (status != null) result.status = status;
    if (message != null) result.message = message;
    if (data != null) result.data = data;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  WebSocketResponse._();

  factory WebSocketResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebSocketResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebSocketResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.websocket.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'code', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..aOS(6, _omitFieldNames ? '' : 'message')
    ..aOM<$0.Value>(7, _omitFieldNames ? '' : 'data',
        subBuilder: $0.Value.create)
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketResponse clone() => WebSocketResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketResponse copyWith(void Function(WebSocketResponse) updates) =>
      super.copyWith((message) => updates(message as WebSocketResponse))
          as WebSocketResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebSocketResponse create() => WebSocketResponse._();
  @$core.override
  WebSocketResponse createEmptyInstance() => create();
  static $pb.PbList<WebSocketResponse> createRepeated() =>
      $pb.PbList<WebSocketResponse>();
  @$core.pragma('dart2js:noInline')
  static WebSocketResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebSocketResponse>(create);
  static WebSocketResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get code => $_getIZ(3);
  @$pb.TagNumber(4)
  set code($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearCode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(4);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get message => $_getSZ(5);
  @$pb.TagNumber(6)
  set message($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearMessage() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.Value get data => $_getN(6);
  @$pb.TagNumber(7)
  set data($0.Value value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasData() => $_has(6);
  @$pb.TagNumber(7)
  void clearData() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Value ensureData() => $_ensure(6);

  @$pb.TagNumber(8)
  $1.Timestamp get timestamp => $_getN(7);
  @$pb.TagNumber(8)
  set timestamp($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasTimestamp() => $_has(7);
  @$pb.TagNumber(8)
  void clearTimestamp() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureTimestamp() => $_ensure(7);
}

class WebSocketConfigUpdateEvent extends $pb.GeneratedMessage {
  factory WebSocketConfigUpdateEvent({
    $core.String? mode,
    $0.Struct? updates,
    $0.Struct? state,
    $core.bool? clear_4,
  }) {
    final result = create();
    if (mode != null) result.mode = mode;
    if (updates != null) result.updates = updates;
    if (state != null) result.state = state;
    if (clear_4 != null) result.clear_4 = clear_4;
    return result;
  }

  WebSocketConfigUpdateEvent._();

  factory WebSocketConfigUpdateEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebSocketConfigUpdateEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebSocketConfigUpdateEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.websocket.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mode')
    ..aOM<$0.Struct>(2, _omitFieldNames ? '' : 'updates',
        subBuilder: $0.Struct.create)
    ..aOM<$0.Struct>(3, _omitFieldNames ? '' : 'state',
        subBuilder: $0.Struct.create)
    ..aOB(4, _omitFieldNames ? '' : 'clear')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketConfigUpdateEvent clone() =>
      WebSocketConfigUpdateEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketConfigUpdateEvent copyWith(
          void Function(WebSocketConfigUpdateEvent) updates) =>
      super.copyWith(
              (message) => updates(message as WebSocketConfigUpdateEvent))
          as WebSocketConfigUpdateEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebSocketConfigUpdateEvent create() => WebSocketConfigUpdateEvent._();
  @$core.override
  WebSocketConfigUpdateEvent createEmptyInstance() => create();
  static $pb.PbList<WebSocketConfigUpdateEvent> createRepeated() =>
      $pb.PbList<WebSocketConfigUpdateEvent>();
  @$core.pragma('dart2js:noInline')
  static WebSocketConfigUpdateEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebSocketConfigUpdateEvent>(create);
  static WebSocketConfigUpdateEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mode => $_getSZ(0);
  @$pb.TagNumber(1)
  set mode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Struct get updates => $_getN(1);
  @$pb.TagNumber(2)
  set updates($0.Struct value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdates() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdates() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Struct ensureUpdates() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.Struct get state => $_getN(2);
  @$pb.TagNumber(3)
  set state($0.Struct value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Struct ensureState() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get clear_4 => $_getBF(3);
  @$pb.TagNumber(4)
  set clear_4($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClear_4() => $_has(3);
  @$pb.TagNumber(4)
  void clearClear_4() => $_clearField(4);
}

class WebSocketDeviceLookupRequest extends $pb.GeneratedMessage {
  factory WebSocketDeviceLookupRequest({
    $core.String? deviceId,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  WebSocketDeviceLookupRequest._();

  factory WebSocketDeviceLookupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebSocketDeviceLookupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebSocketDeviceLookupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.websocket.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketDeviceLookupRequest clone() =>
      WebSocketDeviceLookupRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketDeviceLookupRequest copyWith(
          void Function(WebSocketDeviceLookupRequest) updates) =>
      super.copyWith(
              (message) => updates(message as WebSocketDeviceLookupRequest))
          as WebSocketDeviceLookupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebSocketDeviceLookupRequest create() =>
      WebSocketDeviceLookupRequest._();
  @$core.override
  WebSocketDeviceLookupRequest createEmptyInstance() => create();
  static $pb.PbList<WebSocketDeviceLookupRequest> createRepeated() =>
      $pb.PbList<WebSocketDeviceLookupRequest>();
  @$core.pragma('dart2js:noInline')
  static WebSocketDeviceLookupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebSocketDeviceLookupRequest>(create);
  static WebSocketDeviceLookupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

class WebSocketUpdateDeviceInfoRequest extends $pb.GeneratedMessage {
  factory WebSocketUpdateDeviceInfoRequest({
    $core.String? deviceId,
    $core.String? id,
    $core.String? location,
    $core.String? name,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    if (id != null) result.id = id;
    if (location != null) result.location = location;
    if (name != null) result.name = name;
    return result;
  }

  WebSocketUpdateDeviceInfoRequest._();

  factory WebSocketUpdateDeviceInfoRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebSocketUpdateDeviceInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebSocketUpdateDeviceInfoRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.websocket.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'location')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketUpdateDeviceInfoRequest clone() =>
      WebSocketUpdateDeviceInfoRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketUpdateDeviceInfoRequest copyWith(
          void Function(WebSocketUpdateDeviceInfoRequest) updates) =>
      super.copyWith(
              (message) => updates(message as WebSocketUpdateDeviceInfoRequest))
          as WebSocketUpdateDeviceInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebSocketUpdateDeviceInfoRequest create() =>
      WebSocketUpdateDeviceInfoRequest._();
  @$core.override
  WebSocketUpdateDeviceInfoRequest createEmptyInstance() => create();
  static $pb.PbList<WebSocketUpdateDeviceInfoRequest> createRepeated() =>
      $pb.PbList<WebSocketUpdateDeviceInfoRequest>();
  @$core.pragma('dart2js:noInline')
  static WebSocketUpdateDeviceInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebSocketUpdateDeviceInfoRequest>(
          create);
  static WebSocketUpdateDeviceInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

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
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
