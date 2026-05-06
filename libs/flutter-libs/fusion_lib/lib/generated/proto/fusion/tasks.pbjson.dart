// This is a generated file - do not edit.
//
// Generated from fusion/tasks.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskTypeDescriptor instead')
const TaskType$json = {
  '1': 'TaskType',
  '2': [
    {'1': 'TASK_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TASK_TYPE_SNAPSHOT', '2': 1},
    {'1': 'TASK_TYPE_MESSAGE', '2': 2},
  ],
};

/// Descriptor for `TaskType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List taskTypeDescriptor = $convert.base64Decode(
    'CghUYXNrVHlwZRIZChVUQVNLX1RZUEVfVU5TUEVDSUZJRUQQABIWChJUQVNLX1RZUEVfU05BUF'
    'NIT1QQARIVChFUQVNLX1RZUEVfTUVTU0FHRRAC');

@$core.Deprecated('Use recurringWindowDescriptor instead')
const RecurringWindow$json = {
  '1': 'RecurringWindow',
  '2': [
    {'1': 'start_time', '3': 1, '4': 1, '5': 9, '10': 'startTime'},
    {'1': 'end_time', '3': 2, '4': 1, '5': 9, '10': 'endTime'},
    {'1': 'days', '3': 3, '4': 3, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `RecurringWindow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recurringWindowDescriptor = $convert.base64Decode(
    'Cg9SZWN1cnJpbmdXaW5kb3cSHQoKc3RhcnRfdGltZRgBIAEoCVIJc3RhcnRUaW1lEhkKCGVuZF'
    '90aW1lGAIgASgJUgdlbmRUaW1lEhIKBGRheXMYAyADKAVSBGRheXM=');

@$core.Deprecated('Use snapshotTaskDetailsDescriptor instead')
const SnapshotTaskDetails$json = {
  '1': 'SnapshotTaskDetails',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `SnapshotTaskDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotTaskDetailsDescriptor = $convert.base64Decode(
    'ChNTbmFwc2hvdFRhc2tEZXRhaWxzEh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdElk');

@$core.Deprecated('Use messageTaskDetailsDescriptor instead')
const MessageTaskDetails$json = {
  '1': 'MessageTaskDetails',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'priority', '3': 2, '4': 1, '5': 3, '10': 'priority'},
    {'1': 'zones', '3': 3, '4': 1, '5': 9, '10': 'zones'},
  ],
};

/// Descriptor for `MessageTaskDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageTaskDetailsDescriptor = $convert.base64Decode(
    'ChJNZXNzYWdlVGFza0RldGFpbHMSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEhoKCH'
    'ByaW9yaXR5GAIgASgDUghwcmlvcml0eRIUCgV6b25lcxgDIAEoCVIFem9uZXM=');

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = {
  '1': 'Task',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.fusion.tasks.v1.TaskType',
      '10': 'type'
    },
    {'1': 'cron_expr', '3': 4, '4': 1, '5': 9, '10': 'cronExpr'},
    {
      '1': 'start_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startAt'
    },
    {
      '1': 'end_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endAt'
    },
    {
      '1': 'recurrence',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.RecurringWindow',
      '10': 'recurrence'
    },
    {'1': 'enabled', '3': 8, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'scheduled', '3': 9, '4': 1, '5': 8, '10': 'scheduled'},
    {
      '1': 'snapshot',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.SnapshotTaskDetails',
      '9': 0,
      '10': 'snapshot'
    },
    {
      '1': 'message',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.MessageTaskDetails',
      '9': 0,
      '10': 'message'
    },
  ],
  '8': [
    {'1': 'details'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEg4KAmlkGAEgASgJUgJpZBIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb2'
    '4SLQoEdHlwZRgDIAEoDjIZLmZ1c2lvbi50YXNrcy52MS5UYXNrVHlwZVIEdHlwZRIbCgljcm9u'
    'X2V4cHIYBCABKAlSCGNyb25FeHByEjUKCHN0YXJ0X2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYn'
    'VmLlRpbWVzdGFtcFIHc3RhcnRBdBIxCgZlbmRfYXQYBiABKAsyGi5nb29nbGUucHJvdG9idWYu'
    'VGltZXN0YW1wUgVlbmRBdBJACgpyZWN1cnJlbmNlGAcgASgLMiAuZnVzaW9uLnRhc2tzLnYxLl'
    'JlY3VycmluZ1dpbmRvd1IKcmVjdXJyZW5jZRIYCgdlbmFibGVkGAggASgIUgdlbmFibGVkEhwK'
    'CXNjaGVkdWxlZBgJIAEoCFIJc2NoZWR1bGVkEkIKCHNuYXBzaG90GAogASgLMiQuZnVzaW9uLn'
    'Rhc2tzLnYxLlNuYXBzaG90VGFza0RldGFpbHNIAFIIc25hcHNob3QSPwoHbWVzc2FnZRgLIAEo'
    'CzIjLmZ1c2lvbi50YXNrcy52MS5NZXNzYWdlVGFza0RldGFpbHNIAFIHbWVzc2FnZUIJCgdkZX'
    'RhaWxz');

@$core.Deprecated('Use taskListResponseDescriptor instead')
const TaskListResponse$json = {
  '1': 'TaskListResponse',
  '2': [
    {
      '1': 'tasks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.tasks.v1.Task',
      '10': 'tasks'
    },
  ],
};

/// Descriptor for `TaskListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskListResponseDescriptor = $convert.base64Decode(
    'ChBUYXNrTGlzdFJlc3BvbnNlEisKBXRhc2tzGAEgAygLMhUuZnVzaW9uLnRhc2tzLnYxLlRhc2'
    'tSBXRhc2tz');

@$core.Deprecated('Use taskExecutionRecordDescriptor instead')
const TaskExecutionRecord$json = {
  '1': 'TaskExecutionRecord',
  '2': [
    {'1': 'description', '3': 1, '4': 1, '5': 9, '10': 'description'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'task_id', '3': 3, '4': 1, '5': 9, '10': 'taskId'},
    {
      '1': 'timestamp',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
  ],
};

/// Descriptor for `TaskExecutionRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskExecutionRecordDescriptor = $convert.base64Decode(
    'ChNUYXNrRXhlY3V0aW9uUmVjb3JkEiAKC2Rlc2NyaXB0aW9uGAEgASgJUgtkZXNjcmlwdGlvbh'
    'IWCgZzdGF0dXMYAiABKAlSBnN0YXR1cxIXCgd0YXNrX2lkGAMgASgJUgZ0YXNrSWQSOAoJdGlt'
    'ZXN0YW1wGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdGltZXN0YW1w');

@$core.Deprecated('Use taskHistoryResponseDescriptor instead')
const TaskHistoryResponse$json = {
  '1': 'TaskHistoryResponse',
  '2': [
    {
      '1': 'history',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fusion.tasks.v1.TaskExecutionRecord',
      '10': 'history'
    },
  ],
};

/// Descriptor for `TaskHistoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskHistoryResponseDescriptor = $convert.base64Decode(
    'ChNUYXNrSGlzdG9yeVJlc3BvbnNlEj4KB2hpc3RvcnkYASADKAsyJC5mdXNpb24udGFza3Mudj'
    'EuVGFza0V4ZWN1dGlvblJlY29yZFIHaGlzdG9yeQ==');

@$core.Deprecated('Use createTaskResponseDescriptor instead')
const CreateTaskResponse$json = {
  '1': 'CreateTaskResponse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `CreateTaskResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTaskResponseDescriptor =
    $convert.base64Decode('ChJDcmVhdGVUYXNrUmVzcG9uc2USDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use snapshotTaskCreateRequestDescriptor instead')
const SnapshotTaskCreateRequest$json = {
  '1': 'SnapshotTaskCreateRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'cron_expr', '3': 3, '4': 1, '5': 9, '10': 'cronExpr'},
    {
      '1': 'start_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startAt'
    },
    {
      '1': 'end_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endAt'
    },
    {
      '1': 'recurrence',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.RecurringWindow',
      '10': 'recurrence'
    },
    {'1': 'snapshot_id', '3': 7, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `SnapshotTaskCreateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotTaskCreateRequestDescriptor = $convert.base64Decode(
    'ChlTbmFwc2hvdFRhc2tDcmVhdGVSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIgCgtkZXNjcmlwdG'
    'lvbhgCIAEoCVILZGVzY3JpcHRpb24SGwoJY3Jvbl9leHByGAMgASgJUghjcm9uRXhwchI1Cghz'
    'dGFydF9hdBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB3N0YXJ0QXQSMQoGZW'
    '5kX2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIFZW5kQXQSQAoKcmVjdXJy'
    'ZW5jZRgGIAEoCzIgLmZ1c2lvbi50YXNrcy52MS5SZWN1cnJpbmdXaW5kb3dSCnJlY3VycmVuY2'
    'USHwoLc25hcHNob3RfaWQYByABKAlSCnNuYXBzaG90SWQ=');

@$core.Deprecated('Use snapshotTaskUpdateRequestDescriptor instead')
const SnapshotTaskUpdateRequest$json = {
  '1': 'SnapshotTaskUpdateRequest',
  '2': [
    {
      '1': 'description',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {
      '1': 'cron_expr',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'cronExpr',
      '17': true
    },
    {
      '1': 'start_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startAt'
    },
    {
      '1': 'end_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endAt'
    },
    {
      '1': 'recurrence',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.RecurringWindow',
      '10': 'recurrence'
    },
    {
      '1': 'snapshot_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'snapshotId',
      '17': true
    },
  ],
  '8': [
    {'1': '_description'},
    {'1': '_cron_expr'},
    {'1': '_snapshot_id'},
  ],
};

/// Descriptor for `SnapshotTaskUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotTaskUpdateRequestDescriptor = $convert.base64Decode(
    'ChlTbmFwc2hvdFRhc2tVcGRhdGVSZXF1ZXN0EiUKC2Rlc2NyaXB0aW9uGAEgASgJSABSC2Rlc2'
    'NyaXB0aW9uiAEBEiAKCWNyb25fZXhwchgCIAEoCUgBUghjcm9uRXhwcogBARI1CghzdGFydF9h'
    'dBgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB3N0YXJ0QXQSMQoGZW5kX2F0GA'
    'QgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIFZW5kQXQSQAoKcmVjdXJyZW5jZRgF'
    'IAEoCzIgLmZ1c2lvbi50YXNrcy52MS5SZWN1cnJpbmdXaW5kb3dSCnJlY3VycmVuY2USJAoLc2'
    '5hcHNob3RfaWQYBiABKAlIAlIKc25hcHNob3RJZIgBAUIOCgxfZGVzY3JpcHRpb25CDAoKX2Ny'
    'b25fZXhwckIOCgxfc25hcHNob3RfaWQ=');

@$core.Deprecated('Use messageTaskCreateRequestDescriptor instead')
const MessageTaskCreateRequest$json = {
  '1': 'MessageTaskCreateRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'cron_expr', '3': 3, '4': 1, '5': 9, '10': 'cronExpr'},
    {
      '1': 'start_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startAt'
    },
    {
      '1': 'end_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endAt'
    },
    {
      '1': 'recurrence',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.RecurringWindow',
      '10': 'recurrence'
    },
    {'1': 'message_id', '3': 7, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'priority', '3': 8, '4': 1, '5': 3, '10': 'priority'},
    {'1': 'zones', '3': 9, '4': 1, '5': 9, '10': 'zones'},
  ],
};

/// Descriptor for `MessageTaskCreateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageTaskCreateRequestDescriptor = $convert.base64Decode(
    'ChhNZXNzYWdlVGFza0NyZWF0ZVJlcXVlc3QSDgoCaWQYASABKAlSAmlkEiAKC2Rlc2NyaXB0aW'
    '9uGAIgASgJUgtkZXNjcmlwdGlvbhIbCgljcm9uX2V4cHIYAyABKAlSCGNyb25FeHByEjUKCHN0'
    'YXJ0X2F0GAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHc3RhcnRBdBIxCgZlbm'
    'RfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgVlbmRBdBJACgpyZWN1cnJl'
    'bmNlGAYgASgLMiAuZnVzaW9uLnRhc2tzLnYxLlJlY3VycmluZ1dpbmRvd1IKcmVjdXJyZW5jZR'
    'IdCgptZXNzYWdlX2lkGAcgASgJUgltZXNzYWdlSWQSGgoIcHJpb3JpdHkYCCABKANSCHByaW9y'
    'aXR5EhQKBXpvbmVzGAkgASgJUgV6b25lcw==');

@$core.Deprecated('Use messageTaskUpdateRequestDescriptor instead')
const MessageTaskUpdateRequest$json = {
  '1': 'MessageTaskUpdateRequest',
  '2': [
    {
      '1': 'description',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {
      '1': 'cron_expr',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'cronExpr',
      '17': true
    },
    {
      '1': 'start_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startAt'
    },
    {
      '1': 'end_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endAt'
    },
    {
      '1': 'recurrence',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.fusion.tasks.v1.RecurringWindow',
      '10': 'recurrence'
    },
    {
      '1': 'message_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'messageId',
      '17': true
    },
    {
      '1': 'priority',
      '3': 7,
      '4': 1,
      '5': 3,
      '9': 3,
      '10': 'priority',
      '17': true
    },
    {'1': 'zones', '3': 8, '4': 1, '5': 9, '9': 4, '10': 'zones', '17': true},
  ],
  '8': [
    {'1': '_description'},
    {'1': '_cron_expr'},
    {'1': '_message_id'},
    {'1': '_priority'},
    {'1': '_zones'},
  ],
};

/// Descriptor for `MessageTaskUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageTaskUpdateRequestDescriptor = $convert.base64Decode(
    'ChhNZXNzYWdlVGFza1VwZGF0ZVJlcXVlc3QSJQoLZGVzY3JpcHRpb24YASABKAlIAFILZGVzY3'
    'JpcHRpb26IAQESIAoJY3Jvbl9leHByGAIgASgJSAFSCGNyb25FeHByiAEBEjUKCHN0YXJ0X2F0'
    'GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHc3RhcnRBdBIxCgZlbmRfYXQYBC'
    'ABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgVlbmRBdBJACgpyZWN1cnJlbmNlGAUg'
    'ASgLMiAuZnVzaW9uLnRhc2tzLnYxLlJlY3VycmluZ1dpbmRvd1IKcmVjdXJyZW5jZRIiCgptZX'
    'NzYWdlX2lkGAYgASgJSAJSCW1lc3NhZ2VJZIgBARIfCghwcmlvcml0eRgHIAEoA0gDUghwcmlv'
    'cml0eYgBARIZCgV6b25lcxgIIAEoCUgEUgV6b25lc4gBAUIOCgxfZGVzY3JpcHRpb25CDAoKX2'
    'Nyb25fZXhwckINCgtfbWVzc2FnZV9pZEILCglfcHJpb3JpdHlCCAoGX3pvbmVz');
