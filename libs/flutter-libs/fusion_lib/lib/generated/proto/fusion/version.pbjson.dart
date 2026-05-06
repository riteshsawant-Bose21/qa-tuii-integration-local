// This is a generated file - do not edit.
//
// Generated from fusion/version.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use endpointListResponseDescriptor instead')
const EndpointListResponse$json = {
  '1': 'EndpointListResponse',
  '2': [
    {'1': 'routes', '3': 1, '4': 3, '5': 9, '10': 'routes'},
  ],
};

/// Descriptor for `EndpointListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endpointListResponseDescriptor =
    $convert.base64Decode(
        'ChRFbmRwb2ludExpc3RSZXNwb25zZRIWCgZyb3V0ZXMYASADKAlSBnJvdXRlcw==');

@$core.Deprecated('Use serverInfoResponseDescriptor instead')
const ServerInfoResponse$json = {
  '1': 'ServerInfoResponse',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'commit', '3': 3, '4': 1, '5': 9, '10': 'commit'},
    {'1': 'build_time', '3': 4, '4': 1, '5': 9, '10': 'buildTime'},
    {'1': 'node_id', '3': 5, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'endpoints', '3': 6, '4': 3, '5': 9, '10': 'endpoints'},
    {'1': 'cluster_size', '3': 7, '4': 1, '5': 13, '10': 'clusterSize'},
  ],
};

/// Descriptor for `ServerInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoResponseDescriptor = $convert.base64Decode(
    'ChJTZXJ2ZXJJbmZvUmVzcG9uc2USEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgd2ZXJzaW9uGAIgAS'
    'gJUgd2ZXJzaW9uEhYKBmNvbW1pdBgDIAEoCVIGY29tbWl0Eh0KCmJ1aWxkX3RpbWUYBCABKAlS'
    'CWJ1aWxkVGltZRIXCgdub2RlX2lkGAUgASgJUgZub2RlSWQSHAoJZW5kcG9pbnRzGAYgAygJUg'
    'llbmRwb2ludHMSIQoMY2x1c3Rlcl9zaXplGAcgASgNUgtjbHVzdGVyU2l6ZQ==');

@$core.Deprecated('Use versionResponseDescriptor instead')
const VersionResponse$json = {
  '1': 'VersionResponse',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'commit', '3': 3, '4': 1, '5': 9, '10': 'commit'},
    {'1': 'build_time', '3': 4, '4': 1, '5': 9, '10': 'buildTime'},
  ],
};

/// Descriptor for `VersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionResponseDescriptor = $convert.base64Decode(
    'Cg9WZXJzaW9uUmVzcG9uc2USEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgd2ZXJzaW9uGAIgASgJUg'
    'd2ZXJzaW9uEhYKBmNvbW1pdBgDIAEoCVIGY29tbWl0Eh0KCmJ1aWxkX3RpbWUYBCABKAlSCWJ1'
    'aWxkVGltZQ==');
