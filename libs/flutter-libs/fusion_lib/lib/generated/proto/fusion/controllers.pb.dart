// This is a generated file - do not edit.
//
// Generated from fusion/controllers.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ControllerInfo extends $pb.GeneratedMessage {
  factory ControllerInfo({
    $core.String? id,
    $core.String? name,
    $core.String? address,
    $core.String? version,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (address != null) result.address = address;
    if (version != null) result.version = version;
    return result;
  }

  ControllerInfo._();

  factory ControllerInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.controllers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'address')
    ..aOS(4, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerInfo clone() => ControllerInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerInfo copyWith(void Function(ControllerInfo) updates) =>
      super.copyWith((message) => updates(message as ControllerInfo))
          as ControllerInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerInfo create() => ControllerInfo._();
  @$core.override
  ControllerInfo createEmptyInstance() => create();
  static $pb.PbList<ControllerInfo> createRepeated() =>
      $pb.PbList<ControllerInfo>();
  @$core.pragma('dart2js:noInline')
  static ControllerInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerInfo>(create);
  static ControllerInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get address => $_getSZ(2);
  @$pb.TagNumber(3)
  set address($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get version => $_getSZ(3);
  @$pb.TagNumber(4)
  set version($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => $_clearField(4);
}

class ControllerListResponse extends $pb.GeneratedMessage {
  factory ControllerListResponse({
    $core.Iterable<ControllerInfo>? controllers,
  }) {
    final result = create();
    if (controllers != null) result.controllers.addAll(controllers);
    return result;
  }

  ControllerListResponse._();

  factory ControllerListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerListResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.controllers.v1'),
      createEmptyInstance: create)
    ..pc<ControllerInfo>(
        1, _omitFieldNames ? '' : 'controllers', $pb.PbFieldType.PM,
        subBuilder: ControllerInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerListResponse clone() =>
      ControllerListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerListResponse copyWith(
          void Function(ControllerListResponse) updates) =>
      super.copyWith((message) => updates(message as ControllerListResponse))
          as ControllerListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerListResponse create() => ControllerListResponse._();
  @$core.override
  ControllerListResponse createEmptyInstance() => create();
  static $pb.PbList<ControllerListResponse> createRepeated() =>
      $pb.PbList<ControllerListResponse>();
  @$core.pragma('dart2js:noInline')
  static ControllerListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerListResponse>(create);
  static ControllerListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ControllerInfo> get controllers => $_getList(0);
}

class ControllerWinkResponse extends $pb.GeneratedMessage {
  factory ControllerWinkResponse({
    $core.String? status,
    $core.String? message,
    $core.String? controllerId,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (message != null) result.message = message;
    if (controllerId != null) result.controllerId = controllerId;
    return result;
  }

  ControllerWinkResponse._();

  factory ControllerWinkResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControllerWinkResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControllerWinkResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fusion.controllers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'controllerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerWinkResponse clone() =>
      ControllerWinkResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControllerWinkResponse copyWith(
          void Function(ControllerWinkResponse) updates) =>
      super.copyWith((message) => updates(message as ControllerWinkResponse))
          as ControllerWinkResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControllerWinkResponse create() => ControllerWinkResponse._();
  @$core.override
  ControllerWinkResponse createEmptyInstance() => create();
  static $pb.PbList<ControllerWinkResponse> createRepeated() =>
      $pb.PbList<ControllerWinkResponse>();
  @$core.pragma('dart2js:noInline')
  static ControllerWinkResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControllerWinkResponse>(create);
  static ControllerWinkResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get controllerId => $_getSZ(2);
  @$pb.TagNumber(3)
  set controllerId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasControllerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearControllerId() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
