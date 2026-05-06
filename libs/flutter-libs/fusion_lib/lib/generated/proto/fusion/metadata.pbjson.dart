// This is a generated file - do not edit.
//
// Generated from fusion/metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use versionInfoDescriptor instead')
const VersionInfo$json = {
  '1': 'VersionInfo',
  '2': [
    {'1': 'epoch', '3': 1, '4': 1, '5': 4, '10': 'epoch'},
    {'1': 'counter', '3': 2, '4': 1, '5': 4, '10': 'counter'},
    {'1': 'node_id', '3': 3, '4': 1, '5': 9, '10': 'nodeId'},
  ],
};

/// Descriptor for `VersionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionInfoDescriptor = $convert.base64Decode(
    'CgtWZXJzaW9uSW5mbxIUCgVlcG9jaBgBIAEoBFIFZXBvY2gSGAoHY291bnRlchgCIAEoBFIHY2'
    '91bnRlchIXCgdub2RlX2lkGAMgASgJUgZub2RlSWQ=');

@$core.Deprecated('Use databaseMetadataDescriptor instead')
const DatabaseMetadata$json = {
  '1': 'DatabaseMetadata',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fusion.metadata.v1.VersionInfo',
      '10': 'version'
    },
    {'1': 'active_snapshot', '3': 2, '4': 1, '5': 9, '10': 'activeSnapshot'},
    {'1': 'hash', '3': 3, '4': 1, '5': 9, '10': 'hash'},
    {'1': 'valid', '3': 4, '4': 1, '5': 8, '10': 'valid'},
  ],
};

/// Descriptor for `DatabaseMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List databaseMetadataDescriptor = $convert.base64Decode(
    'ChBEYXRhYmFzZU1ldGFkYXRhEjkKB3ZlcnNpb24YASABKAsyHy5mdXNpb24ubWV0YWRhdGEudj'
    'EuVmVyc2lvbkluZm9SB3ZlcnNpb24SJwoPYWN0aXZlX3NuYXBzaG90GAIgASgJUg5hY3RpdmVT'
    'bmFwc2hvdBISCgRoYXNoGAMgASgJUgRoYXNoEhQKBXZhbGlkGAQgASgIUgV2YWxpZA==');

@$core.Deprecated('Use databaseMetadataResponseDescriptor instead')
const DatabaseMetadataResponse$json = {
  '1': 'DatabaseMetadataResponse',
  '2': [
    {
      '1': 'metadata',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fusion.metadata.v1.DatabaseMetadata',
      '10': 'metadata'
    },
  ],
};

/// Descriptor for `DatabaseMetadataResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List databaseMetadataResponseDescriptor =
    $convert.base64Decode(
        'ChhEYXRhYmFzZU1ldGFkYXRhUmVzcG9uc2USQAoIbWV0YWRhdGEYASABKAsyJC5mdXNpb24ubW'
        'V0YWRhdGEudjEuRGF0YWJhc2VNZXRhZGF0YVIIbWV0YWRhdGE=');
