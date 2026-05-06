// This is a generated file - do not edit.
//
// Generated from fusion/tasks.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/timestamp.pb.dart' as $0;
import 'tasks.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'tasks.pbenum.dart';

class RecurringWindow extends $pb.GeneratedMessage {
  factory RecurringWindow({
    $core.String? startTime,
    $core.String? endTime,
    $core.Iterable<$core.int>? days,
  }) {
    final result = create();
    if (startTime != null) result.startTime = startTime;
    if (endTime != null) result.endTime = endTime;
    if (days != null) result.days.addAll(days);
    return result;
  }

  RecurringWindow._();

  factory RecurringWindow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecurringWindow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecurringWindow',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'startTime')
    ..aOS(2, _omitFieldNames ? '' : 'endTime')
    ..p<$core.int>(3, _omitFieldNames ? '' : 'days', $pb.PbFieldType.K3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecurringWindow clone() => RecurringWindow()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecurringWindow copyWith(void Function(RecurringWindow) updates) =>
      super.copyWith((message) => updates(message as RecurringWindow))
          as RecurringWindow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecurringWindow create() => RecurringWindow._();
  @$core.override
  RecurringWindow createEmptyInstance() => create();
  static $pb.PbList<RecurringWindow> createRepeated() =>
      $pb.PbList<RecurringWindow>();
  @$core.pragma('dart2js:noInline')
  static RecurringWindow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecurringWindow>(create);
  static RecurringWindow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get startTime => $_getSZ(0);
  @$pb.TagNumber(1)
  set startTime($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTime() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get endTime => $_getSZ(1);
  @$pb.TagNumber(2)
  set endTime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.int> get days => $_getList(2);
}

class SnapshotTaskDetails extends $pb.GeneratedMessage {
  factory SnapshotTaskDetails({
    $core.String? snapshotId,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  SnapshotTaskDetails._();

  factory SnapshotTaskDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnapshotTaskDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnapshotTaskDetails',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotTaskDetails clone() => SnapshotTaskDetails()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotTaskDetails copyWith(void Function(SnapshotTaskDetails) updates) =>
      super.copyWith((message) => updates(message as SnapshotTaskDetails))
          as SnapshotTaskDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnapshotTaskDetails create() => SnapshotTaskDetails._();
  @$core.override
  SnapshotTaskDetails createEmptyInstance() => create();
  static $pb.PbList<SnapshotTaskDetails> createRepeated() =>
      $pb.PbList<SnapshotTaskDetails>();
  @$core.pragma('dart2js:noInline')
  static SnapshotTaskDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotTaskDetails>(create);
  static SnapshotTaskDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);
}

class MessageTaskDetails extends $pb.GeneratedMessage {
  factory MessageTaskDetails({
    $core.String? messageId,
    $fixnum.Int64? priority,
    $core.String? zones,
  }) {
    final result = create();
    if (messageId != null) result.messageId = messageId;
    if (priority != null) result.priority = priority;
    if (zones != null) result.zones = zones;
    return result;
  }

  MessageTaskDetails._();

  factory MessageTaskDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageTaskDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageTaskDetails',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aInt64(2, _omitFieldNames ? '' : 'priority')
    ..aOS(3, _omitFieldNames ? '' : 'zones')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTaskDetails clone() => MessageTaskDetails()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTaskDetails copyWith(void Function(MessageTaskDetails) updates) =>
      super.copyWith((message) => updates(message as MessageTaskDetails))
          as MessageTaskDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageTaskDetails create() => MessageTaskDetails._();
  @$core.override
  MessageTaskDetails createEmptyInstance() => create();
  static $pb.PbList<MessageTaskDetails> createRepeated() =>
      $pb.PbList<MessageTaskDetails>();
  @$core.pragma('dart2js:noInline')
  static MessageTaskDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageTaskDetails>(create);
  static MessageTaskDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get priority => $_getI64(1);
  @$pb.TagNumber(2)
  set priority($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPriority() => $_has(1);
  @$pb.TagNumber(2)
  void clearPriority() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get zones => $_getSZ(2);
  @$pb.TagNumber(3)
  set zones($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZones() => $_has(2);
  @$pb.TagNumber(3)
  void clearZones() => $_clearField(3);
}

enum Task_Details { snapshot, message, notSet }

class Task extends $pb.GeneratedMessage {
  factory Task({
    $core.String? id,
    $core.String? description,
    TaskType? type,
    $core.String? cronExpr,
    $0.Timestamp? startAt,
    $0.Timestamp? endAt,
    RecurringWindow? recurrence,
    $core.bool? enabled,
    $core.bool? scheduled,
    SnapshotTaskDetails? snapshot,
    MessageTaskDetails? message,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (description != null) result.description = description;
    if (type != null) result.type = type;
    if (cronExpr != null) result.cronExpr = cronExpr;
    if (startAt != null) result.startAt = startAt;
    if (endAt != null) result.endAt = endAt;
    if (recurrence != null) result.recurrence = recurrence;
    if (enabled != null) result.enabled = enabled;
    if (scheduled != null) result.scheduled = scheduled;
    if (snapshot != null) result.snapshot = snapshot;
    if (message != null) result.message = message;
    return result;
  }

  Task._();

  factory Task.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Task.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Task_Details> _Task_DetailsByTag = {
    10: Task_Details.snapshot,
    11: Task_Details.message,
    0: Task_Details.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Task',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..e<TaskType>(3, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: TaskType.TASK_TYPE_UNSPECIFIED,
        valueOf: TaskType.valueOf,
        enumValues: TaskType.values)
    ..aOS(4, _omitFieldNames ? '' : 'cronExpr')
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'startAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'endAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<RecurringWindow>(7, _omitFieldNames ? '' : 'recurrence',
        subBuilder: RecurringWindow.create)
    ..aOB(8, _omitFieldNames ? '' : 'enabled')
    ..aOB(9, _omitFieldNames ? '' : 'scheduled')
    ..aOM<SnapshotTaskDetails>(10, _omitFieldNames ? '' : 'snapshot',
        subBuilder: SnapshotTaskDetails.create)
    ..aOM<MessageTaskDetails>(11, _omitFieldNames ? '' : 'message',
        subBuilder: MessageTaskDetails.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Task clone() => Task()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Task copyWith(void Function(Task) updates) =>
      super.copyWith((message) => updates(message as Task)) as Task;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Task create() => Task._();
  @$core.override
  Task createEmptyInstance() => create();
  static $pb.PbList<Task> createRepeated() => $pb.PbList<Task>();
  @$core.pragma('dart2js:noInline')
  static Task getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Task>(create);
  static Task? _defaultInstance;

  Task_Details whichDetails() => _Task_DetailsByTag[$_whichOneof(0)]!;
  void clearDetails() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  TaskType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(TaskType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get cronExpr => $_getSZ(3);
  @$pb.TagNumber(4)
  set cronExpr($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCronExpr() => $_has(3);
  @$pb.TagNumber(4)
  void clearCronExpr() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.Timestamp get startAt => $_getN(4);
  @$pb.TagNumber(5)
  set startAt($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasStartAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureStartAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $0.Timestamp get endAt => $_getN(5);
  @$pb.TagNumber(6)
  set endAt($0.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasEndAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureEndAt() => $_ensure(5);

  @$pb.TagNumber(7)
  RecurringWindow get recurrence => $_getN(6);
  @$pb.TagNumber(7)
  set recurrence(RecurringWindow value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasRecurrence() => $_has(6);
  @$pb.TagNumber(7)
  void clearRecurrence() => $_clearField(7);
  @$pb.TagNumber(7)
  RecurringWindow ensureRecurrence() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.bool get enabled => $_getBF(7);
  @$pb.TagNumber(8)
  set enabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearEnabled() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get scheduled => $_getBF(8);
  @$pb.TagNumber(9)
  set scheduled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasScheduled() => $_has(8);
  @$pb.TagNumber(9)
  void clearScheduled() => $_clearField(9);

  @$pb.TagNumber(10)
  SnapshotTaskDetails get snapshot => $_getN(9);
  @$pb.TagNumber(10)
  set snapshot(SnapshotTaskDetails value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSnapshot() => $_has(9);
  @$pb.TagNumber(10)
  void clearSnapshot() => $_clearField(10);
  @$pb.TagNumber(10)
  SnapshotTaskDetails ensureSnapshot() => $_ensure(9);

  @$pb.TagNumber(11)
  MessageTaskDetails get message => $_getN(10);
  @$pb.TagNumber(11)
  set message(MessageTaskDetails value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMessage() => $_has(10);
  @$pb.TagNumber(11)
  void clearMessage() => $_clearField(11);
  @$pb.TagNumber(11)
  MessageTaskDetails ensureMessage() => $_ensure(10);
}

class TaskListResponse extends $pb.GeneratedMessage {
  factory TaskListResponse({
    $core.Iterable<Task>? tasks,
  }) {
    final result = create();
    if (tasks != null) result.tasks.addAll(tasks);
    return result;
  }

  TaskListResponse._();

  factory TaskListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..pc<Task>(1, _omitFieldNames ? '' : 'tasks', $pb.PbFieldType.PM,
        subBuilder: Task.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskListResponse clone() => TaskListResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskListResponse copyWith(void Function(TaskListResponse) updates) =>
      super.copyWith((message) => updates(message as TaskListResponse))
          as TaskListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskListResponse create() => TaskListResponse._();
  @$core.override
  TaskListResponse createEmptyInstance() => create();
  static $pb.PbList<TaskListResponse> createRepeated() =>
      $pb.PbList<TaskListResponse>();
  @$core.pragma('dart2js:noInline')
  static TaskListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskListResponse>(create);
  static TaskListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Task> get tasks => $_getList(0);
}

class TaskExecutionRecord extends $pb.GeneratedMessage {
  factory TaskExecutionRecord({
    $core.String? description,
    $core.String? status,
    $core.String? taskId,
    $0.Timestamp? timestamp,
  }) {
    final result = create();
    if (description != null) result.description = description;
    if (status != null) result.status = status;
    if (taskId != null) result.taskId = taskId;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  TaskExecutionRecord._();

  factory TaskExecutionRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskExecutionRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskExecutionRecord',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'description')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'taskId')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskExecutionRecord clone() => TaskExecutionRecord()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskExecutionRecord copyWith(void Function(TaskExecutionRecord) updates) =>
      super.copyWith((message) => updates(message as TaskExecutionRecord))
          as TaskExecutionRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskExecutionRecord create() => TaskExecutionRecord._();
  @$core.override
  TaskExecutionRecord createEmptyInstance() => create();
  static $pb.PbList<TaskExecutionRecord> createRepeated() =>
      $pb.PbList<TaskExecutionRecord>();
  @$core.pragma('dart2js:noInline')
  static TaskExecutionRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskExecutionRecord>(create);
  static TaskExecutionRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get description => $_getSZ(0);
  @$pb.TagNumber(1)
  set description($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDescription() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescription() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get taskId => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTaskId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskId() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get timestamp => $_getN(3);
  @$pb.TagNumber(4)
  set timestamp($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureTimestamp() => $_ensure(3);
}

class TaskHistoryResponse extends $pb.GeneratedMessage {
  factory TaskHistoryResponse({
    $core.Iterable<TaskExecutionRecord>? history,
  }) {
    final result = create();
    if (history != null) result.history.addAll(history);
    return result;
  }

  TaskHistoryResponse._();

  factory TaskHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskHistoryResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..pc<TaskExecutionRecord>(
        1, _omitFieldNames ? '' : 'history', $pb.PbFieldType.PM,
        subBuilder: TaskExecutionRecord.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskHistoryResponse clone() => TaskHistoryResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskHistoryResponse copyWith(void Function(TaskHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as TaskHistoryResponse))
          as TaskHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskHistoryResponse create() => TaskHistoryResponse._();
  @$core.override
  TaskHistoryResponse createEmptyInstance() => create();
  static $pb.PbList<TaskHistoryResponse> createRepeated() =>
      $pb.PbList<TaskHistoryResponse>();
  @$core.pragma('dart2js:noInline')
  static TaskHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskHistoryResponse>(create);
  static TaskHistoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TaskExecutionRecord> get history => $_getList(0);
}

class CreateTaskResponse extends $pb.GeneratedMessage {
  factory CreateTaskResponse({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  CreateTaskResponse._();

  factory CreateTaskResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateTaskResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateTaskResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTaskResponse clone() => CreateTaskResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTaskResponse copyWith(void Function(CreateTaskResponse) updates) =>
      super.copyWith((message) => updates(message as CreateTaskResponse))
          as CreateTaskResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateTaskResponse create() => CreateTaskResponse._();
  @$core.override
  CreateTaskResponse createEmptyInstance() => create();
  static $pb.PbList<CreateTaskResponse> createRepeated() =>
      $pb.PbList<CreateTaskResponse>();
  @$core.pragma('dart2js:noInline')
  static CreateTaskResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateTaskResponse>(create);
  static CreateTaskResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class SnapshotTaskCreateRequest extends $pb.GeneratedMessage {
  factory SnapshotTaskCreateRequest({
    $core.String? id,
    $core.String? description,
    $core.String? cronExpr,
    $0.Timestamp? startAt,
    $0.Timestamp? endAt,
    RecurringWindow? recurrence,
    $core.String? snapshotId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (description != null) result.description = description;
    if (cronExpr != null) result.cronExpr = cronExpr;
    if (startAt != null) result.startAt = startAt;
    if (endAt != null) result.endAt = endAt;
    if (recurrence != null) result.recurrence = recurrence;
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  SnapshotTaskCreateRequest._();

  factory SnapshotTaskCreateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnapshotTaskCreateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnapshotTaskCreateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'cronExpr')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'startAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'endAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<RecurringWindow>(6, _omitFieldNames ? '' : 'recurrence',
        subBuilder: RecurringWindow.create)
    ..aOS(7, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotTaskCreateRequest clone() =>
      SnapshotTaskCreateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotTaskCreateRequest copyWith(
          void Function(SnapshotTaskCreateRequest) updates) =>
      super.copyWith((message) => updates(message as SnapshotTaskCreateRequest))
          as SnapshotTaskCreateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnapshotTaskCreateRequest create() => SnapshotTaskCreateRequest._();
  @$core.override
  SnapshotTaskCreateRequest createEmptyInstance() => create();
  static $pb.PbList<SnapshotTaskCreateRequest> createRepeated() =>
      $pb.PbList<SnapshotTaskCreateRequest>();
  @$core.pragma('dart2js:noInline')
  static SnapshotTaskCreateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotTaskCreateRequest>(create);
  static SnapshotTaskCreateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get cronExpr => $_getSZ(2);
  @$pb.TagNumber(3)
  set cronExpr($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCronExpr() => $_has(2);
  @$pb.TagNumber(3)
  void clearCronExpr() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get startAt => $_getN(3);
  @$pb.TagNumber(4)
  set startAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStartAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureStartAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $0.Timestamp get endAt => $_getN(4);
  @$pb.TagNumber(5)
  set endAt($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasEndAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureEndAt() => $_ensure(4);

  @$pb.TagNumber(6)
  RecurringWindow get recurrence => $_getN(5);
  @$pb.TagNumber(6)
  set recurrence(RecurringWindow value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRecurrence() => $_has(5);
  @$pb.TagNumber(6)
  void clearRecurrence() => $_clearField(6);
  @$pb.TagNumber(6)
  RecurringWindow ensureRecurrence() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get snapshotId => $_getSZ(6);
  @$pb.TagNumber(7)
  set snapshotId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSnapshotId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSnapshotId() => $_clearField(7);
}

class SnapshotTaskUpdateRequest extends $pb.GeneratedMessage {
  factory SnapshotTaskUpdateRequest({
    $core.String? description,
    $core.String? cronExpr,
    $0.Timestamp? startAt,
    $0.Timestamp? endAt,
    RecurringWindow? recurrence,
    $core.String? snapshotId,
  }) {
    final result = create();
    if (description != null) result.description = description;
    if (cronExpr != null) result.cronExpr = cronExpr;
    if (startAt != null) result.startAt = startAt;
    if (endAt != null) result.endAt = endAt;
    if (recurrence != null) result.recurrence = recurrence;
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  SnapshotTaskUpdateRequest._();

  factory SnapshotTaskUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnapshotTaskUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnapshotTaskUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'description')
    ..aOS(2, _omitFieldNames ? '' : 'cronExpr')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'startAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'endAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<RecurringWindow>(5, _omitFieldNames ? '' : 'recurrence',
        subBuilder: RecurringWindow.create)
    ..aOS(6, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotTaskUpdateRequest clone() =>
      SnapshotTaskUpdateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnapshotTaskUpdateRequest copyWith(
          void Function(SnapshotTaskUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as SnapshotTaskUpdateRequest))
          as SnapshotTaskUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnapshotTaskUpdateRequest create() => SnapshotTaskUpdateRequest._();
  @$core.override
  SnapshotTaskUpdateRequest createEmptyInstance() => create();
  static $pb.PbList<SnapshotTaskUpdateRequest> createRepeated() =>
      $pb.PbList<SnapshotTaskUpdateRequest>();
  @$core.pragma('dart2js:noInline')
  static SnapshotTaskUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotTaskUpdateRequest>(create);
  static SnapshotTaskUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get description => $_getSZ(0);
  @$pb.TagNumber(1)
  set description($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDescription() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescription() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cronExpr => $_getSZ(1);
  @$pb.TagNumber(2)
  set cronExpr($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCronExpr() => $_has(1);
  @$pb.TagNumber(2)
  void clearCronExpr() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get startAt => $_getN(2);
  @$pb.TagNumber(3)
  set startAt($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStartAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureStartAt() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.Timestamp get endAt => $_getN(3);
  @$pb.TagNumber(4)
  set endAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEndAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureEndAt() => $_ensure(3);

  @$pb.TagNumber(5)
  RecurringWindow get recurrence => $_getN(4);
  @$pb.TagNumber(5)
  set recurrence(RecurringWindow value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRecurrence() => $_has(4);
  @$pb.TagNumber(5)
  void clearRecurrence() => $_clearField(5);
  @$pb.TagNumber(5)
  RecurringWindow ensureRecurrence() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get snapshotId => $_getSZ(5);
  @$pb.TagNumber(6)
  set snapshotId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSnapshotId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSnapshotId() => $_clearField(6);
}

class MessageTaskCreateRequest extends $pb.GeneratedMessage {
  factory MessageTaskCreateRequest({
    $core.String? id,
    $core.String? description,
    $core.String? cronExpr,
    $0.Timestamp? startAt,
    $0.Timestamp? endAt,
    RecurringWindow? recurrence,
    $core.String? messageId,
    $fixnum.Int64? priority,
    $core.String? zones,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (description != null) result.description = description;
    if (cronExpr != null) result.cronExpr = cronExpr;
    if (startAt != null) result.startAt = startAt;
    if (endAt != null) result.endAt = endAt;
    if (recurrence != null) result.recurrence = recurrence;
    if (messageId != null) result.messageId = messageId;
    if (priority != null) result.priority = priority;
    if (zones != null) result.zones = zones;
    return result;
  }

  MessageTaskCreateRequest._();

  factory MessageTaskCreateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageTaskCreateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageTaskCreateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'cronExpr')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'startAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'endAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<RecurringWindow>(6, _omitFieldNames ? '' : 'recurrence',
        subBuilder: RecurringWindow.create)
    ..aOS(7, _omitFieldNames ? '' : 'messageId')
    ..aInt64(8, _omitFieldNames ? '' : 'priority')
    ..aOS(9, _omitFieldNames ? '' : 'zones')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTaskCreateRequest clone() =>
      MessageTaskCreateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTaskCreateRequest copyWith(
          void Function(MessageTaskCreateRequest) updates) =>
      super.copyWith((message) => updates(message as MessageTaskCreateRequest))
          as MessageTaskCreateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageTaskCreateRequest create() => MessageTaskCreateRequest._();
  @$core.override
  MessageTaskCreateRequest createEmptyInstance() => create();
  static $pb.PbList<MessageTaskCreateRequest> createRepeated() =>
      $pb.PbList<MessageTaskCreateRequest>();
  @$core.pragma('dart2js:noInline')
  static MessageTaskCreateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageTaskCreateRequest>(create);
  static MessageTaskCreateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get cronExpr => $_getSZ(2);
  @$pb.TagNumber(3)
  set cronExpr($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCronExpr() => $_has(2);
  @$pb.TagNumber(3)
  void clearCronExpr() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get startAt => $_getN(3);
  @$pb.TagNumber(4)
  set startAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStartAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureStartAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $0.Timestamp get endAt => $_getN(4);
  @$pb.TagNumber(5)
  set endAt($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasEndAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureEndAt() => $_ensure(4);

  @$pb.TagNumber(6)
  RecurringWindow get recurrence => $_getN(5);
  @$pb.TagNumber(6)
  set recurrence(RecurringWindow value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRecurrence() => $_has(5);
  @$pb.TagNumber(6)
  void clearRecurrence() => $_clearField(6);
  @$pb.TagNumber(6)
  RecurringWindow ensureRecurrence() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get messageId => $_getSZ(6);
  @$pb.TagNumber(7)
  set messageId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMessageId() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessageId() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get priority => $_getI64(7);
  @$pb.TagNumber(8)
  set priority($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPriority() => $_has(7);
  @$pb.TagNumber(8)
  void clearPriority() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get zones => $_getSZ(8);
  @$pb.TagNumber(9)
  set zones($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasZones() => $_has(8);
  @$pb.TagNumber(9)
  void clearZones() => $_clearField(9);
}

class MessageTaskUpdateRequest extends $pb.GeneratedMessage {
  factory MessageTaskUpdateRequest({
    $core.String? description,
    $core.String? cronExpr,
    $0.Timestamp? startAt,
    $0.Timestamp? endAt,
    RecurringWindow? recurrence,
    $core.String? messageId,
    $fixnum.Int64? priority,
    $core.String? zones,
  }) {
    final result = create();
    if (description != null) result.description = description;
    if (cronExpr != null) result.cronExpr = cronExpr;
    if (startAt != null) result.startAt = startAt;
    if (endAt != null) result.endAt = endAt;
    if (recurrence != null) result.recurrence = recurrence;
    if (messageId != null) result.messageId = messageId;
    if (priority != null) result.priority = priority;
    if (zones != null) result.zones = zones;
    return result;
  }

  MessageTaskUpdateRequest._();

  factory MessageTaskUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageTaskUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageTaskUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'fusion.tasks.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'description')
    ..aOS(2, _omitFieldNames ? '' : 'cronExpr')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'startAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'endAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<RecurringWindow>(5, _omitFieldNames ? '' : 'recurrence',
        subBuilder: RecurringWindow.create)
    ..aOS(6, _omitFieldNames ? '' : 'messageId')
    ..aInt64(7, _omitFieldNames ? '' : 'priority')
    ..aOS(8, _omitFieldNames ? '' : 'zones')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTaskUpdateRequest clone() =>
      MessageTaskUpdateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTaskUpdateRequest copyWith(
          void Function(MessageTaskUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as MessageTaskUpdateRequest))
          as MessageTaskUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageTaskUpdateRequest create() => MessageTaskUpdateRequest._();
  @$core.override
  MessageTaskUpdateRequest createEmptyInstance() => create();
  static $pb.PbList<MessageTaskUpdateRequest> createRepeated() =>
      $pb.PbList<MessageTaskUpdateRequest>();
  @$core.pragma('dart2js:noInline')
  static MessageTaskUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageTaskUpdateRequest>(create);
  static MessageTaskUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get description => $_getSZ(0);
  @$pb.TagNumber(1)
  set description($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDescription() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescription() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cronExpr => $_getSZ(1);
  @$pb.TagNumber(2)
  set cronExpr($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCronExpr() => $_has(1);
  @$pb.TagNumber(2)
  void clearCronExpr() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get startAt => $_getN(2);
  @$pb.TagNumber(3)
  set startAt($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStartAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureStartAt() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.Timestamp get endAt => $_getN(3);
  @$pb.TagNumber(4)
  set endAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEndAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureEndAt() => $_ensure(3);

  @$pb.TagNumber(5)
  RecurringWindow get recurrence => $_getN(4);
  @$pb.TagNumber(5)
  set recurrence(RecurringWindow value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRecurrence() => $_has(4);
  @$pb.TagNumber(5)
  void clearRecurrence() => $_clearField(5);
  @$pb.TagNumber(5)
  RecurringWindow ensureRecurrence() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get messageId => $_getSZ(5);
  @$pb.TagNumber(6)
  set messageId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMessageId() => $_has(5);
  @$pb.TagNumber(6)
  void clearMessageId() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get priority => $_getI64(6);
  @$pb.TagNumber(7)
  set priority($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPriority() => $_has(6);
  @$pb.TagNumber(7)
  void clearPriority() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get zones => $_getSZ(7);
  @$pb.TagNumber(8)
  set zones($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasZones() => $_has(7);
  @$pb.TagNumber(8)
  void clearZones() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
