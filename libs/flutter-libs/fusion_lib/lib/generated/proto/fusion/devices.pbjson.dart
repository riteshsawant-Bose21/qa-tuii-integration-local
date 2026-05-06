// This is a generated file - do not edit.
//
// Generated from fusion/devices.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use deviceInfoDescriptor instead')
const DeviceInfo$json = {
  '1': 'DeviceInfo',
  '2': [
    {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'location', '3': 3, '4': 1, '5': 9, '10': 'location'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'model_name', '3': 5, '4': 1, '5': 9, '10': 'modelName'},
    {'1': 'mac_address', '3': 6, '4': 1, '5': 9, '10': 'macAddress'},
    {'1': 'serial_number', '3': 7, '4': 1, '5': 9, '10': 'serialNumber'},
    {'1': 'is_primary', '3': 8, '4': 1, '5': 8, '10': 'isPrimary'},
    {'1': 'firmware_version', '3': 9, '4': 1, '5': 9, '10': 'firmwareVersion'},
    {
      '1': 'is_device_certificate_valid',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'isDeviceCertificateValid'
    },
  ],
};

/// Descriptor for `DeviceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceInfoDescriptor = $convert.base64Decode(
    'CgpEZXZpY2VJbmZvEhgKB2FkZHJlc3MYASABKAlSB2FkZHJlc3MSDgoCaWQYAiABKAlSAmlkEh'
    'oKCGxvY2F0aW9uGAMgASgJUghsb2NhdGlvbhISCgRuYW1lGAQgASgJUgRuYW1lEh0KCm1vZGVs'
    'X25hbWUYBSABKAlSCW1vZGVsTmFtZRIfCgttYWNfYWRkcmVzcxgGIAEoCVIKbWFjQWRkcmVzcx'
    'IjCg1zZXJpYWxfbnVtYmVyGAcgASgJUgxzZXJpYWxOdW1iZXISHQoKaXNfcHJpbWFyeRgIIAEo'
    'CFIJaXNQcmltYXJ5EikKEGZpcm13YXJlX3ZlcnNpb24YCSABKAlSD2Zpcm13YXJlVmVyc2lvbh'
    'I9Chtpc19kZXZpY2VfY2VydGlmaWNhdGVfdmFsaWQYCiABKAhSGGlzRGV2aWNlQ2VydGlmaWNh'
    'dGVWYWxpZA==');

@$core.Deprecated('Use devicePatchDescriptor instead')
const DevicePatch$json = {
  '1': 'DevicePatch',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'id', '17': true},
    {
      '1': 'location',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'location',
      '17': true
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'name', '17': true},
  ],
  '8': [
    {'1': '_id'},
    {'1': '_location'},
    {'1': '_name'},
  ],
};

/// Descriptor for `DevicePatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List devicePatchDescriptor = $convert.base64Decode(
    'CgtEZXZpY2VQYXRjaBITCgJpZBgBIAEoCUgAUgJpZIgBARIfCghsb2NhdGlvbhgCIAEoCUgBUg'
    'hsb2NhdGlvbogBARIXCgRuYW1lGAMgASgJSAJSBG5hbWWIAQFCBQoDX2lkQgsKCV9sb2NhdGlv'
    'bkIHCgVfbmFtZQ==');

@$core.Deprecated('Use deviceListResponseDescriptor instead')
const DeviceListResponse$json = {
  '1': 'DeviceListResponse',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.devices.v1.DeviceInfo',
      '10': 'devices'
    },
  ],
};

/// Descriptor for `DeviceListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceListResponseDescriptor = $convert.base64Decode(
    'ChJEZXZpY2VMaXN0UmVzcG9uc2USNwoHZGV2aWNlcxgBIAMoCzIdLmZ1c2lvbi5kZXZpY2VzLn'
    'YxLkRldmljZUluZm9SB2RldmljZXM=');
