// This is a generated file - do not edit.
//
// Generated from fusion/sessions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sAPSessionDescriptor instead')
const SAPSession$json = {
  '1': 'SAPSession',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'origin', '3': 2, '4': 1, '5': 9, '10': 'origin'},
    {
      '1': 'timestamp',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
    {
      '1': 'description',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'description'
    },
  ],
};

/// Descriptor for `SAPSession`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sAPSessionDescriptor = $convert.base64Decode(
    'CgpTQVBTZXNzaW9uEg4KAmlkGAEgASgJUgJpZBIWCgZvcmlnaW4YAiABKAlSBm9yaWdpbhI4Cg'
    'l0aW1lc3RhbXAYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgl0aW1lc3RhbXAS'
    'OQoLZGVzY3JpcHRpb24YBCABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgtkZXNjcmlwdG'
    'lvbg==');

@$core.Deprecated('Use sessionListResponseDescriptor instead')
const SessionListResponse$json = {
  '1': 'SessionListResponse',
  '2': [
    {
      '1': 'sessions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.sessions.v1.SessionListResponse.SessionsEntry',
      '10': 'sessions'
    },
  ],
  '3': [SessionListResponse_SessionsEntry$json],
};

@$core.Deprecated('Use sessionListResponseDescriptor instead')
const SessionListResponse_SessionsEntry$json = {
  '1': 'SessionsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.sessions.v1.SAPSession',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `SessionListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionListResponseDescriptor = $convert.base64Decode(
    'ChNTZXNzaW9uTGlzdFJlc3BvbnNlElEKCHNlc3Npb25zGAEgAygLMjUuZnVzaW9uLnNlc3Npb2'
    '5zLnYxLlNlc3Npb25MaXN0UmVzcG9uc2UuU2Vzc2lvbnNFbnRyeVIIc2Vzc2lvbnMaWwoNU2Vz'
    'c2lvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI0CgV2YWx1ZRgCIAEoCzIeLmZ1c2lvbi5zZX'
    'NzaW9ucy52MS5TQVBTZXNzaW9uUgV2YWx1ZToCOAE=');
