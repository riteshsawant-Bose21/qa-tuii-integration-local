// This is a generated file - do not edit.
//
// Generated from fusion/time_machine.proto.

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

class SnapshotDefinition extends $pb.GeneratedMessage {
  factory SnapshotDefinition({
    $core.String? id,
    $core.String? name,
    $0.Struct? data,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (data != null) result.data = data;
    return result;
  }

  SnapshotDefinition._();

  factory SnapshotDefinition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnapshotDefinition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnapshotDefinition',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Struct>(3, _omitFieldNames ? '' : 'data',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotDefinition clone() => SnapshotDefinition()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotDefinition copyWith(void Function(SnapshotDefinition) updates) =>
      super.copyWith((message) => updates(message as SnapshotDefinition))
          as SnapshotDefinition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnapshotDefinition create() => SnapshotDefinition._();
  @$core.override
  SnapshotDefinition createEmptyInstance() => create();
  static $pb.PbList<SnapshotDefinition> createRepeated() =>
      $pb.PbList<SnapshotDefinition>();
  @$core.pragma('dart2js:noInline')
  static SnapshotDefinition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotDefinition>(create);
  static SnapshotDefinition? _defaultInstance;

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
  $0.Struct get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($0.Struct value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Struct ensureData() => $_ensure(2);
}

class Scene extends $pb.GeneratedMessage {
  factory Scene({
    $core.String? id,
    $core.String? name,
    $0.Struct? data,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (data != null) result.data = data;
    return result;
  }

  Scene._();

  factory Scene.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Scene.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Scene',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Struct>(3, _omitFieldNames ? '' : 'data',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scene clone() => Scene()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scene copyWith(void Function(Scene) updates) =>
      super.copyWith((message) => updates(message as Scene)) as Scene;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Scene create() => Scene._();
  @$core.override
  Scene createEmptyInstance() => create();
  static $pb.PbList<Scene> createRepeated() => $pb.PbList<Scene>();
  @$core.pragma('dart2js:noInline')
  static Scene getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Scene>(create);
  static Scene? _defaultInstance;

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
  $0.Struct get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($0.Struct value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Struct ensureData() => $_ensure(2);
}

class SceneSet extends $pb.GeneratedMessage {
  factory SceneSet({
    $core.String? setId,
    $core.String? name,
    $core.String? defaultScene,
    $core.String? currentSceneId,
    $core.Iterable<Scene>? scenes,
  }) {
    final result = create();
    if (setId != null) result.setId = setId;
    if (name != null) result.name = name;
    if (defaultScene != null) result.defaultScene = defaultScene;
    if (currentSceneId != null) result.currentSceneId = currentSceneId;
    if (scenes != null) result.scenes.addAll(scenes);
    return result;
  }

  SceneSet._();

  factory SceneSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SceneSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SceneSet',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'setId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'defaultScene')
    ..aOS(4, _omitFieldNames ? '' : 'currentSceneId')
    ..pc<Scene>(5, _omitFieldNames ? '' : 'scenes', $pb.PbFieldType.PM,
        subBuilder: Scene.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneSet clone() => SceneSet()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneSet copyWith(void Function(SceneSet) updates) =>
      super.copyWith((message) => updates(message as SceneSet)) as SceneSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SceneSet create() => SceneSet._();
  @$core.override
  SceneSet createEmptyInstance() => create();
  static $pb.PbList<SceneSet> createRepeated() => $pb.PbList<SceneSet>();
  @$core.pragma('dart2js:noInline')
  static SceneSet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SceneSet>(create);
  static SceneSet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get setId => $_getSZ(0);
  @$pb.TagNumber(1)
  set setId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get defaultScene => $_getSZ(2);
  @$pb.TagNumber(3)
  set defaultScene($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaultScene() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultScene() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get currentSceneId => $_getSZ(3);
  @$pb.TagNumber(4)
  set currentSceneId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCurrentSceneId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCurrentSceneId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Scene> get scenes => $_getList(4);
}

class ActivateSnapshotRequest extends $pb.GeneratedMessage {
  factory ActivateSnapshotRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  ActivateSnapshotRequest._();

  factory ActivateSnapshotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActivateSnapshotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivateSnapshotRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateSnapshotRequest clone() =>
      ActivateSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateSnapshotRequest copyWith(
          void Function(ActivateSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as ActivateSnapshotRequest))
          as ActivateSnapshotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActivateSnapshotRequest create() => ActivateSnapshotRequest._();
  @$core.override
  ActivateSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<ActivateSnapshotRequest> createRepeated() =>
      $pb.PbList<ActivateSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static ActivateSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActivateSnapshotRequest>(create);
  static ActivateSnapshotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ActivateSceneSetRequest extends $pb.GeneratedMessage {
  factory ActivateSceneSetRequest({
    $core.String? setId,
    $core.String? sceneId,
  }) {
    final result = create();
    if (setId != null) result.setId = setId;
    if (sceneId != null) result.sceneId = sceneId;
    return result;
  }

  ActivateSceneSetRequest._();

  factory ActivateSceneSetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActivateSceneSetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivateSceneSetRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'setId')
    ..aOS(2, _omitFieldNames ? '' : 'sceneId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateSceneSetRequest clone() =>
      ActivateSceneSetRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateSceneSetRequest copyWith(
          void Function(ActivateSceneSetRequest) updates) =>
      super.copyWith((message) => updates(message as ActivateSceneSetRequest))
          as ActivateSceneSetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActivateSceneSetRequest create() => ActivateSceneSetRequest._();
  @$core.override
  ActivateSceneSetRequest createEmptyInstance() => create();
  static $pb.PbList<ActivateSceneSetRequest> createRepeated() =>
      $pb.PbList<ActivateSceneSetRequest>();
  @$core.pragma('dart2js:noInline')
  static ActivateSceneSetRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActivateSceneSetRequest>(create);
  static ActivateSceneSetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get setId => $_getSZ(0);
  @$pb.TagNumber(1)
  set setId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sceneId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sceneId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSceneId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSceneId() => $_clearField(2);
}

class CurrentSceneRequest extends $pb.GeneratedMessage {
  factory CurrentSceneRequest({
    $core.String? setId,
  }) {
    final result = create();
    if (setId != null) result.setId = setId;
    return result;
  }

  CurrentSceneRequest._();

  factory CurrentSceneRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CurrentSceneRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CurrentSceneRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'setId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentSceneRequest clone() => CurrentSceneRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentSceneRequest copyWith(void Function(CurrentSceneRequest) updates) =>
      super.copyWith((message) => updates(message as CurrentSceneRequest))
          as CurrentSceneRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CurrentSceneRequest create() => CurrentSceneRequest._();
  @$core.override
  CurrentSceneRequest createEmptyInstance() => create();
  static $pb.PbList<CurrentSceneRequest> createRepeated() =>
      $pb.PbList<CurrentSceneRequest>();
  @$core.pragma('dart2js:noInline')
  static CurrentSceneRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CurrentSceneRequest>(create);
  static CurrentSceneRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get setId => $_getSZ(0);
  @$pb.TagNumber(1)
  set setId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetId() => $_clearField(1);
}

class CurrentSceneMetadata extends $pb.GeneratedMessage {
  factory CurrentSceneMetadata({
    $core.String? sceneId,
    $core.String? name,
  }) {
    final result = create();
    if (sceneId != null) result.sceneId = sceneId;
    if (name != null) result.name = name;
    return result;
  }

  CurrentSceneMetadata._();

  factory CurrentSceneMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CurrentSceneMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CurrentSceneMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sceneId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentSceneMetadata clone() =>
      CurrentSceneMetadata()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentSceneMetadata copyWith(void Function(CurrentSceneMetadata) updates) =>
      super.copyWith((message) => updates(message as CurrentSceneMetadata))
          as CurrentSceneMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CurrentSceneMetadata create() => CurrentSceneMetadata._();
  @$core.override
  CurrentSceneMetadata createEmptyInstance() => create();
  static $pb.PbList<CurrentSceneMetadata> createRepeated() =>
      $pb.PbList<CurrentSceneMetadata>();
  @$core.pragma('dart2js:noInline')
  static CurrentSceneMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CurrentSceneMetadata>(create);
  static CurrentSceneMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sceneId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sceneId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSceneId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSceneId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class CurrentSceneResponse extends $pb.GeneratedMessage {
  factory CurrentSceneResponse({
    $core.String? setId,
    CurrentSceneMetadata? currentScene,
  }) {
    final result = create();
    if (setId != null) result.setId = setId;
    if (currentScene != null) result.currentScene = currentScene;
    return result;
  }

  CurrentSceneResponse._();

  factory CurrentSceneResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CurrentSceneResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CurrentSceneResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'setId')
    ..aOM<CurrentSceneMetadata>(2, _omitFieldNames ? '' : 'currentScene',
        subBuilder: CurrentSceneMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentSceneResponse clone() =>
      CurrentSceneResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CurrentSceneResponse copyWith(void Function(CurrentSceneResponse) updates) =>
      super.copyWith((message) => updates(message as CurrentSceneResponse))
          as CurrentSceneResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CurrentSceneResponse create() => CurrentSceneResponse._();
  @$core.override
  CurrentSceneResponse createEmptyInstance() => create();
  static $pb.PbList<CurrentSceneResponse> createRepeated() =>
      $pb.PbList<CurrentSceneResponse>();
  @$core.pragma('dart2js:noInline')
  static CurrentSceneResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CurrentSceneResponse>(create);
  static CurrentSceneResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get setId => $_getSZ(0);
  @$pb.TagNumber(1)
  set setId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetId() => $_clearField(1);

  @$pb.TagNumber(2)
  CurrentSceneMetadata get currentScene => $_getN(1);
  @$pb.TagNumber(2)
  set currentScene(CurrentSceneMetadata value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrentScene() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrentScene() => $_clearField(2);
  @$pb.TagNumber(2)
  CurrentSceneMetadata ensureCurrentScene() => $_ensure(1);
}

class SnapshotDefinitionListResponse extends $pb.GeneratedMessage {
  factory SnapshotDefinitionListResponse({
    $core.Iterable<SnapshotDefinition>? snapshots,
  }) {
    final result = create();
    if (snapshots != null) result.snapshots.addAll(snapshots);
    return result;
  }

  SnapshotDefinitionListResponse._();

  factory SnapshotDefinitionListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnapshotDefinitionListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnapshotDefinitionListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..pc<SnapshotDefinition>(
        1, _omitFieldNames ? '' : 'snapshots', $pb.PbFieldType.PM,
        subBuilder: SnapshotDefinition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotDefinitionListResponse clone() =>
      SnapshotDefinitionListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotDefinitionListResponse copyWith(
          void Function(SnapshotDefinitionListResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SnapshotDefinitionListResponse))
          as SnapshotDefinitionListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnapshotDefinitionListResponse create() =>
      SnapshotDefinitionListResponse._();
  @$core.override
  SnapshotDefinitionListResponse createEmptyInstance() => create();
  static $pb.PbList<SnapshotDefinitionListResponse> createRepeated() =>
      $pb.PbList<SnapshotDefinitionListResponse>();
  @$core.pragma('dart2js:noInline')
  static SnapshotDefinitionListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotDefinitionListResponse>(create);
  static SnapshotDefinitionListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SnapshotDefinition> get snapshots => $_getList(0);
}

class SceneListResponse extends $pb.GeneratedMessage {
  factory SceneListResponse({
    $core.Iterable<Scene>? scenes,
  }) {
    final result = create();
    if (scenes != null) result.scenes.addAll(scenes);
    return result;
  }

  SceneListResponse._();

  factory SceneListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SceneListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SceneListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..pc<Scene>(1, _omitFieldNames ? '' : 'scenes', $pb.PbFieldType.PM,
        subBuilder: Scene.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneListResponse clone() => SceneListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneListResponse copyWith(void Function(SceneListResponse) updates) =>
      super.copyWith((message) => updates(message as SceneListResponse))
          as SceneListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SceneListResponse create() => SceneListResponse._();
  @$core.override
  SceneListResponse createEmptyInstance() => create();
  static $pb.PbList<SceneListResponse> createRepeated() =>
      $pb.PbList<SceneListResponse>();
  @$core.pragma('dart2js:noInline')
  static SceneListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SceneListResponse>(create);
  static SceneListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Scene> get scenes => $_getList(0);
}

class SceneSetListResponse extends $pb.GeneratedMessage {
  factory SceneSetListResponse({
    $core.Iterable<SceneSet>? sceneSets,
  }) {
    final result = create();
    if (sceneSets != null) result.sceneSets.addAll(sceneSets);
    return result;
  }

  SceneSetListResponse._();

  factory SceneSetListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SceneSetListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SceneSetListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..pc<SceneSet>(1, _omitFieldNames ? '' : 'sceneSets', $pb.PbFieldType.PM,
        subBuilder: SceneSet.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneSetListResponse clone() =>
      SceneSetListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneSetListResponse copyWith(void Function(SceneSetListResponse) updates) =>
      super.copyWith((message) => updates(message as SceneSetListResponse))
          as SceneSetListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SceneSetListResponse create() => SceneSetListResponse._();
  @$core.override
  SceneSetListResponse createEmptyInstance() => create();
  static $pb.PbList<SceneSetListResponse> createRepeated() =>
      $pb.PbList<SceneSetListResponse>();
  @$core.pragma('dart2js:noInline')
  static SceneSetListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SceneSetListResponse>(create);
  static SceneSetListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SceneSet> get sceneSets => $_getList(0);
}

class SceneCatalogListResponse extends $pb.GeneratedMessage {
  factory SceneCatalogListResponse({
    $core.Iterable<SnapshotDefinition>? snapshots,
    $core.Iterable<SceneSet>? sceneSets,
  }) {
    final result = create();
    if (snapshots != null) result.snapshots.addAll(snapshots);
    if (sceneSets != null) result.sceneSets.addAll(sceneSets);
    return result;
  }

  SceneCatalogListResponse._();

  factory SceneCatalogListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SceneCatalogListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SceneCatalogListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..pc<SnapshotDefinition>(
        1, _omitFieldNames ? '' : 'snapshots', $pb.PbFieldType.PM,
        subBuilder: SnapshotDefinition.create)
    ..pc<SceneSet>(2, _omitFieldNames ? '' : 'sceneSets', $pb.PbFieldType.PM,
        subBuilder: SceneSet.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneCatalogListResponse clone() =>
      SceneCatalogListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneCatalogListResponse copyWith(
          void Function(SceneCatalogListResponse) updates) =>
      super.copyWith((message) => updates(message as SceneCatalogListResponse))
          as SceneCatalogListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SceneCatalogListResponse create() => SceneCatalogListResponse._();
  @$core.override
  SceneCatalogListResponse createEmptyInstance() => create();
  static $pb.PbList<SceneCatalogListResponse> createRepeated() =>
      $pb.PbList<SceneCatalogListResponse>();
  @$core.pragma('dart2js:noInline')
  static SceneCatalogListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SceneCatalogListResponse>(create);
  static SceneCatalogListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SnapshotDefinition> get snapshots => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<SceneSet> get sceneSets => $_getList(1);
}

class TimeMachineListResponse extends $pb.GeneratedMessage {
  factory TimeMachineListResponse({
    $core.Iterable<$core.String>? snapshots,
  }) {
    final result = create();
    if (snapshots != null) result.snapshots.addAll(snapshots);
    return result;
  }

  TimeMachineListResponse._();

  factory TimeMachineListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TimeMachineListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimeMachineListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'snapshots')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeMachineListResponse clone() =>
      TimeMachineListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeMachineListResponse copyWith(
          void Function(TimeMachineListResponse) updates) =>
      super.copyWith((message) => updates(message as TimeMachineListResponse))
          as TimeMachineListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeMachineListResponse create() => TimeMachineListResponse._();
  @$core.override
  TimeMachineListResponse createEmptyInstance() => create();
  static $pb.PbList<TimeMachineListResponse> createRepeated() =>
      $pb.PbList<TimeMachineListResponse>();
  @$core.pragma('dart2js:noInline')
  static TimeMachineListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimeMachineListResponse>(create);
  static TimeMachineListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get snapshots => $_getList(0);
}

class ActiveTimeMachineResponse extends $pb.GeneratedMessage {
  factory ActiveTimeMachineResponse({
    $core.String? activeSnapshot,
  }) {
    final result = create();
    if (activeSnapshot != null) result.activeSnapshot = activeSnapshot;
    return result;
  }

  ActiveTimeMachineResponse._();

  factory ActiveTimeMachineResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActiveTimeMachineResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveTimeMachineResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'activeSnapshot')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveTimeMachineResponse clone() =>
      ActiveTimeMachineResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveTimeMachineResponse copyWith(
          void Function(ActiveTimeMachineResponse) updates) =>
      super.copyWith((message) => updates(message as ActiveTimeMachineResponse))
          as ActiveTimeMachineResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActiveTimeMachineResponse create() => ActiveTimeMachineResponse._();
  @$core.override
  ActiveTimeMachineResponse createEmptyInstance() => create();
  static $pb.PbList<ActiveTimeMachineResponse> createRepeated() =>
      $pb.PbList<ActiveTimeMachineResponse>();
  @$core.pragma('dart2js:noInline')
  static ActiveTimeMachineResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveTimeMachineResponse>(create);
  static ActiveTimeMachineResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get activeSnapshot => $_getSZ(0);
  @$pb.TagNumber(1)
  set activeSnapshot($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActiveSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearActiveSnapshot() => $_clearField(1);
}

class TimeMachineOperationStatus extends $pb.GeneratedMessage {
  factory TimeMachineOperationStatus({
    $core.String? name,
    $core.String? status,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (status != null) result.status = status;
    return result;
  }

  TimeMachineOperationStatus._();

  factory TimeMachineOperationStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TimeMachineOperationStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimeMachineOperationStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.snapshots.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeMachineOperationStatus clone() =>
      TimeMachineOperationStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeMachineOperationStatus copyWith(
          void Function(TimeMachineOperationStatus) updates) =>
      super.copyWith(
              (message) => updates(message as TimeMachineOperationStatus))
          as TimeMachineOperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeMachineOperationStatus create() => TimeMachineOperationStatus._();
  @$core.override
  TimeMachineOperationStatus createEmptyInstance() => create();
  static $pb.PbList<TimeMachineOperationStatus> createRepeated() =>
      $pb.PbList<TimeMachineOperationStatus>();
  @$core.pragma('dart2js:noInline')
  static TimeMachineOperationStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimeMachineOperationStatus>(create);
  static TimeMachineOperationStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
