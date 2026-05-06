// This is a generated file - do not edit.
//
// Generated from fusion/pava.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use audioMetadataDescriptor instead')
const AudioMetadata$json = {
  '1': 'AudioMetadata',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'orig_name', '3': 2, '4': 1, '5': 9, '10': 'origName'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'filename', '3': 4, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'mime_type', '3': 5, '4': 1, '5': 9, '10': 'mimeType'},
    {
      '1': 'uploaded',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'uploaded'
    },
    {'1': 'duration', '3': 7, '4': 1, '5': 3, '10': 'duration'},
    {'1': 'size_bytes', '3': 8, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'tags', '3': 9, '4': 3, '5': 9, '10': 'tags'},
    {'1': 'checksum', '3': 10, '4': 1, '5': 9, '10': 'checksum'},
  ],
};

/// Descriptor for `AudioMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioMetadataDescriptor = $convert.base64Decode(
    'Cg1BdWRpb01ldGFkYXRhEg4KAmlkGAEgASgJUgJpZBIbCglvcmlnX25hbWUYAiABKAlSCG9yaW'
    'dOYW1lEiEKDGRpc3BsYXlfbmFtZRgDIAEoCVILZGlzcGxheU5hbWUSGgoIZmlsZW5hbWUYBCAB'
    'KAlSCGZpbGVuYW1lEhsKCW1pbWVfdHlwZRgFIAEoCVIIbWltZVR5cGUSNgoIdXBsb2FkZWQYBi'
    'ABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgh1cGxvYWRlZBIaCghkdXJhdGlvbhgH'
    'IAEoA1IIZHVyYXRpb24SHQoKc2l6ZV9ieXRlcxgIIAEoA1IJc2l6ZUJ5dGVzEhIKBHRhZ3MYCS'
    'ADKAlSBHRhZ3MSGgoIY2hlY2tzdW0YCiABKAlSCGNoZWNrc3Vt');

@$core.Deprecated('Use audioMetadataListResponseDescriptor instead')
const AudioMetadataListResponse$json = {
  '1': 'AudioMetadataListResponse',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.pava.v1.AudioMetadata',
      '10': 'messages'
    },
  ],
};

/// Descriptor for `AudioMetadataListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioMetadataListResponseDescriptor =
    $convert.base64Decode(
        'ChlBdWRpb01ldGFkYXRhTGlzdFJlc3BvbnNlEjkKCG1lc3NhZ2VzGAEgAygLMh0uZnVzaW9uLn'
        'BhdmEudjEuQXVkaW9NZXRhZGF0YVIIbWVzc2FnZXM=');

@$core.Deprecated('Use audioTagListResponseDescriptor instead')
const AudioTagListResponse$json = {
  '1': 'AudioTagListResponse',
  '2': [
    {'1': 'tags', '3': 1, '4': 3, '5': 9, '10': 'tags'},
  ],
};

/// Descriptor for `AudioTagListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioTagListResponseDescriptor = $convert
    .base64Decode('ChRBdWRpb1RhZ0xpc3RSZXNwb25zZRISCgR0YWdzGAEgAygJUgR0YWdz');

@$core.Deprecated('Use triggerMessageRequestDescriptor instead')
const TriggerMessageRequest$json = {
  '1': 'TriggerMessageRequest',
  '2': [
    {'1': 'priority', '3': 1, '4': 1, '5': 5, '10': 'priority'},
    {'1': 'zones', '3': 2, '4': 3, '5': 9, '10': 'zones'},
  ],
};

/// Descriptor for `TriggerMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List triggerMessageRequestDescriptor = $convert.base64Decode(
    'ChVUcmlnZ2VyTWVzc2FnZVJlcXVlc3QSGgoIcHJpb3JpdHkYASABKAVSCHByaW9yaXR5EhQKBX'
    'pvbmVzGAIgAygJUgV6b25lcw==');
