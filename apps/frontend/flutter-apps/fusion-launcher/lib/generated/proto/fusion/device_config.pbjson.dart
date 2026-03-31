// This is a generated file - do not edit.
//
// Generated from fusion/device_config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use droConditionedOutputEnvelopeDescriptor instead')
const DroConditionedOutputEnvelope$json = {
  '1': 'DroConditionedOutputEnvelope',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'response_id', '3': 2, '4': 1, '5': 9, '10': 'responseId'},
    {'1': 'status_code', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    {'1': 'status_message', '3': 4, '4': 1, '5': 9, '10': 'statusMessage'},
    {'1': 'version', '3': 5, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'result',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroConditionedOutput',
      '10': 'result'
    },
  ],
};

/// Descriptor for `DroConditionedOutputEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droConditionedOutputEnvelopeDescriptor = $convert.base64Decode(
    'ChxEcm9Db25kaXRpb25lZE91dHB1dEVudmVsb3BlEh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcX'
    'Vlc3RJZBIfCgtyZXNwb25zZV9pZBgCIAEoCVIKcmVzcG9uc2VJZBIfCgtzdGF0dXNfY29kZRgD'
    'IAEoBVIKc3RhdHVzQ29kZRIlCg5zdGF0dXNfbWVzc2FnZRgEIAEoCVINc3RhdHVzTWVzc2FnZR'
    'IYCgd2ZXJzaW9uGAUgASgJUgd2ZXJzaW9uEkQKBnJlc3VsdBgGIAEoCzIsLmZ1c2lvbi5kZXZp'
    'Y2Vjb25maWcudjEuRHJvQ29uZGl0aW9uZWRPdXRwdXRSBnJlc3VsdA==');

@$core.Deprecated('Use droConditionedOutputDescriptor instead')
const DroConditionedOutput$json = {
  '1': 'DroConditionedOutput',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroConditionedDevice',
      '10': 'devices'
    },
    {
      '1': 'aes67_streams',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroAes67Stream',
      '10': 'aes67Streams'
    },
    {
      '1': 'device_connections',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroDeviceConnection',
      '10': 'deviceConnections'
    },
    {
      '1': 'io_ports',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroIoPort',
      '10': 'ioPorts'
    },
    {
      '1': 'latencies',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroLatency',
      '10': 'latencies'
    },
    {'1': 'total_cost', '3': 6, '4': 1, '5': 1, '10': 'totalCost'},
  ],
};

/// Descriptor for `DroConditionedOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droConditionedOutputDescriptor = $convert.base64Decode(
    'ChREcm9Db25kaXRpb25lZE91dHB1dBJGCgdkZXZpY2VzGAEgAygLMiwuZnVzaW9uLmRldmljZW'
    'NvbmZpZy52MS5Ecm9Db25kaXRpb25lZERldmljZVIHZGV2aWNlcxJLCg1hZXM2N19zdHJlYW1z'
    'GAIgAygLMiYuZnVzaW9uLmRldmljZWNvbmZpZy52MS5Ecm9BZXM2N1N0cmVhbVIMYWVzNjdTdH'
    'JlYW1zEloKEmRldmljZV9jb25uZWN0aW9ucxgDIAMoCzIrLmZ1c2lvbi5kZXZpY2Vjb25maWcu'
    'djEuRHJvRGV2aWNlQ29ubmVjdGlvblIRZGV2aWNlQ29ubmVjdGlvbnMSPAoIaW9fcG9ydHMYBC'
    'ADKAsyIS5mdXNpb24uZGV2aWNlY29uZmlnLnYxLkRyb0lvUG9ydFIHaW9Qb3J0cxJACglsYXRl'
    'bmNpZXMYBSADKAsyIi5mdXNpb24uZGV2aWNlY29uZmlnLnYxLkRyb0xhdGVuY3lSCWxhdGVuY2'
    'llcxIdCgp0b3RhbF9jb3N0GAYgASgBUgl0b3RhbENvc3Q=');

@$core.Deprecated('Use deviceConfigurationPackageDescriptor instead')
const DeviceConfigurationPackage$json = {
  '1': 'DeviceConfigurationPackage',
  '2': [
    {
      '1': 'dro_conditioned_output',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroConditionedOutput',
      '10': 'droConditionedOutput'
    },
    {
      '1': 'fusion_connect_additions',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.FusionConnectAdditions',
      '10': 'fusionConnectAdditions'
    },
  ],
};

/// Descriptor for `DeviceConfigurationPackage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceConfigurationPackageDescriptor = $convert.base64Decode(
    'ChpEZXZpY2VDb25maWd1cmF0aW9uUGFja2FnZRJiChZkcm9fY29uZGl0aW9uZWRfb3V0cHV0GA'
    'EgASgLMiwuZnVzaW9uLmRldmljZWNvbmZpZy52MS5Ecm9Db25kaXRpb25lZE91dHB1dFIUZHJv'
    'Q29uZGl0aW9uZWRPdXRwdXQSaAoYZnVzaW9uX2Nvbm5lY3RfYWRkaXRpb25zGAIgASgLMi4uZn'
    'VzaW9uLmRldmljZWNvbmZpZy52MS5GdXNpb25Db25uZWN0QWRkaXRpb25zUhZmdXNpb25Db25u'
    'ZWN0QWRkaXRpb25z');

@$core.Deprecated('Use fusionConnectAdditionsDescriptor instead')
const FusionConnectAdditions$json = {
  '1': 'FusionConnectAdditions',
  '2': [
    {
      '1': 'audio_streams',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.FusionConnectAudioStream',
      '10': 'audioStreams'
    },
    {
      '1': 'settings',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.FusionConnectAudioSettings',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `FusionConnectAdditions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionConnectAdditionsDescriptor = $convert.base64Decode(
    'ChZGdXNpb25Db25uZWN0QWRkaXRpb25zElUKDWF1ZGlvX3N0cmVhbXMYASADKAsyMC5mdXNpb2'
    '4uZGV2aWNlY29uZmlnLnYxLkZ1c2lvbkNvbm5lY3RBdWRpb1N0cmVhbVIMYXVkaW9TdHJlYW1z'
    'Ek4KCHNldHRpbmdzGAIgASgLMjIuZnVzaW9uLmRldmljZWNvbmZpZy52MS5GdXNpb25Db25uZW'
    'N0QXVkaW9TZXR0aW5nc1IIc2V0dGluZ3M=');

@$core.Deprecated('Use droConditionedDeviceDescriptor instead')
const DroConditionedDevice$json = {
  '1': 'DroConditionedDevice',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'device_type', '3': 3, '4': 1, '5': 9, '10': 'deviceType'},
    {'1': 'location', '3': 4, '4': 1, '5': 9, '10': 'location'},
    {'1': 'cost', '3': 5, '4': 1, '5': 1, '10': 'cost'},
    {
      '1': 'cores',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroCore',
      '10': 'cores'
    },
    {
      '1': 'connections_device_in',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.google.protobuf.ListValue',
      '10': 'connectionsDeviceIn'
    },
    {
      '1': 'connections_device_out',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.google.protobuf.ListValue',
      '10': 'connectionsDeviceOut'
    },
    {
      '1': 'dsp_static_config',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.StaticConfiguration',
      '10': 'dspStaticConfig'
    },
  ],
};

/// Descriptor for `DroConditionedDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droConditionedDeviceDescriptor = $convert.base64Decode(
    'ChREcm9Db25kaXRpb25lZERldmljZRIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBW'
    'xhYmVsEh8KC2RldmljZV90eXBlGAMgASgJUgpkZXZpY2VUeXBlEhoKCGxvY2F0aW9uGAQgASgJ'
    'Ughsb2NhdGlvbhISCgRjb3N0GAUgASgBUgRjb3N0EjUKBWNvcmVzGAYgAygLMh8uZnVzaW9uLm'
    'RldmljZWNvbmZpZy52MS5Ecm9Db3JlUgVjb3JlcxJOChVjb25uZWN0aW9uc19kZXZpY2VfaW4Y'
    'ByADKAsyGi5nb29nbGUucHJvdG9idWYuTGlzdFZhbHVlUhNjb25uZWN0aW9uc0RldmljZUluEl'
    'AKFmNvbm5lY3Rpb25zX2RldmljZV9vdXQYCCADKAsyGi5nb29nbGUucHJvdG9idWYuTGlzdFZh'
    'bHVlUhRjb25uZWN0aW9uc0RldmljZU91dBJXChFkc3Bfc3RhdGljX2NvbmZpZxgJIAEoCzIrLm'
    'Z1c2lvbi5kZXZpY2Vjb25maWcudjEuU3RhdGljQ29uZmlndXJhdGlvblIPZHNwU3RhdGljQ29u'
    'Zmln');

@$core.Deprecated('Use droCoreDescriptor instead')
const DroCore$json = {
  '1': 'DroCore',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'util_algs', '3': 2, '4': 1, '5': 1, '10': 'utilAlgs'},
    {
      '1': 'util_device_connect',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'utilDeviceConnect'
    },
    {'1': 'util_task_connect', '3': 4, '4': 1, '5': 1, '10': 'utilTaskConnect'},
    {'1': 'util_total', '3': 5, '4': 1, '5': 1, '10': 'utilTotal'},
    {'1': 'block_ids', '3': 6, '4': 3, '5': 9, '10': 'blockIds'},
  ],
};

/// Descriptor for `DroCore`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droCoreDescriptor = $convert.base64Decode(
    'CgdEcm9Db3JlEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIbCgl1dGlsX2FsZ3MYAiABKAFSCHV0aW'
    'xBbGdzEi4KE3V0aWxfZGV2aWNlX2Nvbm5lY3QYAyABKAFSEXV0aWxEZXZpY2VDb25uZWN0EioK'
    'EXV0aWxfdGFza19jb25uZWN0GAQgASgBUg91dGlsVGFza0Nvbm5lY3QSHQoKdXRpbF90b3RhbB'
    'gFIAEoAVIJdXRpbFRvdGFsEhsKCWJsb2NrX2lkcxgGIAMoCVIIYmxvY2tJZHM=');

@$core.Deprecated('Use droAes67StreamDescriptor instead')
const DroAes67Stream$json = {
  '1': 'DroAes67Stream',
  '2': [
    {'1': 'stream_id', '3': 1, '4': 1, '5': 9, '10': 'streamId'},
    {'1': 'stream_name', '3': 2, '4': 1, '5': 9, '10': 'streamName'},
    {'1': 'direction', '3': 3, '4': 1, '5': 9, '10': 'direction'},
    {
      '1': 'multicast_destination_ip',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'multicastDestinationIp'
    },
    {'1': 'source_device', '3': 5, '4': 1, '5': 9, '10': 'sourceDevice'},
    {'1': 'channels', '3': 6, '4': 1, '5': 13, '10': 'channels'},
    {'1': 'description', '3': 7, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'destination_device',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'destinationDevice'
    },
  ],
};

/// Descriptor for `DroAes67Stream`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droAes67StreamDescriptor = $convert.base64Decode(
    'Cg5Ecm9BZXM2N1N0cmVhbRIbCglzdHJlYW1faWQYASABKAlSCHN0cmVhbUlkEh8KC3N0cmVhbV'
    '9uYW1lGAIgASgJUgpzdHJlYW1OYW1lEhwKCWRpcmVjdGlvbhgDIAEoCVIJZGlyZWN0aW9uEjgK'
    'GG11bHRpY2FzdF9kZXN0aW5hdGlvbl9pcBgEIAEoCVIWbXVsdGljYXN0RGVzdGluYXRpb25JcB'
    'IjCg1zb3VyY2VfZGV2aWNlGAUgASgJUgxzb3VyY2VEZXZpY2USGgoIY2hhbm5lbHMYBiABKA1S'
    'CGNoYW5uZWxzEiAKC2Rlc2NyaXB0aW9uGAcgASgJUgtkZXNjcmlwdGlvbhItChJkZXN0aW5hdG'
    'lvbl9kZXZpY2UYCCABKAlSEWRlc3RpbmF0aW9uRGV2aWNl');

@$core.Deprecated('Use droDeviceConnectionDescriptor instead')
const DroDeviceConnection$json = {
  '1': 'DroDeviceConnection',
  '2': [
    {'1': 'source_device', '3': 1, '4': 1, '5': 9, '10': 'sourceDevice'},
    {
      '1': 'destination_device',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'destinationDevice'
    },
    {'1': 'channels', '3': 3, '4': 1, '5': 13, '10': 'channels'},
    {'1': 'source_port', '3': 4, '4': 1, '5': 9, '10': 'sourcePort'},
  ],
};

/// Descriptor for `DroDeviceConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droDeviceConnectionDescriptor = $convert.base64Decode(
    'ChNEcm9EZXZpY2VDb25uZWN0aW9uEiMKDXNvdXJjZV9kZXZpY2UYASABKAlSDHNvdXJjZURldm'
    'ljZRItChJkZXN0aW5hdGlvbl9kZXZpY2UYAiABKAlSEWRlc3RpbmF0aW9uRGV2aWNlEhoKCGNo'
    'YW5uZWxzGAMgASgNUghjaGFubmVscxIfCgtzb3VyY2VfcG9ydBgEIAEoCVIKc291cmNlUG9ydA'
    '==');

@$core.Deprecated('Use droIoPortDescriptor instead')
const DroIoPort$json = {
  '1': 'DroIoPort',
  '2': [
    {'1': 'io_id', '3': 1, '4': 1, '5': 9, '10': 'ioId'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'port_type', '3': 3, '4': 1, '5': 9, '10': 'portType'},
    {'1': 'port_nums', '3': 4, '4': 3, '5': 13, '10': 'portNums'},
  ],
};

/// Descriptor for `DroIoPort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droIoPortDescriptor = $convert.base64Decode(
    'CglEcm9Jb1BvcnQSEwoFaW9faWQYASABKAlSBGlvSWQSGwoJZGV2aWNlX2lkGAIgASgJUghkZX'
    'ZpY2VJZBIbCglwb3J0X3R5cGUYAyABKAlSCHBvcnRUeXBlEhsKCXBvcnRfbnVtcxgEIAMoDVII'
    'cG9ydE51bXM=');

@$core.Deprecated('Use droLatencyDescriptor instead')
const DroLatency$json = {
  '1': 'DroLatency',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.DroLatency.ValuesEntry',
      '10': 'values'
    },
  ],
  '3': [DroLatency_ValuesEntry$json],
};

@$core.Deprecated('Use droLatencyDescriptor instead')
const DroLatency_ValuesEntry$json = {
  '1': 'ValuesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `DroLatency`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List droLatencyDescriptor = $convert.base64Decode(
    'CgpEcm9MYXRlbmN5EkYKBnZhbHVlcxgBIAMoCzIuLmZ1c2lvbi5kZXZpY2Vjb25maWcudjEuRH'
    'JvTGF0ZW5jeS5WYWx1ZXNFbnRyeVIGdmFsdWVzGlEKC1ZhbHVlc0VudHJ5EhAKA2tleRgBIAEo'
    'CVIDa2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZToCOA'
    'E=');

@$core.Deprecated('Use fusionConnectAudioStreamDescriptor instead')
const FusionConnectAudioStream$json = {
  '1': 'FusionConnectAudioStream',
  '2': [
    {'1': 'source_device_uid', '3': 1, '4': 1, '5': 9, '10': 'sourceDeviceUid'},
    {'1': 'dest_device_uid', '3': 2, '4': 1, '5': 9, '10': 'destDeviceUid'},
    {
      '1': 'properties',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.FusionConnectAudioStreamProperties',
      '10': 'properties'
    },
  ],
};

/// Descriptor for `FusionConnectAudioStream`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionConnectAudioStreamDescriptor = $convert.base64Decode(
    'ChhGdXNpb25Db25uZWN0QXVkaW9TdHJlYW0SKgoRc291cmNlX2RldmljZV91aWQYASABKAlSD3'
    'NvdXJjZURldmljZVVpZBImCg9kZXN0X2RldmljZV91aWQYAiABKAlSDWRlc3REZXZpY2VVaWQS'
    'WgoKcHJvcGVydGllcxgDIAEoCzI6LmZ1c2lvbi5kZXZpY2Vjb25maWcudjEuRnVzaW9uQ29ubm'
    'VjdEF1ZGlvU3RyZWFtUHJvcGVydGllc1IKcHJvcGVydGllcw==');

@$core.Deprecated('Use fusionConnectAudioStreamPropertiesDescriptor instead')
const FusionConnectAudioStreamProperties$json = {
  '1': 'FusionConnectAudioStreamProperties',
  '2': [
    {'1': 'stream_name', '3': 1, '4': 1, '5': 9, '10': 'streamName'},
    {'1': 'dest_ip', '3': 2, '4': 1, '5': 9, '10': 'destIp'},
    {'1': 'channels', '3': 3, '4': 1, '5': 13, '10': 'channels'},
    {'1': 'source_port', '3': 4, '4': 1, '5': 13, '10': 'sourcePort'},
    {'1': 'is_source', '3': 5, '4': 1, '5': 8, '10': 'isSource'},
    {'1': 'is_fusion_connect', '3': 6, '4': 1, '5': 8, '10': 'isFusionConnect'},
  ],
};

/// Descriptor for `FusionConnectAudioStreamProperties`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionConnectAudioStreamPropertiesDescriptor =
    $convert.base64Decode(
        'CiJGdXNpb25Db25uZWN0QXVkaW9TdHJlYW1Qcm9wZXJ0aWVzEh8KC3N0cmVhbV9uYW1lGAEgAS'
        'gJUgpzdHJlYW1OYW1lEhcKB2Rlc3RfaXAYAiABKAlSBmRlc3RJcBIaCghjaGFubmVscxgDIAEo'
        'DVIIY2hhbm5lbHMSHwoLc291cmNlX3BvcnQYBCABKA1SCnNvdXJjZVBvcnQSGwoJaXNfc291cm'
        'NlGAUgASgIUghpc1NvdXJjZRIqChFpc19mdXNpb25fY29ubmVjdBgGIAEoCFIPaXNGdXNpb25D'
        'b25uZWN0');

@$core.Deprecated('Use fusionConnectAudioSettingsDescriptor instead')
const FusionConnectAudioSettings$json = {
  '1': 'FusionConnectAudioSettings',
  '2': [
    {
      '1': 'audio',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.FusionConnectAudioSettings.AudioEntry',
      '10': 'audio'
    },
  ],
  '3': [FusionConnectAudioSettings_AudioEntry$json],
};

@$core.Deprecated('Use fusionConnectAudioSettingsDescriptor instead')
const FusionConnectAudioSettings_AudioEntry$json = {
  '1': 'AudioEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.AudioBlockSettings',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `FusionConnectAudioSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionConnectAudioSettingsDescriptor = $convert.base64Decode(
    'ChpGdXNpb25Db25uZWN0QXVkaW9TZXR0aW5ncxJTCgVhdWRpbxgBIAMoCzI9LmZ1c2lvbi5kZX'
    'ZpY2Vjb25maWcudjEuRnVzaW9uQ29ubmVjdEF1ZGlvU2V0dGluZ3MuQXVkaW9FbnRyeVIFYXVk'
    'aW8aZAoKQXVkaW9FbnRyeRIQCgNrZXkYASABKAlSA2tleRJACgV2YWx1ZRgCIAEoCzIqLmZ1c2'
    'lvbi5kZXZpY2Vjb25maWcudjEuQXVkaW9CbG9ja1NldHRpbmdzUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use audioBlockSettingsDescriptor instead')
const AudioBlockSettings$json = {
  '1': 'AudioBlockSettings',
  '2': [
    {
      '1': 'parameters',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.AudioBlockSettings.ParametersEntry',
      '10': 'parameters'
    },
  ],
  '3': [AudioBlockSettings_ParametersEntry$json],
};

@$core.Deprecated('Use audioBlockSettingsDescriptor instead')
const AudioBlockSettings_ParametersEntry$json = {
  '1': 'ParametersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `AudioBlockSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioBlockSettingsDescriptor = $convert.base64Decode(
    'ChJBdWRpb0Jsb2NrU2V0dGluZ3MSWgoKcGFyYW1ldGVycxgBIAMoCzI6LmZ1c2lvbi5kZXZpY2'
    'Vjb25maWcudjEuQXVkaW9CbG9ja1NldHRpbmdzLlBhcmFtZXRlcnNFbnRyeVIKcGFyYW1ldGVy'
    'cxpVCg9QYXJhbWV0ZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLAoFdmFsdWUYAiABKAsyFi'
    '5nb29nbGUucHJvdG9idWYuVmFsdWVSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use staticConfigurationDescriptor instead')
const StaticConfiguration$json = {
  '1': 'StaticConfiguration',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.SessionConfiguration',
      '10': 'session'
    },
    {
      '1': 'audio_tasks',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.AudioTask',
      '10': 'audioTasks'
    },
    {
      '1': 'task_connections',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.TaskConnection',
      '10': 'taskConnections'
    },
    {
      '1': 'parameter_settings',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.ParameterSetting',
      '10': 'parameterSettings'
    },
  ],
};

/// Descriptor for `StaticConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List staticConfigurationDescriptor = $convert.base64Decode(
    'ChNTdGF0aWNDb25maWd1cmF0aW9uEkYKB3Nlc3Npb24YASABKAsyLC5mdXNpb24uZGV2aWNlY2'
    '9uZmlnLnYxLlNlc3Npb25Db25maWd1cmF0aW9uUgdzZXNzaW9uEkIKC2F1ZGlvX3Rhc2tzGAIg'
    'AygLMiEuZnVzaW9uLmRldmljZWNvbmZpZy52MS5BdWRpb1Rhc2tSCmF1ZGlvVGFza3MSUQoQdG'
    'Fza19jb25uZWN0aW9ucxgDIAMoCzImLmZ1c2lvbi5kZXZpY2Vjb25maWcudjEuVGFza0Nvbm5l'
    'Y3Rpb25SD3Rhc2tDb25uZWN0aW9ucxJXChJwYXJhbWV0ZXJfc2V0dGluZ3MYBCADKAsyKC5mdX'
    'Npb24uZGV2aWNlY29uZmlnLnYxLlBhcmFtZXRlclNldHRpbmdSEXBhcmFtZXRlclNldHRpbmdz');

@$core.Deprecated('Use sessionConfigurationDescriptor instead')
const SessionConfiguration$json = {
  '1': 'SessionConfiguration',
  '2': [
    {
      '1': 'property_settings',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.PropertySetting',
      '10': 'propertySettings'
    },
  ],
};

/// Descriptor for `SessionConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionConfigurationDescriptor = $convert.base64Decode(
    'ChRTZXNzaW9uQ29uZmlndXJhdGlvbhJUChFwcm9wZXJ0eV9zZXR0aW5ncxgBIAMoCzInLmZ1c2'
    'lvbi5kZXZpY2Vjb25maWcudjEuUHJvcGVydHlTZXR0aW5nUhBwcm9wZXJ0eVNldHRpbmdz');

@$core.Deprecated('Use audioTaskDescriptor instead')
const AudioTask$json = {
  '1': 'AudioTask',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'property_settings',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.PropertySetting',
      '10': 'propertySettings'
    },
    {
      '1': 'blocks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.Block',
      '10': 'blocks'
    },
    {
      '1': 'block_connections',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.BlockConnection',
      '10': 'blockConnections'
    },
  ],
};

/// Descriptor for `AudioTask`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioTaskDescriptor = $convert.base64Decode(
    'CglBdWRpb1Rhc2sSEgoEbmFtZRgBIAEoCVIEbmFtZRJUChFwcm9wZXJ0eV9zZXR0aW5ncxgCIA'
    'MoCzInLmZ1c2lvbi5kZXZpY2Vjb25maWcudjEuUHJvcGVydHlTZXR0aW5nUhBwcm9wZXJ0eVNl'
    'dHRpbmdzEjUKBmJsb2NrcxgDIAMoCzIdLmZ1c2lvbi5kZXZpY2Vjb25maWcudjEuQmxvY2tSBm'
    'Jsb2NrcxJUChFibG9ja19jb25uZWN0aW9ucxgEIAMoCzInLmZ1c2lvbi5kZXZpY2Vjb25maWcu'
    'djEuQmxvY2tDb25uZWN0aW9uUhBibG9ja0Nvbm5lY3Rpb25z');

@$core.Deprecated('Use blockDescriptor instead')
const Block$json = {
  '1': 'Block',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'algorithm', '3': 2, '4': 1, '5': 9, '10': 'algorithm'},
    {
      '1': 'property_settings',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.PropertySetting',
      '10': 'propertySettings'
    },
    {
      '1': 'terminal_channels',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fusion.deviceconfig.v1.TerminalChannels',
      '10': 'terminalChannels'
    },
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode(
    'CgVCbG9jaxISCgRuYW1lGAEgASgJUgRuYW1lEhwKCWFsZ29yaXRobRgCIAEoCVIJYWxnb3JpdG'
    'htElQKEXByb3BlcnR5X3NldHRpbmdzGAMgAygLMicuZnVzaW9uLmRldmljZWNvbmZpZy52MS5Q'
    'cm9wZXJ0eVNldHRpbmdSEHByb3BlcnR5U2V0dGluZ3MSVQoRdGVybWluYWxfY2hhbm5lbHMYBC'
    'ADKAsyKC5mdXNpb24uZGV2aWNlY29uZmlnLnYxLlRlcm1pbmFsQ2hhbm5lbHNSEHRlcm1pbmFs'
    'Q2hhbm5lbHM=');

@$core.Deprecated('Use propertySettingDescriptor instead')
const PropertySetting$json = {
  '1': 'PropertySetting',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'value'
    },
  ],
};

/// Descriptor for `PropertySetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List propertySettingDescriptor = $convert.base64Decode(
    'Cg9Qcm9wZXJ0eVNldHRpbmcSEgoEbmFtZRgBIAEoCVIEbmFtZRIsCgV2YWx1ZRgCIAEoCzIWLm'
    'dvb2dsZS5wcm90b2J1Zi5WYWx1ZVIFdmFsdWU=');

@$core.Deprecated('Use terminalChannelsDescriptor instead')
const TerminalChannels$json = {
  '1': 'TerminalChannels',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'channels', '3': 2, '4': 1, '5': 13, '10': 'channels'},
  ],
};

/// Descriptor for `TerminalChannels`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List terminalChannelsDescriptor = $convert.base64Decode(
    'ChBUZXJtaW5hbENoYW5uZWxzEhIKBG5hbWUYASABKAlSBG5hbWUSGgoIY2hhbm5lbHMYAiABKA'
    '1SCGNoYW5uZWxz');

@$core.Deprecated('Use blockConnectionDescriptor instead')
const BlockConnection$json = {
  '1': 'BlockConnection',
  '2': [
    {'1': 'source_block', '3': 1, '4': 1, '5': 9, '10': 'sourceBlock'},
    {'1': 'output_terminal', '3': 2, '4': 1, '5': 9, '10': 'outputTerminal'},
    {'1': 'output_channel', '3': 3, '4': 1, '5': 13, '10': 'outputChannel'},
    {
      '1': 'destination_block',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'destinationBlock'
    },
    {'1': 'input_terminal', '3': 5, '4': 1, '5': 9, '10': 'inputTerminal'},
    {'1': 'input_channel', '3': 6, '4': 1, '5': 13, '10': 'inputChannel'},
  ],
};

/// Descriptor for `BlockConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockConnectionDescriptor = $convert.base64Decode(
    'Cg9CbG9ja0Nvbm5lY3Rpb24SIQoMc291cmNlX2Jsb2NrGAEgASgJUgtzb3VyY2VCbG9jaxInCg'
    '9vdXRwdXRfdGVybWluYWwYAiABKAlSDm91dHB1dFRlcm1pbmFsEiUKDm91dHB1dF9jaGFubmVs'
    'GAMgASgNUg1vdXRwdXRDaGFubmVsEisKEWRlc3RpbmF0aW9uX2Jsb2NrGAQgASgJUhBkZXN0aW'
    '5hdGlvbkJsb2NrEiUKDmlucHV0X3Rlcm1pbmFsGAUgASgJUg1pbnB1dFRlcm1pbmFsEiMKDWlu'
    'cHV0X2NoYW5uZWwYBiABKA1SDGlucHV0Q2hhbm5lbA==');

@$core.Deprecated('Use taskConnectionDescriptor instead')
const TaskConnection$json = {
  '1': 'TaskConnection',
  '2': [
    {'1': 'source_task', '3': 1, '4': 1, '5': 9, '10': 'sourceTask'},
    {'1': 'output_block', '3': 2, '4': 1, '5': 9, '10': 'outputBlock'},
    {'1': 'output_channel', '3': 3, '4': 1, '5': 13, '10': 'outputChannel'},
    {'1': 'destination_task', '3': 4, '4': 1, '5': 9, '10': 'destinationTask'},
    {'1': 'input_block', '3': 5, '4': 1, '5': 9, '10': 'inputBlock'},
    {'1': 'input_channel', '3': 6, '4': 1, '5': 13, '10': 'inputChannel'},
  ],
};

/// Descriptor for `TaskConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskConnectionDescriptor = $convert.base64Decode(
    'Cg5UYXNrQ29ubmVjdGlvbhIfCgtzb3VyY2VfdGFzaxgBIAEoCVIKc291cmNlVGFzaxIhCgxvdX'
    'RwdXRfYmxvY2sYAiABKAlSC291dHB1dEJsb2NrEiUKDm91dHB1dF9jaGFubmVsGAMgASgNUg1v'
    'dXRwdXRDaGFubmVsEikKEGRlc3RpbmF0aW9uX3Rhc2sYBCABKAlSD2Rlc3RpbmF0aW9uVGFzax'
    'IfCgtpbnB1dF9ibG9jaxgFIAEoCVIKaW5wdXRCbG9jaxIjCg1pbnB1dF9jaGFubmVsGAYgASgN'
    'UgxpbnB1dENoYW5uZWw=');

@$core.Deprecated('Use parameterSettingDescriptor instead')
const ParameterSetting$json = {
  '1': 'ParameterSetting',
  '2': [
    {'1': 'target', '3': 1, '4': 1, '5': 9, '10': 'target'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'index', '3': 3, '4': 3, '5': 13, '10': 'index'},
    {
      '1': 'value',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'value'
    },
  ],
};

/// Descriptor for `ParameterSetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parameterSettingDescriptor = $convert.base64Decode(
    'ChBQYXJhbWV0ZXJTZXR0aW5nEhYKBnRhcmdldBgBIAEoCVIGdGFyZ2V0EhIKBG5hbWUYAiABKA'
    'lSBG5hbWUSFAoFaW5kZXgYAyADKA1SBWluZGV4EiwKBXZhbHVlGAQgASgLMhYuZ29vZ2xlLnBy'
    'b3RvYnVmLlZhbHVlUgV2YWx1ZQ==');
