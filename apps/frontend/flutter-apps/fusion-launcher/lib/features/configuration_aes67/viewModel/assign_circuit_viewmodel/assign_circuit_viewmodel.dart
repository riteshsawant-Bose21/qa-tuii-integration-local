import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'assign_circuit_state.dart';

class AssignCircuitViewmodel extends Cubit<AssignCircuitState> {
  final ProjectViewModel _projectViewModel;

  AssignCircuitViewmodel({required ProjectViewModel projectViewModel}) : _projectViewModel = projectViewModel, super(const AssignCircuitInitial());

  void init(Aes67Config stream) {
    emit(const AssignCircuitLoading());

    // ── Build zone tree ──────────────────────────────────────────────
    final List<Zone> allZones = _projectViewModel.getAllZones();
    final List<CircuitTreeNode> tree =
        allZones.map((Zone zone) {
          final List<SubZone> subZones = _projectViewModel.getSubZonesForZone(parentZoneId: zone.id);
          if (subZones.isEmpty) {
            return ZoneTreeNode(
              id: zone.id,
              name: zone.name,
              color: zone.color,
              circuits: _projectViewModel.getCircuitsInZone(zone.id),
            );
          }
          return ZoneWithSubZonesTreeNode(
            id: zone.id,
            name: zone.name,
            color: zone.color,
            subZones:
                subZones.map((SubZone sz) {
                  return SubZoneTreeNode(
                    id: sz.id,
                    name: sz.name,
                    circuits: _projectViewModel.getCircuitsInSubZone(subZoneId: sz.id),
                  );
                }).toList(),
          );
        }).toList();

    // ── Build per-channel rows (pre-fill existing assignments) ───────
    final List<ChannelAssignmentRow> rows =
        stream.channelConfigs.map((Aes67ChannelConfig ch) {
          return ChannelAssignmentRow(
            channelNumber: ch.channelNumber,
            channelLabel: ch.label ?? 'Channel ${ch.channelNumber}',
            selectedCircuitId: ch.assignedTo,
          );
        }).toList();

    emit(
      AssignCircuitLoaded(
        stream: stream,
        zoneTree: tree,
        channelRows: rows,
        selectedChannelNumber: rows.isNotEmpty ? rows.first.channelNumber : 1,
      ),
    );
  }

  // ── Channel selection ─────────────────────────────────────────────

  void selectChannel(int channelNumber) {
    final AssignCircuitLoaded? s = _loaded;
    if (s == null) return;
    emit(s.copyWith(selectedChannelNumber: channelNumber));
  }

  // ── Circuit selection for active channel ─────────────────────────
  //
  // Tapping an already-selected circuit deselects it (toggles off).

  void selectCircuit(int channelNumber, String circuitId) {
    final AssignCircuitLoaded? s = _loaded;
    if (s == null) return;
    final List<ChannelAssignmentRow> updated =
        s.channelRows.map((ChannelAssignmentRow r) {
          if (r.channelNumber == channelNumber) {
            // Toggle: tap selected circuit → clear; tap other circuit → set
            final bool alreadySelected = r.selectedCircuitId == circuitId;
            return alreadySelected ? r.copyWith(clearCircuit: true) : r.copyWith(selectedCircuitId: circuitId);
          }
          return r;
        }).toList();
    emit(s.copyWith(channelRows: updated));
  }

  // ── Save ──────────────────────────────────────────────────────────

  Aes67Config? buildUpdatedStream() => _loaded?.buildUpdatedStream();

  // ── Helpers ───────────────────────────────────────────────────────

  AssignCircuitLoaded? get _loaded {
    final AssignCircuitState s = state;
    return s is AssignCircuitLoaded ? s : null;
  }
}
