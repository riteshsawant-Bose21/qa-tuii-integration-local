part of 'assign_circuit_viewmodel.dart';

// ── Circuit tree nodes ────────────────────────────────────────────────────────

sealed class CircuitTreeNode {
  const CircuitTreeNode();
}

/// A zone that has NO sub-zones — circuits are its direct children.
class ZoneTreeNode extends CircuitTreeNode {
  final String id;
  final String name;
  final Color color;
  final List<CircuitModel> circuits;

  const ZoneTreeNode({
    required this.id,
    required this.name,
    required this.color,
    required this.circuits,
  });
}

/// A zone that HAS sub-zones — children are [SubZoneTreeNode]s.
class ZoneWithSubZonesTreeNode extends CircuitTreeNode {
  final String id;
  final String name;
  final Color color;
  final List<SubZoneTreeNode> subZones;

  const ZoneWithSubZonesTreeNode({
    required this.id,
    required this.name,
    required this.color,
    required this.subZones,
  });
}

/// A sub-zone — circuits are its direct children.
class SubZoneTreeNode extends CircuitTreeNode {
  final String id;
  final String name;
  final List<CircuitModel> circuits;

  const SubZoneTreeNode({
    required this.id,
    required this.name,
    required this.circuits,
  });
}

// ── Per-channel row ───────────────────────────────────────────────────────────

class ChannelAssignmentRow {
  final int channelNumber;
  final String channelLabel;

  /// ID of the currently selected [CircuitModel], or null if unassigned.
  final String? selectedCircuitId;

  const ChannelAssignmentRow({
    required this.channelNumber,
    required this.channelLabel,
    this.selectedCircuitId,
  });

  ChannelAssignmentRow copyWith({String? selectedCircuitId, bool clearCircuit = false}) {
    return ChannelAssignmentRow(
      channelNumber: channelNumber,
      channelLabel: channelLabel,
      selectedCircuitId: clearCircuit ? null : (selectedCircuitId ?? this.selectedCircuitId),
    );
  }
}

// ── Sealed states ─────────────────────────────────────────────────────────────

sealed class AssignCircuitState {
  const AssignCircuitState();
}

class AssignCircuitInitial extends AssignCircuitState {
  const AssignCircuitInitial();
}

class AssignCircuitLoading extends AssignCircuitState {
  const AssignCircuitLoading();
}

class AssignCircuitLoaded extends AssignCircuitState {
  final Aes67Config stream;

  /// Flat list of tree nodes (one entry per zone).
  final List<CircuitTreeNode> zoneTree;

  /// Per-channel assignment rows.
  final List<ChannelAssignmentRow> channelRows;

  /// Which channel is currently active in the left panel (by channelNumber).
  final int selectedChannelNumber;

  const AssignCircuitLoaded({
    required this.stream,
    required this.zoneTree,
    required this.channelRows,
    required this.selectedChannelNumber,
  });

  ChannelAssignmentRow get selectedChannel =>
      channelRows.firstWhere((ChannelAssignmentRow r) => r.channelNumber == selectedChannelNumber, orElse: () => channelRows.first);

  AssignCircuitLoaded copyWith({
    List<ChannelAssignmentRow>? channelRows,
    int? selectedChannelNumber,
  }) {
    return AssignCircuitLoaded(
      stream: stream,
      zoneTree: zoneTree,
      channelRows: channelRows ?? this.channelRows,
      selectedChannelNumber: selectedChannelNumber ?? this.selectedChannelNumber,
    );
  }

  /// Returns the stream with `assignedTo` baked into each channelConfig.
  Aes67Config buildUpdatedStream() {
    final List<Aes67ChannelConfig> updatedConfigs =
        stream.channelConfigs.map((Aes67ChannelConfig ch) {
          final ChannelAssignmentRow? row = channelRows.where((ChannelAssignmentRow r) => r.channelNumber == ch.channelNumber).firstOrNull;
          if (row?.selectedCircuitId != null) {
            return ch.copyWith(assignedTo: row!.selectedCircuitId);
          }
          return ch.copyWith(clearAssignedTo: true);
        }).toList();
    return stream.copyWith(channelConfigs: updatedConfigs);
  }
}
