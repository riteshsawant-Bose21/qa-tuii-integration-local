// This is a generated file - do not edit.
//
// Generated from fusion/udp.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class UDPDebugStats extends $pb.GeneratedMessage {
  factory UDPDebugStats({
    $core.int? queueDepth,
    $core.int? queueCapacity,
    $fixnum.Int64? maxQueueDepth,
    $core.int? registeredClients,
    $core.int? pendingBroadcasts,
    $fixnum.Int64? oldestPendingAgeMs,
    $fixnum.Int64? enqueuedPackets,
    $fixnum.Int64? droppedPackets,
    $fixnum.Int64? handledPackets,
    $fixnum.Int64? ackPackets,
    $fixnum.Int64? responsesSent,
    $fixnum.Int64? broadcastMessages,
    $fixnum.Int64? broadcastDatagrams,
    $fixnum.Int64? lastBroadcastEpoch,
    $fixnum.Int64? lastBroadcastVersion,
    $fixnum.Int64? lastBroadcastSentAtNs,
    $core.bool? maintenanceEnabled,
  }) {
    final result = create();
    if (queueDepth != null) result.queueDepth = queueDepth;
    if (queueCapacity != null) result.queueCapacity = queueCapacity;
    if (maxQueueDepth != null) result.maxQueueDepth = maxQueueDepth;
    if (registeredClients != null) result.registeredClients = registeredClients;
    if (pendingBroadcasts != null) result.pendingBroadcasts = pendingBroadcasts;
    if (oldestPendingAgeMs != null)
      result.oldestPendingAgeMs = oldestPendingAgeMs;
    if (enqueuedPackets != null) result.enqueuedPackets = enqueuedPackets;
    if (droppedPackets != null) result.droppedPackets = droppedPackets;
    if (handledPackets != null) result.handledPackets = handledPackets;
    if (ackPackets != null) result.ackPackets = ackPackets;
    if (responsesSent != null) result.responsesSent = responsesSent;
    if (broadcastMessages != null) result.broadcastMessages = broadcastMessages;
    if (broadcastDatagrams != null)
      result.broadcastDatagrams = broadcastDatagrams;
    if (lastBroadcastEpoch != null)
      result.lastBroadcastEpoch = lastBroadcastEpoch;
    if (lastBroadcastVersion != null)
      result.lastBroadcastVersion = lastBroadcastVersion;
    if (lastBroadcastSentAtNs != null)
      result.lastBroadcastSentAtNs = lastBroadcastSentAtNs;
    if (maintenanceEnabled != null)
      result.maintenanceEnabled = maintenanceEnabled;
    return result;
  }

  UDPDebugStats._();

  factory UDPDebugStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UDPDebugStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UDPDebugStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fusion'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'queueDepth', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'queueCapacity', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'maxQueueDepth', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'registeredClients', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'pendingBroadcasts', $pb.PbFieldType.OU3)
    ..aInt64(6, _omitFieldNames ? '' : 'oldestPendingAgeMs')
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'enqueuedPackets', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'droppedPackets', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'handledPackets', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'ackPackets', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'responsesSent', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        12, _omitFieldNames ? '' : 'broadcastMessages', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        13, _omitFieldNames ? '' : 'broadcastDatagrams', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        14, _omitFieldNames ? '' : 'lastBroadcastEpoch', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        15, _omitFieldNames ? '' : 'lastBroadcastVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(16, _omitFieldNames ? '' : 'lastBroadcastSentAtNs')
    ..aOB(17, _omitFieldNames ? '' : 'maintenanceEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UDPDebugStats clone() => UDPDebugStats()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UDPDebugStats copyWith(void Function(UDPDebugStats) updates) =>
      super.copyWith((message) => updates(message as UDPDebugStats))
          as UDPDebugStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UDPDebugStats create() => UDPDebugStats._();
  @$core.override
  UDPDebugStats createEmptyInstance() => create();
  static $pb.PbList<UDPDebugStats> createRepeated() =>
      $pb.PbList<UDPDebugStats>();
  @$core.pragma('dart2js:noInline')
  static UDPDebugStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UDPDebugStats>(create);
  static UDPDebugStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get queueDepth => $_getIZ(0);
  @$pb.TagNumber(1)
  set queueDepth($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueueDepth() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueueDepth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get queueCapacity => $_getIZ(1);
  @$pb.TagNumber(2)
  set queueCapacity($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQueueCapacity() => $_has(1);
  @$pb.TagNumber(2)
  void clearQueueCapacity() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get maxQueueDepth => $_getI64(2);
  @$pb.TagNumber(3)
  set maxQueueDepth($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxQueueDepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxQueueDepth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get registeredClients => $_getIZ(3);
  @$pb.TagNumber(4)
  set registeredClients($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRegisteredClients() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegisteredClients() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get pendingBroadcasts => $_getIZ(4);
  @$pb.TagNumber(5)
  set pendingBroadcasts($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPendingBroadcasts() => $_has(4);
  @$pb.TagNumber(5)
  void clearPendingBroadcasts() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get oldestPendingAgeMs => $_getI64(5);
  @$pb.TagNumber(6)
  set oldestPendingAgeMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOldestPendingAgeMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearOldestPendingAgeMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get enqueuedPackets => $_getI64(6);
  @$pb.TagNumber(7)
  set enqueuedPackets($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEnqueuedPackets() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnqueuedPackets() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get droppedPackets => $_getI64(7);
  @$pb.TagNumber(8)
  set droppedPackets($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDroppedPackets() => $_has(7);
  @$pb.TagNumber(8)
  void clearDroppedPackets() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get handledPackets => $_getI64(8);
  @$pb.TagNumber(9)
  set handledPackets($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHandledPackets() => $_has(8);
  @$pb.TagNumber(9)
  void clearHandledPackets() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get ackPackets => $_getI64(9);
  @$pb.TagNumber(10)
  set ackPackets($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAckPackets() => $_has(9);
  @$pb.TagNumber(10)
  void clearAckPackets() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get responsesSent => $_getI64(10);
  @$pb.TagNumber(11)
  set responsesSent($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasResponsesSent() => $_has(10);
  @$pb.TagNumber(11)
  void clearResponsesSent() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get broadcastMessages => $_getI64(11);
  @$pb.TagNumber(12)
  set broadcastMessages($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasBroadcastMessages() => $_has(11);
  @$pb.TagNumber(12)
  void clearBroadcastMessages() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get broadcastDatagrams => $_getI64(12);
  @$pb.TagNumber(13)
  set broadcastDatagrams($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasBroadcastDatagrams() => $_has(12);
  @$pb.TagNumber(13)
  void clearBroadcastDatagrams() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get lastBroadcastEpoch => $_getI64(13);
  @$pb.TagNumber(14)
  set lastBroadcastEpoch($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasLastBroadcastEpoch() => $_has(13);
  @$pb.TagNumber(14)
  void clearLastBroadcastEpoch() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get lastBroadcastVersion => $_getI64(14);
  @$pb.TagNumber(15)
  set lastBroadcastVersion($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLastBroadcastVersion() => $_has(14);
  @$pb.TagNumber(15)
  void clearLastBroadcastVersion() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get lastBroadcastSentAtNs => $_getI64(15);
  @$pb.TagNumber(16)
  set lastBroadcastSentAtNs($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasLastBroadcastSentAtNs() => $_has(15);
  @$pb.TagNumber(16)
  void clearLastBroadcastSentAtNs() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get maintenanceEnabled => $_getBF(16);
  @$pb.TagNumber(17)
  set maintenanceEnabled($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasMaintenanceEnabled() => $_has(16);
  @$pb.TagNumber(17)
  void clearMaintenanceEnabled() => $_clearField(17);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
