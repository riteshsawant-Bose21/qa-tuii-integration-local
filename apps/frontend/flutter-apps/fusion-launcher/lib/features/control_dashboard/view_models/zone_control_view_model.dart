import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../projects/view_model/block_data/block_data_viewmodel.dart';
part 'zone_control_state.dart';

/// Per-zone cubit that manages **gain** and **mute** state by talking to the
/// device via [BlockDataViewmodel.getBlockData] / [updateBlockParameter].
///
/// Subscribes to [BlockDataViewmodel.stream] for real-time WebSocket-pushed
/// gain/mute updates so the UI stays in sync with the device.
class ZoneControlViewModel extends Cubit<ZoneControlState> {
  ZoneControlViewModel({
    required this.zoneId,
  }) : super(ZoneControlState(blockId: processingBlockFor(zoneId)?.id)) {
    _fetchInitialValues();
    _subscribeToBlockDataStream();
  }
  final String zoneId;

  /// Subscription to [BlockDataViewmodel] state changes for real-time
  /// WebSocket-pushed block data updates.
  StreamSubscription<Map<String, dynamic>?>? _blockDataSubscription;

  static const double _minGain = -60.0;
  static const double _maxGain = 12.0;
  static const double _stepGain = 1.0;

  @override
  Future<void> close() {
    _blockDataSubscription?.cancel();
    return super.close();
  }

  // ── WebSocket push subscription ────────────────────────────────────────

  /// Listens to [BlockDataViewmodel.stream] and applies incoming WebSocket
  /// gain/mute updates for this zone's processing block in real time.
  void _subscribeToBlockDataStream() {
    final String? blockId = processingBlock?.id;
    if (blockId == null) return;

    final BlockDataViewmodel blockDataVM = serviceLocator<BlockDataViewmodel>();
    _blockDataSubscription = blockDataVM.stream.map((BlockDataState s) => s.allBlockData[blockId]).distinct().listen((Map<String, dynamic>? blockData) {
      if (blockData == null || blockData.isEmpty || isClosed) return;

      final double? gain = _parseDouble(blockData['gain']);
      final bool? muted = _parseBool(blockData['mute']);

      // Only emit if something actually changed to avoid loops.
      if ((gain != null && gain != state.gain) || (muted != null && muted != state.muted)) {
        emit(
          state.copyWith(
            gain: gain ?? state.gain,
            muted: muted ?? state.muted,
            clearError: true,
          ),
        );
      }
    });
  }

  // ── zone data accessors ────────────────────────────────────────────────

  /// The user-facing gain [ProcessingBlockModel] for this zone/subzone.
  ProcessingBlockModel? get processingBlock => processingBlockFor(zoneId);

  /// Subzones belonging to this zone.
  List<SubZone> get subZones {
    return serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zoneId);
  }

  /// Circuits belonging to this zone (zone-level only).
  List<CircuitModel> get circuits {
    return serviceLocator<ProjectViewModel>().getCircuitsInZone(zoneId);
  }

  /// Circuits belonging to a subzone.
  List<CircuitModel> getCircuitsInSubZone({required String subZoneId}) {
    return serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZoneId);
  }

  /// Static helper so the constructor initializer can call it before `this` is available.
  static ProcessingBlockModel? processingBlockFor(String zoneId) {
    return serviceLocator<ProjectViewModel>().getUserFacingGainBlockForZone(zoneId: zoneId);
  }

  // ── public API ─────────────────────────────────────────────────────────
  void setGain(double value) {
    final double clamped = value.clamp(_minGain, _maxGain);
    emit(state.copyWith(gain: clamped, clearError: true));
    _pushGainToDevice(clamped);
  }

  void incrementGain() {
    final double newGain = (state.gain + _stepGain).clamp(_minGain, _maxGain);
    emit(state.copyWith(gain: newGain, clearError: true));
    _pushGainToDevice(newGain);
  }

  void decrementGain() {
    final double newGain = (state.gain - _stepGain).clamp(_minGain, _maxGain);
    emit(state.copyWith(gain: newGain, clearError: true));
    _pushGainToDevice(newGain);
  }

  void toggleMute() {
    final bool newMuted = !state.muted;
    emit(state.copyWith(muted: newMuted, clearError: true));
    _pushMuteToDevice(newMuted);
  }

  /// Converts a percentage value (0–100) to a dBFS value (-60 to 12)
  double percentageToDbfs(double percentage) {
    const double minDb = -60.0;
    const double maxDb = 12.0;

    final double clamped = percentage.clamp(0.0, 100.0);
    return minDb + (clamped / 100.0) * (maxDb - minDb);
  }

  /// Converts a dBFS value (-60 to 12) to a percentage value (0–100)
  double dbfsToPercentage(double dbfs) {
    const double minDb = -60.0;
    const double maxDb = 12.0;

    final double clamped = dbfs.clamp(minDb, maxDb);
    return ((clamped - minDb) / (maxDb - minDb)) * 100.0;
  }

  // ── private helpers ────────────────────────────────────────────────────
  Future<void> _fetchInitialValues() async {
    final String? blockId = processingBlock?.id;
    if (blockId == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final Map<String, dynamic>? data = await serviceLocator<BlockDataViewmodel>().getBlockData(blockId: blockId);
      if (data != null) {
        final double gain = _parseDouble(data['gain']) ?? state.gain;
        final bool muted = _parseBool(data['mute']) ?? state.muted;
        emit(state.copyWith(gain: gain, muted: muted, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      debugPrint('[ZoneControlVM] Failed to fetch block data for $blockId: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _pushGainToDevice(double gain) {
    final String? blockId = processingBlock?.id;
    if (blockId == null) return;
    serviceLocator<BlockDataViewmodel>().updateBlockParameter(
      blockId: blockId,
      parameter: 'gain',
      value: gain,
    );
  }

  void _pushMuteToDevice(bool muted) {
    final String? blockId = processingBlock?.id;
    if (blockId == null) return;
    serviceLocator<BlockDataViewmodel>().updateBlockParameter(
      blockId: blockId,
      parameter: 'mute',
      value: muted,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }
}
