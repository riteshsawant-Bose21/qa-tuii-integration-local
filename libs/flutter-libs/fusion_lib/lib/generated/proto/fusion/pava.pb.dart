// This is a generated file - do not edit.
//
// Generated from fusion/pava.proto.

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

class AudioMetadata extends $pb.GeneratedMessage {
  factory AudioMetadata({
    $core.String? id,
    $core.String? origName,
    $core.String? displayName,
    $core.String? filename,
    $core.String? mimeType,
    $0.Timestamp? uploaded,
    $fixnum.Int64? duration,
    $fixnum.Int64? sizeBytes,
    $core.Iterable<$core.String>? tags,
    $core.String? checksum,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (origName != null) result.origName = origName;
    if (displayName != null) result.displayName = displayName;
    if (filename != null) result.filename = filename;
    if (mimeType != null) result.mimeType = mimeType;
    if (uploaded != null) result.uploaded = uploaded;
    if (duration != null) result.duration = duration;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (tags != null) result.tags.addAll(tags);
    if (checksum != null) result.checksum = checksum;
    return result;
  }

  AudioMetadata._();

  factory AudioMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioMetadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.pava.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'origName')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'filename')
    ..aOS(5, _omitFieldNames ? '' : 'mimeType')
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'uploaded',
        subBuilder: $0.Timestamp.create)
    ..aInt64(7, _omitFieldNames ? '' : 'duration')
    ..aInt64(8, _omitFieldNames ? '' : 'sizeBytes')
    ..pPS(9, _omitFieldNames ? '' : 'tags')
    ..aOS(10, _omitFieldNames ? '' : 'checksum')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMetadata clone() => AudioMetadata()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMetadata copyWith(void Function(AudioMetadata) updates) =>
      super.copyWith((message) => updates(message as AudioMetadata))
          as AudioMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioMetadata create() => AudioMetadata._();
  @$core.override
  AudioMetadata createEmptyInstance() => create();
  static $pb.PbList<AudioMetadata> createRepeated() =>
      $pb.PbList<AudioMetadata>();
  @$core.pragma('dart2js:noInline')
  static AudioMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioMetadata>(create);
  static AudioMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get origName => $_getSZ(1);
  @$pb.TagNumber(2)
  set origName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrigName() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrigName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get filename => $_getSZ(3);
  @$pb.TagNumber(4)
  set filename($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilename() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilename() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get mimeType => $_getSZ(4);
  @$pb.TagNumber(5)
  set mimeType($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMimeType() => $_has(4);
  @$pb.TagNumber(5)
  void clearMimeType() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Timestamp get uploaded => $_getN(5);
  @$pb.TagNumber(6)
  set uploaded($0.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasUploaded() => $_has(5);
  @$pb.TagNumber(6)
  void clearUploaded() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureUploaded() => $_ensure(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get duration => $_getI64(6);
  @$pb.TagNumber(7)
  set duration($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDuration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDuration() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get sizeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSizeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearSizeBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get tags => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get checksum => $_getSZ(9);
  @$pb.TagNumber(10)
  set checksum($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasChecksum() => $_has(9);
  @$pb.TagNumber(10)
  void clearChecksum() => $_clearField(10);
}

class AudioMetadataListResponse extends $pb.GeneratedMessage {
  factory AudioMetadataListResponse({
    $core.Iterable<AudioMetadata>? messages,
  }) {
    final result = create();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  AudioMetadataListResponse._();

  factory AudioMetadataListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioMetadataListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioMetadataListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.pava.v1'),
      createEmptyInstance: create)
    ..pc<AudioMetadata>(
        1, _omitFieldNames ? '' : 'messages', $pb.PbFieldType.PM,
        subBuilder: AudioMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMetadataListResponse clone() =>
      AudioMetadataListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMetadataListResponse copyWith(
          void Function(AudioMetadataListResponse) updates) =>
      super.copyWith((message) => updates(message as AudioMetadataListResponse))
          as AudioMetadataListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioMetadataListResponse create() => AudioMetadataListResponse._();
  @$core.override
  AudioMetadataListResponse createEmptyInstance() => create();
  static $pb.PbList<AudioMetadataListResponse> createRepeated() =>
      $pb.PbList<AudioMetadataListResponse>();
  @$core.pragma('dart2js:noInline')
  static AudioMetadataListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioMetadataListResponse>(create);
  static AudioMetadataListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AudioMetadata> get messages => $_getList(0);
}

class AudioTagListResponse extends $pb.GeneratedMessage {
  factory AudioTagListResponse({
    $core.Iterable<$core.String>? tags,
  }) {
    final result = create();
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  AudioTagListResponse._();

  factory AudioTagListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioTagListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioTagListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.pava.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTagListResponse clone() =>
      AudioTagListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTagListResponse copyWith(void Function(AudioTagListResponse) updates) =>
      super.copyWith((message) => updates(message as AudioTagListResponse))
          as AudioTagListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioTagListResponse create() => AudioTagListResponse._();
  @$core.override
  AudioTagListResponse createEmptyInstance() => create();
  static $pb.PbList<AudioTagListResponse> createRepeated() =>
      $pb.PbList<AudioTagListResponse>();
  @$core.pragma('dart2js:noInline')
  static AudioTagListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioTagListResponse>(create);
  static AudioTagListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get tags => $_getList(0);
}

class TriggerMessageRequest extends $pb.GeneratedMessage {
  factory TriggerMessageRequest({
    $core.int? priority,
    $core.Iterable<$core.String>? zones,
  }) {
    final result = create();
    if (priority != null) result.priority = priority;
    if (zones != null) result.zones.addAll(zones);
    return result;
  }

  TriggerMessageRequest._();

  factory TriggerMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TriggerMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TriggerMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion.pava.v1'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.O3)
    ..pPS(2, _omitFieldNames ? '' : 'zones')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TriggerMessageRequest clone() =>
      TriggerMessageRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TriggerMessageRequest copyWith(
          void Function(TriggerMessageRequest) updates) =>
      super.copyWith((message) => updates(message as TriggerMessageRequest))
          as TriggerMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TriggerMessageRequest create() => TriggerMessageRequest._();
  @$core.override
  TriggerMessageRequest createEmptyInstance() => create();
  static $pb.PbList<TriggerMessageRequest> createRepeated() =>
      $pb.PbList<TriggerMessageRequest>();
  @$core.pragma('dart2js:noInline')
  static TriggerMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TriggerMessageRequest>(create);
  static TriggerMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get priority => $_getIZ(0);
  @$pb.TagNumber(1)
  set priority($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPriority() => $_has(0);
  @$pb.TagNumber(1)
  void clearPriority() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get zones => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
