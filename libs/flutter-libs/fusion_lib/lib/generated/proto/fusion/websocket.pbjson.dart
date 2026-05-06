// This is a generated file - do not edit.
//
// Generated from fusion/websocket.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use webSocketRequestDescriptor instead')
const WebSocketRequest$json = {
  '1': 'WebSocketRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'data',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'data'
    },
  ],
};

/// Descriptor for `WebSocketRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketRequestDescriptor = $convert.base64Decode(
    'ChBXZWJTb2NrZXRSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIYCgd2ZXJzaW9uGAIgASgFUgd2ZX'
    'JzaW9uEhIKBHR5cGUYAyABKAlSBHR5cGUSKgoEZGF0YRgEIAEoCzIWLmdvb2dsZS5wcm90b2J1'
    'Zi5WYWx1ZVIEZGF0YQ==');

@$core.Deprecated('Use webSocketResponseDescriptor instead')
const WebSocketResponse$json = {
  '1': 'WebSocketResponse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'id', '17': true},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'code', '3': 4, '4': 1, '5': 5, '10': 'code'},
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
    {'1': 'message', '3': 6, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'data',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'data'
    },
    {
      '1': 'timestamp',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
  ],
  '8': [
    {'1': '_id'},
  ],
};

/// Descriptor for `WebSocketResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketResponseDescriptor = $convert.base64Decode(
    'ChFXZWJTb2NrZXRSZXNwb25zZRITCgJpZBgBIAEoCUgAUgJpZIgBARIYCgd2ZXJzaW9uGAIgAS'
    'gFUgd2ZXJzaW9uEhIKBHR5cGUYAyABKAlSBHR5cGUSEgoEY29kZRgEIAEoBVIEY29kZRIWCgZz'
    'dGF0dXMYBSABKAlSBnN0YXR1cxIYCgdtZXNzYWdlGAYgASgJUgdtZXNzYWdlEioKBGRhdGEYBy'
    'ABKAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVSBGRhdGESOAoJdGltZXN0YW1wGAggASgLMhou'
    'Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdGltZXN0YW1wQgUKA19pZA==');

@$core.Deprecated('Use webSocketConfigUpdateEventDescriptor instead')
const WebSocketConfigUpdateEvent$json = {
  '1': 'WebSocketConfigUpdateEvent',
  '2': [
    {'1': 'mode', '3': 1, '4': 1, '5': 9, '10': 'mode'},
    {
      '1': 'updates',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'updates'
    },
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'state'
    },
    {'1': 'clear', '3': 4, '4': 1, '5': 8, '10': 'clear'},
  ],
};

/// Descriptor for `WebSocketConfigUpdateEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketConfigUpdateEventDescriptor = $convert.base64Decode(
    'ChpXZWJTb2NrZXRDb25maWdVcGRhdGVFdmVudBISCgRtb2RlGAEgASgJUgRtb2RlEjEKB3VwZG'
    'F0ZXMYAiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ugd1cGRhdGVzEi0KBXN0YXRlGAMg'
    'ASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIFc3RhdGUSFAoFY2xlYXIYBCABKAhSBWNsZW'
    'Fy');

@$core.Deprecated('Use webSocketDeviceLookupRequestDescriptor instead')
const WebSocketDeviceLookupRequest$json = {
  '1': 'WebSocketDeviceLookupRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `WebSocketDeviceLookupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketDeviceLookupRequestDescriptor =
    $convert.base64Decode(
        'ChxXZWJTb2NrZXREZXZpY2VMb29rdXBSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aW'
        'NlSWQ=');

@$core.Deprecated('Use webSocketUpdateDeviceInfoRequestDescriptor instead')
const WebSocketUpdateDeviceInfoRequest$json = {
  '1': 'WebSocketUpdateDeviceInfoRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'id', '17': true},
    {
      '1': 'location',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'location',
      '17': true
    },
    {'1': 'name', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'name', '17': true},
  ],
  '8': [
    {'1': '_id'},
    {'1': '_location'},
    {'1': '_name'},
  ],
};

/// Descriptor for `WebSocketUpdateDeviceInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketUpdateDeviceInfoRequestDescriptor =
    $convert.base64Decode(
        'CiBXZWJTb2NrZXRVcGRhdGVEZXZpY2VJbmZvUmVxdWVzdBIbCglkZXZpY2VfaWQYASABKAlSCG'
        'RldmljZUlkEhMKAmlkGAIgASgJSABSAmlkiAEBEh8KCGxvY2F0aW9uGAMgASgJSAFSCGxvY2F0'
        'aW9uiAEBEhcKBG5hbWUYBCABKAlIAlIEbmFtZYgBAUIFCgNfaWRCCwoJX2xvY2F0aW9uQgcKBV'
        '9uYW1l');
