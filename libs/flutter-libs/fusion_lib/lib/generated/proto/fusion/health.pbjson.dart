// This is a generated file - do not edit.
//
// Generated from fusion/health.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use clusterMemberDescriptor instead')
const ClusterMember$json = {
  '1': 'ClusterMember',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'address', '3': 2, '4': 1, '5': 9, '10': 'address'},
    {'1': 'port', '3': 3, '4': 1, '5': 13, '10': 'port'},
    {'1': 'state', '3': 4, '4': 1, '5': 9, '10': 'state'},
  ],
};

/// Descriptor for `ClusterMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clusterMemberDescriptor = $convert.base64Decode(
    'Cg1DbHVzdGVyTWVtYmVyEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHYWRkcmVzcxgCIAEoCVIHYW'
    'RkcmVzcxISCgRwb3J0GAMgASgNUgRwb3J0EhQKBXN0YXRlGAQgASgJUgVzdGF0ZQ==');

@$core.Deprecated('Use clusterInfoDescriptor instead')
const ClusterInfo$json = {
  '1': 'ClusterInfo',
  '2': [
    {'1': 'member_count', '3': 1, '4': 1, '5': 13, '10': 'memberCount'},
    {'1': 'alive_count', '3': 2, '4': 1, '5': 13, '10': 'aliveCount'},
    {'1': 'local_node', '3': 3, '4': 1, '5': 9, '10': 'localNode'},
    {
      '1': 'members',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fusion.ClusterMember',
      '10': 'members'
    },
    {
      '1': 'last_update_time',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUpdateTime'
    },
    {'1': 'suspect_nodes', '3': 6, '4': 1, '5': 13, '10': 'suspectNodes'},
    {'1': 'dead_nodes', '3': 7, '4': 1, '5': 13, '10': 'deadNodes'},
    {'1': 'cluster_health', '3': 8, '4': 1, '5': 1, '10': 'clusterHealth'},
    {
      '1': 'avg_ping_latency_ms',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'avgPingLatencyMs'
    },
  ],
};

/// Descriptor for `ClusterInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clusterInfoDescriptor = $convert.base64Decode(
    'CgtDbHVzdGVySW5mbxIhCgxtZW1iZXJfY291bnQYASABKA1SC21lbWJlckNvdW50Eh8KC2FsaX'
    'ZlX2NvdW50GAIgASgNUgphbGl2ZUNvdW50Eh0KCmxvY2FsX25vZGUYAyABKAlSCWxvY2FsTm9k'
    'ZRIvCgdtZW1iZXJzGAQgAygLMhUuZnVzaW9uLkNsdXN0ZXJNZW1iZXJSB21lbWJlcnMSRAoQbG'
    'FzdF91cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDmxhc3RV'
    'cGRhdGVUaW1lEiMKDXN1c3BlY3Rfbm9kZXMYBiABKA1SDHN1c3BlY3ROb2RlcxIdCgpkZWFkX2'
    '5vZGVzGAcgASgNUglkZWFkTm9kZXMSJQoOY2x1c3Rlcl9oZWFsdGgYCCABKAFSDWNsdXN0ZXJI'
    'ZWFsdGgSLQoTYXZnX3BpbmdfbGF0ZW5jeV9tcxgJIAEoAVIQYXZnUGluZ0xhdGVuY3lNcw==');

@$core.Deprecated('Use nodeHealthDescriptor instead')
const NodeHealth$json = {
  '1': 'NodeHealth',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'last_heartbeat',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastHeartbeat'
    },
    {'1': 'uptime_seconds', '3': 3, '4': 1, '5': 3, '10': 'uptimeSeconds'},
    {
      '1': 'start_time',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startTime'
    },
    {
      '1': 'health_check_count',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'healthCheckCount'
    },
  ],
};

/// Descriptor for `NodeHealth`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeHealthDescriptor = $convert.base64Decode(
    'CgpOb2RlSGVhbHRoEhYKBnN0YXR1cxgBIAEoCVIGc3RhdHVzEkEKDmxhc3RfaGVhcnRiZWF0GA'
    'IgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFINbGFzdEhlYXJ0YmVhdBIlCg51cHRp'
    'bWVfc2Vjb25kcxgDIAEoA1INdXB0aW1lU2Vjb25kcxI5CgpzdGFydF90aW1lGAQgASgLMhouZ2'
    '9vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEiwKEmhlYWx0aF9jaGVja19jb3Vu'
    'dBgFIAEoA1IQaGVhbHRoQ2hlY2tDb3VudA==');

@$core.Deprecated('Use healthCheckResponseDescriptor instead')
const HealthCheckResponse$json = {
  '1': 'HealthCheckResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'node_health',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fusion.NodeHealth',
      '10': 'nodeHealth'
    },
    {'1': 'cluster_health', '3': 3, '4': 1, '5': 1, '10': 'clusterHealth'},
  ],
};

/// Descriptor for `HealthCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthCheckResponseDescriptor = $convert.base64Decode(
    'ChNIZWFsdGhDaGVja1Jlc3BvbnNlEhYKBnN0YXR1cxgBIAEoCVIGc3RhdHVzEjMKC25vZGVfaG'
    'VhbHRoGAIgASgLMhIuZnVzaW9uLk5vZGVIZWFsdGhSCm5vZGVIZWFsdGgSJQoOY2x1c3Rlcl9o'
    'ZWFsdGgYAyABKAFSDWNsdXN0ZXJIZWFsdGg=');
