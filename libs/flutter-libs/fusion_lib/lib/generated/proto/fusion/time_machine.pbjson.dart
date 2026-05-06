// This is a generated file - do not edit.
//
// Generated from fusion/time_machine.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use snapshotDefinitionDescriptor instead')
const SnapshotDefinition$json = {
  '1': 'SnapshotDefinition',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'data',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'data'
    },
  ],
};

/// Descriptor for `SnapshotDefinition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotDefinitionDescriptor = $convert.base64Decode(
    'ChJTbmFwc2hvdERlZmluaXRpb24SDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USKwoEZGF0YRgDIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSBGRhdGE=');

@$core.Deprecated('Use sceneDescriptor instead')
const Scene$json = {
  '1': 'Scene',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'data',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'data'
    },
  ],
};

/// Descriptor for `Scene`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneDescriptor = $convert.base64Decode(
    'CgVTY2VuZRIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIrCgRkYXRhGAMgAS'
    'gLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIEZGF0YQ==');

@$core.Deprecated('Use sceneSetDescriptor instead')
const SceneSet$json = {
  '1': 'SceneSet',
  '2': [
    {'1': 'set_id', '3': 1, '4': 1, '5': 9, '10': 'setId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'default_scene', '3': 3, '4': 1, '5': 9, '10': 'defaultScene'},
    {'1': 'current_scene_id', '3': 4, '4': 1, '5': 9, '10': 'currentSceneId'},
    {
      '1': 'scenes',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fusion.snapshots.v1.Scene',
      '10': 'scenes'
    },
  ],
};

/// Descriptor for `SceneSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneSetDescriptor = $convert.base64Decode(
    'CghTY2VuZVNldBIVCgZzZXRfaWQYASABKAlSBXNldElkEhIKBG5hbWUYAiABKAlSBG5hbWUSIw'
    'oNZGVmYXVsdF9zY2VuZRgDIAEoCVIMZGVmYXVsdFNjZW5lEigKEGN1cnJlbnRfc2NlbmVfaWQY'
    'BCABKAlSDmN1cnJlbnRTY2VuZUlkEjIKBnNjZW5lcxgFIAMoCzIaLmZ1c2lvbi5zbmFwc2hvdH'
    'MudjEuU2NlbmVSBnNjZW5lcw==');

@$core.Deprecated('Use activateSnapshotRequestDescriptor instead')
const ActivateSnapshotRequest$json = {
  '1': 'ActivateSnapshotRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ActivateSnapshotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activateSnapshotRequestDescriptor = $convert
    .base64Decode('ChdBY3RpdmF0ZVNuYXBzaG90UmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use activateSceneSetRequestDescriptor instead')
const ActivateSceneSetRequest$json = {
  '1': 'ActivateSceneSetRequest',
  '2': [
    {'1': 'set_id', '3': 1, '4': 1, '5': 9, '10': 'setId'},
    {'1': 'scene_id', '3': 2, '4': 1, '5': 9, '10': 'sceneId'},
  ],
};

/// Descriptor for `ActivateSceneSetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activateSceneSetRequestDescriptor =
    $convert.base64Decode(
        'ChdBY3RpdmF0ZVNjZW5lU2V0UmVxdWVzdBIVCgZzZXRfaWQYASABKAlSBXNldElkEhkKCHNjZW'
        '5lX2lkGAIgASgJUgdzY2VuZUlk');

@$core.Deprecated('Use currentSceneRequestDescriptor instead')
const CurrentSceneRequest$json = {
  '1': 'CurrentSceneRequest',
  '2': [
    {'1': 'set_id', '3': 1, '4': 1, '5': 9, '10': 'setId'},
  ],
};

/// Descriptor for `CurrentSceneRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List currentSceneRequestDescriptor =
    $convert.base64Decode(
        'ChNDdXJyZW50U2NlbmVSZXF1ZXN0EhUKBnNldF9pZBgBIAEoCVIFc2V0SWQ=');

@$core.Deprecated('Use currentSceneMetadataDescriptor instead')
const CurrentSceneMetadata$json = {
  '1': 'CurrentSceneMetadata',
  '2': [
    {'1': 'scene_id', '3': 1, '4': 1, '5': 9, '10': 'sceneId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CurrentSceneMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List currentSceneMetadataDescriptor = $convert.base64Decode(
    'ChRDdXJyZW50U2NlbmVNZXRhZGF0YRIZCghzY2VuZV9pZBgBIAEoCVIHc2NlbmVJZBISCgRuYW'
    '1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use currentSceneResponseDescriptor instead')
const CurrentSceneResponse$json = {
  '1': 'CurrentSceneResponse',
  '2': [
    {'1': 'set_id', '3': 1, '4': 1, '5': 9, '10': 'setId'},
    {
      '1': 'current_scene',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.snapshots.v1.CurrentSceneMetadata',
      '10': 'currentScene'
    },
  ],
};

/// Descriptor for `CurrentSceneResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List currentSceneResponseDescriptor = $convert.base64Decode(
    'ChRDdXJyZW50U2NlbmVSZXNwb25zZRIVCgZzZXRfaWQYASABKAlSBXNldElkEk4KDWN1cnJlbn'
    'Rfc2NlbmUYAiABKAsyKS5mdXNpb24uc25hcHNob3RzLnYxLkN1cnJlbnRTY2VuZU1ldGFkYXRh'
    'UgxjdXJyZW50U2NlbmU=');

@$core.Deprecated('Use snapshotDefinitionListResponseDescriptor instead')
const SnapshotDefinitionListResponse$json = {
  '1': 'SnapshotDefinitionListResponse',
  '2': [
    {
      '1': 'snapshots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.snapshots.v1.SnapshotDefinition',
      '10': 'snapshots'
    },
  ],
};

/// Descriptor for `SnapshotDefinitionListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotDefinitionListResponseDescriptor =
    $convert.base64Decode(
        'Ch5TbmFwc2hvdERlZmluaXRpb25MaXN0UmVzcG9uc2USRQoJc25hcHNob3RzGAEgAygLMicuZn'
        'VzaW9uLnNuYXBzaG90cy52MS5TbmFwc2hvdERlZmluaXRpb25SCXNuYXBzaG90cw==');

@$core.Deprecated('Use sceneListResponseDescriptor instead')
const SceneListResponse$json = {
  '1': 'SceneListResponse',
  '2': [
    {
      '1': 'scenes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.snapshots.v1.Scene',
      '10': 'scenes'
    },
  ],
};

/// Descriptor for `SceneListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneListResponseDescriptor = $convert.base64Decode(
    'ChFTY2VuZUxpc3RSZXNwb25zZRIyCgZzY2VuZXMYASADKAsyGi5mdXNpb24uc25hcHNob3RzLn'
    'YxLlNjZW5lUgZzY2VuZXM=');

@$core.Deprecated('Use sceneSetListResponseDescriptor instead')
const SceneSetListResponse$json = {
  '1': 'SceneSetListResponse',
  '2': [
    {
      '1': 'scene_sets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.snapshots.v1.SceneSet',
      '10': 'sceneSets'
    },
  ],
};

/// Descriptor for `SceneSetListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneSetListResponseDescriptor = $convert.base64Decode(
    'ChRTY2VuZVNldExpc3RSZXNwb25zZRI8CgpzY2VuZV9zZXRzGAEgAygLMh0uZnVzaW9uLnNuYX'
    'BzaG90cy52MS5TY2VuZVNldFIJc2NlbmVTZXRz');

@$core.Deprecated('Use sceneCatalogListResponseDescriptor instead')
const SceneCatalogListResponse$json = {
  '1': 'SceneCatalogListResponse',
  '2': [
    {
      '1': 'snapshots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.snapshots.v1.SnapshotDefinition',
      '10': 'snapshots'
    },
    {
      '1': 'scene_sets',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fusion.snapshots.v1.SceneSet',
      '10': 'sceneSets'
    },
  ],
};

/// Descriptor for `SceneCatalogListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneCatalogListResponseDescriptor = $convert.base64Decode(
    'ChhTY2VuZUNhdGFsb2dMaXN0UmVzcG9uc2USRQoJc25hcHNob3RzGAEgAygLMicuZnVzaW9uLn'
    'NuYXBzaG90cy52MS5TbmFwc2hvdERlZmluaXRpb25SCXNuYXBzaG90cxI8CgpzY2VuZV9zZXRz'
    'GAIgAygLMh0uZnVzaW9uLnNuYXBzaG90cy52MS5TY2VuZVNldFIJc2NlbmVTZXRz');

@$core.Deprecated('Use timeMachineListResponseDescriptor instead')
const TimeMachineListResponse$json = {
  '1': 'TimeMachineListResponse',
  '2': [
    {'1': 'snapshots', '3': 1, '4': 3, '5': 9, '10': 'snapshots'},
  ],
};

/// Descriptor for `TimeMachineListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeMachineListResponseDescriptor =
    $convert.base64Decode(
        'ChdUaW1lTWFjaGluZUxpc3RSZXNwb25zZRIcCglzbmFwc2hvdHMYASADKAlSCXNuYXBzaG90cw'
        '==');

@$core.Deprecated('Use activeTimeMachineResponseDescriptor instead')
const ActiveTimeMachineResponse$json = {
  '1': 'ActiveTimeMachineResponse',
  '2': [
    {'1': 'active_snapshot', '3': 1, '4': 1, '5': 9, '10': 'activeSnapshot'},
  ],
};

/// Descriptor for `ActiveTimeMachineResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeTimeMachineResponseDescriptor =
    $convert.base64Decode(
        'ChlBY3RpdmVUaW1lTWFjaGluZVJlc3BvbnNlEicKD2FjdGl2ZV9zbmFwc2hvdBgBIAEoCVIOYW'
        'N0aXZlU25hcHNob3Q=');

@$core.Deprecated('Use timeMachineOperationStatusDescriptor instead')
const TimeMachineOperationStatus$json = {
  '1': 'TimeMachineOperationStatus',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `TimeMachineOperationStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeMachineOperationStatusDescriptor =
    $convert.base64Decode(
        'ChpUaW1lTWFjaGluZU9wZXJhdGlvblN0YXR1cxISCgRuYW1lGAEgASgJUgRuYW1lEhYKBnN0YX'
        'R1cxgCIAEoCVIGc3RhdHVz');
