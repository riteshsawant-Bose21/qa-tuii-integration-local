// This is a generated file - do not edit.
//
// Generated from fusion/udp.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use uDPDebugStatsDescriptor instead')
const UDPDebugStats$json = {
  '1': 'UDPDebugStats',
  '2': [
    {'1': 'queue_depth', '3': 1, '4': 1, '5': 13, '10': 'queueDepth'},
    {'1': 'queue_capacity', '3': 2, '4': 1, '5': 13, '10': 'queueCapacity'},
    {'1': 'max_queue_depth', '3': 3, '4': 1, '5': 4, '10': 'maxQueueDepth'},
    {
      '1': 'registered_clients',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'registeredClients'
    },
    {
      '1': 'pending_broadcasts',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'pendingBroadcasts'
    },
    {
      '1': 'oldest_pending_age_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'oldestPendingAgeMs'
    },
    {'1': 'enqueued_packets', '3': 7, '4': 1, '5': 4, '10': 'enqueuedPackets'},
    {'1': 'dropped_packets', '3': 8, '4': 1, '5': 4, '10': 'droppedPackets'},
    {'1': 'handled_packets', '3': 9, '4': 1, '5': 4, '10': 'handledPackets'},
    {'1': 'ack_packets', '3': 10, '4': 1, '5': 4, '10': 'ackPackets'},
    {'1': 'responses_sent', '3': 11, '4': 1, '5': 4, '10': 'responsesSent'},
    {
      '1': 'broadcast_messages',
      '3': 12,
      '4': 1,
      '5': 4,
      '10': 'broadcastMessages'
    },
    {
      '1': 'broadcast_datagrams',
      '3': 13,
      '4': 1,
      '5': 4,
      '10': 'broadcastDatagrams'
    },
    {
      '1': 'last_broadcast_epoch',
      '3': 14,
      '4': 1,
      '5': 4,
      '10': 'lastBroadcastEpoch'
    },
    {
      '1': 'last_broadcast_version',
      '3': 15,
      '4': 1,
      '5': 4,
      '10': 'lastBroadcastVersion'
    },
    {
      '1': 'last_broadcast_sent_at_ns',
      '3': 16,
      '4': 1,
      '5': 3,
      '10': 'lastBroadcastSentAtNs'
    },
    {
      '1': 'maintenance_enabled',
      '3': 17,
      '4': 1,
      '5': 8,
      '10': 'maintenanceEnabled'
    },
  ],
};

/// Descriptor for `UDPDebugStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uDPDebugStatsDescriptor = $convert.base64Decode(
    'Cg1VRFBEZWJ1Z1N0YXRzEh8KC3F1ZXVlX2RlcHRoGAEgASgNUgpxdWV1ZURlcHRoEiUKDnF1ZX'
    'VlX2NhcGFjaXR5GAIgASgNUg1xdWV1ZUNhcGFjaXR5EiYKD21heF9xdWV1ZV9kZXB0aBgDIAEo'
    'BFINbWF4UXVldWVEZXB0aBItChJyZWdpc3RlcmVkX2NsaWVudHMYBCABKA1SEXJlZ2lzdGVyZW'
    'RDbGllbnRzEi0KEnBlbmRpbmdfYnJvYWRjYXN0cxgFIAEoDVIRcGVuZGluZ0Jyb2FkY2FzdHMS'
    'MQoVb2xkZXN0X3BlbmRpbmdfYWdlX21zGAYgASgDUhJvbGRlc3RQZW5kaW5nQWdlTXMSKQoQZW'
    '5xdWV1ZWRfcGFja2V0cxgHIAEoBFIPZW5xdWV1ZWRQYWNrZXRzEicKD2Ryb3BwZWRfcGFja2V0'
    'cxgIIAEoBFIOZHJvcHBlZFBhY2tldHMSJwoPaGFuZGxlZF9wYWNrZXRzGAkgASgEUg5oYW5kbG'
    'VkUGFja2V0cxIfCgthY2tfcGFja2V0cxgKIAEoBFIKYWNrUGFja2V0cxIlCg5yZXNwb25zZXNf'
    'c2VudBgLIAEoBFINcmVzcG9uc2VzU2VudBItChJicm9hZGNhc3RfbWVzc2FnZXMYDCABKARSEW'
    'Jyb2FkY2FzdE1lc3NhZ2VzEi8KE2Jyb2FkY2FzdF9kYXRhZ3JhbXMYDSABKARSEmJyb2FkY2Fz'
    'dERhdGFncmFtcxIwChRsYXN0X2Jyb2FkY2FzdF9lcG9jaBgOIAEoBFISbGFzdEJyb2FkY2FzdE'
    'Vwb2NoEjQKFmxhc3RfYnJvYWRjYXN0X3ZlcnNpb24YDyABKARSFGxhc3RCcm9hZGNhc3RWZXJz'
    'aW9uEjgKGWxhc3RfYnJvYWRjYXN0X3NlbnRfYXRfbnMYECABKANSFWxhc3RCcm9hZGNhc3RTZW'
    '50QXROcxIvChNtYWludGVuYW5jZV9lbmFibGVkGBEgASgIUhJtYWludGVuYW5jZUVuYWJsZWQ=');
