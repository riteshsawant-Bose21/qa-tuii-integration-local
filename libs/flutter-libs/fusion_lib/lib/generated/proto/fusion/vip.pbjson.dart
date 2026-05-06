// This is a generated file - do not edit.
//
// Generated from fusion/vip.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use currentVIPResponseDescriptor instead')
const CurrentVIPResponse$json = {
  '1': 'CurrentVIPResponse',
  '2': [
    {'1': 'local', '3': 1, '4': 1, '5': 9, '10': 'local'},
    {'1': 'vip', '3': 2, '4': 1, '5': 9, '10': 'vip'},
  ],
};

/// Descriptor for `CurrentVIPResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List currentVIPResponseDescriptor = $convert.base64Decode(
    'ChJDdXJyZW50VklQUmVzcG9uc2USFAoFbG9jYWwYASABKAlSBWxvY2FsEhAKA3ZpcBgCIAEoCV'
    'IDdmlw');

@$core.Deprecated('Use vIPNodeResultDescriptor instead')
const VIPNodeResult$json = {
  '1': 'VIPNodeResult',
  '2': [
    {'1': 'node', '3': 1, '4': 1, '5': 9, '10': 'node'},
    {'1': 'host', '3': 2, '4': 1, '5': 9, '10': 'host'},
    {'1': 'phase', '3': 3, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'success', '3': 4, '4': 1, '5': 8, '10': 'success'},
    {'1': 'status_code', '3': 5, '4': 1, '5': 5, '10': 'statusCode'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
    {
      '1': 'started_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'completed_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'completedAt'
    },
  ],
};

/// Descriptor for `VIPNodeResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vIPNodeResultDescriptor = $convert.base64Decode(
    'Cg1WSVBOb2RlUmVzdWx0EhIKBG5vZGUYASABKAlSBG5vZGUSEgoEaG9zdBgCIAEoCVIEaG9zdB'
    'IUCgVwaGFzZRgDIAEoCVIFcGhhc2USGAoHc3VjY2VzcxgEIAEoCFIHc3VjY2VzcxIfCgtzdGF0'
    'dXNfY29kZRgFIAEoBVIKc3RhdHVzQ29kZRIUCgVlcnJvchgGIAEoCVIFZXJyb3ISOQoKc3Rhcn'
    'RlZF9hdBgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0ZWRBdBI9Cgxj'
    'b21wbGV0ZWRfYXQYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtjb21wbGV0ZW'
    'RBdA==');

@$core.Deprecated('Use vIPOperationStatusDescriptor instead')
const VIPOperationStatus$json = {
  '1': 'VIPOperationStatus',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'desired_vip', '3': 2, '4': 1, '5': 9, '10': 'desiredVip'},
    {'1': 'status_host', '3': 3, '4': 1, '5': 9, '10': 'statusHost'},
    {'1': 'observed_vip', '3': 4, '4': 1, '5': 9, '10': 'observedVip'},
    {'1': 'observed_holder', '3': 5, '4': 1, '5': 9, '10': 'observedHolder'},
    {'1': 'phase', '3': 6, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'message', '3': 7, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'started_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'completed_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'completedAt'
    },
    {
      '1': 'node_results',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.fusion.vip.v1.VIPOperationStatus.NodeResultsEntry',
      '10': 'nodeResults'
    },
  ],
  '3': [VIPOperationStatus_NodeResultsEntry$json],
};

@$core.Deprecated('Use vIPOperationStatusDescriptor instead')
const VIPOperationStatus_NodeResultsEntry$json = {
  '1': 'NodeResultsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.vip.v1.VIPNodeResult',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `VIPOperationStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vIPOperationStatusDescriptor = $convert.base64Decode(
    'ChJWSVBPcGVyYXRpb25TdGF0dXMSDgoCaWQYASABKAlSAmlkEh8KC2Rlc2lyZWRfdmlwGAIgAS'
    'gJUgpkZXNpcmVkVmlwEh8KC3N0YXR1c19ob3N0GAMgASgJUgpzdGF0dXNIb3N0EiEKDG9ic2Vy'
    'dmVkX3ZpcBgEIAEoCVILb2JzZXJ2ZWRWaXASJwoPb2JzZXJ2ZWRfaG9sZGVyGAUgASgJUg5vYn'
    'NlcnZlZEhvbGRlchIUCgVwaGFzZRgGIAEoCVIFcGhhc2USGAoHbWVzc2FnZRgHIAEoCVIHbWVz'
    'c2FnZRI5CgpzdGFydGVkX2F0GAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3'
    'RhcnRlZEF0Ej0KDGNvbXBsZXRlZF9hdBgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh'
    'bXBSC2NvbXBsZXRlZEF0ElUKDG5vZGVfcmVzdWx0cxgKIAMoCzIyLmZ1c2lvbi52aXAudjEuVk'
    'lQT3BlcmF0aW9uU3RhdHVzLk5vZGVSZXN1bHRzRW50cnlSC25vZGVSZXN1bHRzGlwKEE5vZGVS'
    'ZXN1bHRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSMgoFdmFsdWUYAiABKAsyHC5mdXNpb24udm'
    'lwLnYxLlZJUE5vZGVSZXN1bHRSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use vIPApplyStatusDescriptor instead')
const VIPApplyStatus$json = {
  '1': 'VIPApplyStatus',
  '2': [
    {'1': 'desired_vip', '3': 1, '4': 1, '5': 9, '10': 'desiredVip'},
    {'1': 'phase', '3': 2, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'started_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'completed_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'completedAt'
    },
  ],
};

/// Descriptor for `VIPApplyStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vIPApplyStatusDescriptor = $convert.base64Decode(
    'Cg5WSVBBcHBseVN0YXR1cxIfCgtkZXNpcmVkX3ZpcBgBIAEoCVIKZGVzaXJlZFZpcBIUCgVwaG'
    'FzZRgCIAEoCVIFcGhhc2USGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZRI5CgpzdGFydGVkX2F0'
    'GAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRlZEF0Ej0KDGNvbXBsZX'
    'RlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSC2NvbXBsZXRlZEF0');
