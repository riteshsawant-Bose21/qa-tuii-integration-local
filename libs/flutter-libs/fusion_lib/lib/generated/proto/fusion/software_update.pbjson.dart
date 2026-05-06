// This is a generated file - do not edit.
//
// Generated from fusion/software_update.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use softwareUpdateBundleDescriptor instead')
const SoftwareUpdateBundle$json = {
  '1': 'SoftwareUpdateBundle',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'checksum', '3': 2, '4': 1, '5': 9, '10': 'checksum'},
    {'1': 'size_bytes', '3': 3, '4': 1, '5': 3, '10': 'sizeBytes'},
    {
      '1': 'uploaded',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'uploaded'
    },
    {'1': 'source_ip', '3': 5, '4': 1, '5': 9, '10': 'sourceIp'},
    {'1': 'sync_id', '3': 6, '4': 1, '5': 9, '10': 'syncId'},
  ],
};

/// Descriptor for `SoftwareUpdateBundle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List softwareUpdateBundleDescriptor = $convert.base64Decode(
    'ChRTb2Z0d2FyZVVwZGF0ZUJ1bmRsZRIaCghmaWxlbmFtZRgBIAEoCVIIZmlsZW5hbWUSGgoIY2'
    'hlY2tzdW0YAiABKAlSCGNoZWNrc3VtEh0KCnNpemVfYnl0ZXMYAyABKANSCXNpemVCeXRlcxI2'
    'Cgh1cGxvYWRlZBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCHVwbG9hZGVkEh'
    'sKCXNvdXJjZV9pcBgFIAEoCVIIc291cmNlSXASFwoHc3luY19pZBgGIAEoCVIGc3luY0lk');

@$core.Deprecated('Use softwareUpdateUploadResponseDescriptor instead')
const SoftwareUpdateUploadResponse$json = {
  '1': 'SoftwareUpdateUploadResponse',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'checksum', '3': 2, '4': 1, '5': 9, '10': 'checksum'},
    {'1': 'size_bytes', '3': 3, '4': 1, '5': 3, '10': 'sizeBytes'},
    {
      '1': 'uploaded',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'uploaded'
    },
  ],
};

/// Descriptor for `SoftwareUpdateUploadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List softwareUpdateUploadResponseDescriptor = $convert.base64Decode(
    'ChxTb2Z0d2FyZVVwZGF0ZVVwbG9hZFJlc3BvbnNlEhoKCGZpbGVuYW1lGAEgASgJUghmaWxlbm'
    'FtZRIaCghjaGVja3N1bRgCIAEoCVIIY2hlY2tzdW0SHQoKc2l6ZV9ieXRlcxgDIAEoA1IJc2l6'
    'ZUJ5dGVzEjYKCHVwbG9hZGVkGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIIdX'
    'Bsb2FkZWQ=');

@$core.Deprecated('Use softwareUpdateListResponseDescriptor instead')
const SoftwareUpdateListResponse$json = {
  '1': 'SoftwareUpdateListResponse',
  '2': [
    {
      '1': 'bundles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.softwareupdate.v1.SoftwareUpdateBundle',
      '10': 'bundles'
    },
  ],
};

/// Descriptor for `SoftwareUpdateListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List softwareUpdateListResponseDescriptor =
    $convert.base64Decode(
        'ChpTb2Z0d2FyZVVwZGF0ZUxpc3RSZXNwb25zZRJICgdidW5kbGVzGAEgAygLMi4uZnVzaW9uLn'
        'NvZnR3YXJldXBkYXRlLnYxLlNvZnR3YXJlVXBkYXRlQnVuZGxlUgdidW5kbGVz');

@$core.Deprecated('Use softwareUpdateErrorResponseDescriptor instead')
const SoftwareUpdateErrorResponse$json = {
  '1': 'SoftwareUpdateErrorResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 9, '10': 'error'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SoftwareUpdateErrorResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List softwareUpdateErrorResponseDescriptor =
    $convert.base64Decode(
        'ChtTb2Z0d2FyZVVwZGF0ZUVycm9yUmVzcG9uc2USFAoFZXJyb3IYASABKAlSBWVycm9yEhgKB2'
        '1lc3NhZ2UYAiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use swUpdateInfoDescriptor instead')
const SwUpdateInfo$json = {
  '1': 'SwUpdateInfo',
  '2': [
    {'1': 'serial_number', '3': 1, '4': 1, '5': 9, '10': 'serialNumber'},
    {
      '1': 'current_bundle_version',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'currentBundleVersion'
    },
    {
      '1': 'previous_bundle_version',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'previousBundleVersion'
    },
    {'1': 'mount', '3': 4, '4': 1, '5': 9, '10': 'mount'},
    {'1': 'previous_mount', '3': 5, '4': 1, '5': 9, '10': 'previousMount'},
    {'1': 'status', '3': 6, '4': 1, '5': 9, '10': 'status'},
    {'1': 'current_state', '3': 7, '4': 1, '5': 9, '10': 'currentState'},
    {'1': 'boot_partition', '3': 8, '4': 1, '5': 9, '10': 'bootPartition'},
    {
      '1': 'previous_boot_partition',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'previousBootPartition'
    },
    {'1': 'error', '3': 10, '4': 1, '5': 9, '10': 'error'},
    {'1': 'updated_at', '3': 11, '4': 1, '5': 9, '10': 'updatedAt'},
  ],
};

/// Descriptor for `SwUpdateInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List swUpdateInfoDescriptor = $convert.base64Decode(
    'CgxTd1VwZGF0ZUluZm8SIwoNc2VyaWFsX251bWJlchgBIAEoCVIMc2VyaWFsTnVtYmVyEjQKFm'
    'N1cnJlbnRfYnVuZGxlX3ZlcnNpb24YAiABKAlSFGN1cnJlbnRCdW5kbGVWZXJzaW9uEjYKF3By'
    'ZXZpb3VzX2J1bmRsZV92ZXJzaW9uGAMgASgJUhVwcmV2aW91c0J1bmRsZVZlcnNpb24SFAoFbW'
    '91bnQYBCABKAlSBW1vdW50EiUKDnByZXZpb3VzX21vdW50GAUgASgJUg1wcmV2aW91c01vdW50'
    'EhYKBnN0YXR1cxgGIAEoCVIGc3RhdHVzEiMKDWN1cnJlbnRfc3RhdGUYByABKAlSDGN1cnJlbn'
    'RTdGF0ZRIlCg5ib290X3BhcnRpdGlvbhgIIAEoCVINYm9vdFBhcnRpdGlvbhI2ChdwcmV2aW91'
    'c19ib290X3BhcnRpdGlvbhgJIAEoCVIVcHJldmlvdXNCb290UGFydGl0aW9uEhQKBWVycm9yGA'
    'ogASgJUgVlcnJvchIdCgp1cGRhdGVkX2F0GAsgASgJUgl1cGRhdGVkQXQ=');
