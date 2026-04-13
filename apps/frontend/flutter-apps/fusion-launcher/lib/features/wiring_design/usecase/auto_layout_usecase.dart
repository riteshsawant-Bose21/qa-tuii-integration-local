import 'dart:math' as math;
import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/wiring_controller_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/wiring_devices_painter.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/connection_manager.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/zone_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_zone_painter.dart';

class WiringAutoLayoutUseCase {
  static const double _horizontalGroupGap = 200;
  static const double _verticalGroupGap = 200;
  static const double _topRowDeviceGap = 120;

  List<WiringLayoutResult> execute({
    required List<HardwareComponent> devices,
    required List<WiringConnectionModel> connections,
    required List<Zone> zones,
    required WiringZoneManager zoneManager,
  }) {
    final ConnectionManager connectionManager = ConnectionManager();
    final List<WiringZonePainter> zonePainters =
        zones.map((Zone zone) => WiringZonePainter(zone: zone, zoneManager: zoneManager, connectionManager: connectionManager)).toList();
    final List<WiringSourcePainter> sourcePainters = <WiringSourcePainter>[];
    final List<WiringDevicesPainter> dspPainters = <WiringDevicesPainter>[];
    final List<WiringDevicesPainter> amplifierPainters = <WiringDevicesPainter>[];
    final List<WiringDevicesPainter> otherPainters = <WiringDevicesPainter>[];

    for (final HardwareComponent device in devices) {
      if (device is Source) {
        sourcePainters.add(WiringSourcePainter(source: device, connectionManager: connectionManager));
        continue;
      }
      if (device is Amplifier) {
        amplifierPainters.add(WiringDevicesPainter(device: device, connectionManager: connectionManager));
        continue;
      }
      if (device is FusionDsp) {
        dspPainters.add(WiringDevicesPainter(device: device, connectionManager: connectionManager));
        continue;
      }
      otherPainters.add(WiringControllerPainter(device: device, connectionManager: connectionManager));
    }

    final Map<String, Size> sizeById = <String, Size>{
      for (final WiringSourcePainter painter in sourcePainters) painter.source.id: painter.getSize(),
      for (final WiringDevicesPainter painter in dspPainters) painter.device.id: painter.getSize(),
      for (final WiringDevicesPainter painter in amplifierPainters) painter.device.id: painter.getSize(),
      for (final WiringDevicesPainter painter in otherPainters) painter.device.id: painter.getSize(),
      for (final WiringZonePainter painter in zonePainters) painter.zone.id: painter.getSize(),
    };

    final List<Source> sources = sourcePainters.map((WiringSourcePainter painter) => painter.source).toList();
    final List<FusionDsp> dsps = dspPainters.map((WiringDevicesPainter painter) => painter.device).whereType<FusionDsp>().toList();
    final List<Amplifier> amplifiers = amplifierPainters.map((WiringDevicesPainter painter) => painter.device).whereType<Amplifier>().toList();
    final List<HardwareComponent> others = otherPainters.map((WiringDevicesPainter painter) => painter.device).toList();
    final Map<String, HardwareComponent> hardwareById = <String, HardwareComponent>{for (final HardwareComponent device in devices) device.id: device};
    final Map<String, List<int>> sourceConnectionPortRanks = _buildSourceConnectionPortRanks(
      sources: sources,
      connections: connections,
      hardwareById: hardwareById,
    );

    final Map<String, FusionDsp> dspById = <String, FusionDsp>{for (final FusionDsp dsp in dsps) dsp.id: dsp};
    final Map<String, Amplifier> amplifierById = <String, Amplifier>{for (final Amplifier amp in amplifiers) amp.id: amp};
    final Map<String, Zone> zoneById = <String, Zone>{for (final Zone zone in zones) zone.id: zone};
    final Map<String, HardwareComponent> otherById = <String, HardwareComponent>{for (final HardwareComponent other in others) other.id: other};

    final List<HardwareComponent> orderedOthers =
        others.toList()..sort((HardwareComponent a, HardwareComponent b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final Map<String, int> otherOrderById = <String, int>{for (int i = 0; i < orderedOthers.length; i++) orderedOthers[i].id: i};

    final Map<String, _TopSourceLinkMeta> topSourceLinkMetaById = _buildTopSourceLinkMeta(
      sources: sources,
      connections: connections,
      otherById: otherById,
      otherOrderById: otherOrderById,
    );
    final Set<String> topConnectedSourceIds = topSourceLinkMetaById.keys.toSet();
    final List<Source> topConnectedSources =
        sources.where((Source source) => topConnectedSourceIds.contains(source.id)).toList()..sort((Source a, Source b) {
          final List<int> aRanks = sourceConnectionPortRanks[a.id] ?? <int>[1 << 30];
          final List<int> bRanks = sourceConnectionPortRanks[b.id] ?? <int>[1 << 30];
          final int rankCompare = _compareOrderedIntLists(aRanks, bRanks);
          if (rankCompare != 0) {
            return rankCompare;
          }
          final _TopSourceLinkMeta aMeta = topSourceLinkMetaById[a.id]!;
          final _TopSourceLinkMeta bMeta = topSourceLinkMetaById[b.id]!;
          if (aMeta.otherOrder != bMeta.otherOrder) {
            return aMeta.otherOrder.compareTo(bMeta.otherOrder);
          }
          if (aMeta.otherPortOrder != bMeta.otherPortOrder) {
            return aMeta.otherPortOrder.compareTo(bMeta.otherPortOrder);
          }
          if (aMeta.sourcePortOrder != bMeta.sourcePortOrder) {
            return aMeta.sourcePortOrder.compareTo(bMeta.sourcePortOrder);
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    final double sourceColumnMaxWidth = _maxWidth(sources.map((Source source) => sizeById[source.id]));
    final double dspColumnMaxWidth = _maxWidth(dsps.map((FusionDsp dsp) => sizeById[dsp.id]));
    final double rightColumnMaxWidth = _maxWidth(amplifiers.map((Amplifier amp) => sizeById[amp.id]));
    final double zoneColumnMaxWidth = _maxWidth(zones.map((Zone zone) => sizeById[zone.id]));

    final double sourceColumnCenterX = sourceColumnMaxWidth / 2;
    final double dspColumnCenterX = sourceColumnCenterX + sourceColumnMaxWidth / 2 + _horizontalGroupGap + dspColumnMaxWidth / 2;
    final double rightColumnCenterX = dspColumnCenterX + dspColumnMaxWidth / 2 + _horizontalGroupGap + rightColumnMaxWidth / 2;
    final double zoneColumnCenterX = rightColumnCenterX + rightColumnMaxWidth / 2 + _horizontalGroupGap + zoneColumnMaxWidth / 2;

    final Map<int, _EquipmentGroup> groups = _buildEquipmentGroups(
      dsps: dsps,
      amplifiers: amplifiers,
      connections: connections,
      dspById: dspById,
    );
    for (final Source source in sources) {
      if (source.equipmentLocationPosition != null) {
        final int sourceGroupKey = _locationKey(source.equipmentLocationPosition);
        groups.putIfAbsent(sourceGroupKey, _EquipmentGroup.new);
      }
    }
    final List<int> orderedGroupKeys = groups.keys.toList()..sort();
    final Map<String, int> dspOrderById = <String, int>{};
    int dspOrderCounter = 0;
    for (final int groupKey in orderedGroupKeys) {
      final _EquipmentGroup group = groups[groupKey]!;
      for (final FusionDsp dsp in group.dsps) {
        dspOrderById[dsp.id] = dspOrderCounter;
        dspOrderCounter += 1;
      }
    }

    final Map<String, _SourceLinkMeta> sourceLinkMetaById = _buildSourceLinkMeta(
      sources: sources,
      connections: connections,
      dspById: dspById,
      orderedGroupKeys: orderedGroupKeys,
    );
    final Map<String, String?> connectedDspIdByAmplifierId = <String, String?>{
      for (final Amplifier amplifier in amplifiers)
        amplifier.id: _findConnectedDspIdForAmplifier(
          amplifierId: amplifier.id,
          connections: connections,
          dspIds: dspById.keys,
        ),
    };
    final Map<String, String?> connectedDspIdBySourceId = <String, String?>{
      for (final Source source in sources) source.id: sourceLinkMetaById[source.id]?.dspId,
    };

    final Map<int, List<Source>> sourcesByGroupKey = <int, List<Source>>{};
    for (final Source source in sources) {
      if (topConnectedSourceIds.contains(source.id)) {
        continue;
      }
      final _SourceLinkMeta? meta = sourceLinkMetaById[source.id];
      int? resolvedGroupKey;
      if (meta != null && meta.groupKey != _unassignedGroupKey && groups.containsKey(meta.groupKey)) {
        resolvedGroupKey = meta.groupKey;
      } else if (source.equipmentLocationPosition != null) {
        final int sourceLocationGroupKey = _locationKey(source.equipmentLocationPosition);
        if (groups.containsKey(sourceLocationGroupKey)) {
          resolvedGroupKey = sourceLocationGroupKey;
        }
      }

      resolvedGroupKey ??= orderedGroupKeys.isNotEmpty ? orderedGroupKeys.first : _unassignedGroupKey;
      sourcesByGroupKey.putIfAbsent(resolvedGroupKey, () => <Source>[]).add(source);
    }
    for (final MapEntry<int, List<Source>> entry in sourcesByGroupKey.entries) {
      entry.value.sort((Source a, Source b) {
        final List<int> aRanks = sourceConnectionPortRanks[a.id] ?? <int>[1 << 30];
        final List<int> bRanks = sourceConnectionPortRanks[b.id] ?? <int>[1 << 30];
        final int rankCompare = _compareOrderedIntLists(aRanks, bRanks);
        if (rankCompare != 0) {
          return rankCompare;
        }
        final _SourceLinkMeta aMeta = sourceLinkMetaById[a.id]!;
        final _SourceLinkMeta bMeta = sourceLinkMetaById[b.id]!;
        if (aMeta.dspPortOrder != bMeta.dspPortOrder) {
          return aMeta.dspPortOrder.compareTo(bMeta.dspPortOrder);
        }
        if (aMeta.sourcePortOrder != bMeta.sourcePortOrder) {
          return aMeta.sourcePortOrder.compareTo(bMeta.sourcePortOrder);
        }
        final int aDspOrder = aMeta.dspId != null ? (dspOrderById[aMeta.dspId!] ?? (1 << 30)) : (1 << 30);
        final int bDspOrder = bMeta.dspId != null ? (dspOrderById[bMeta.dspId!] ?? (1 << 30)) : (1 << 30);
        if (aDspOrder != bDspOrder) {
          return aDspOrder.compareTo(bDspOrder);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    final List<WiringLayoutResult> results = <WiringLayoutResult>[];

    // Keep remaining devices as a dedicated top row.
    final double topRowHeight = _maxHeight(orderedOthers.map((HardwareComponent device) => sizeById[device.id]));
    final Map<String, double> otherCenterXById = <String, double>{};
    double topRowCursorX = 0;
    for (final HardwareComponent other in orderedOthers) {
      final Size otherSize = sizeById[other.id] ?? Size.zero;
      final double centerX = topRowCursorX + otherSize.width / 2;
      otherCenterXById[other.id] = centerX;
      results.add(
        WiringLayoutResult(
          hardwareComponent: other,
          position: Offset(centerX, topRowHeight / 2),
        ),
      );
      topRowCursorX += otherSize.width + _topRowDeviceGap;
    }

    final double topConnectedSourceRowHeight = _maxHeight(topConnectedSources.map((Source source) => sizeById[source.id]));
    final double topConnectedSourceRowTop = topRowHeight > 0 ? topRowHeight + _verticalGroupGap : 0;
    double topConnectedSourceCursorX = 0;
    for (final Source source in topConnectedSources) {
      final _TopSourceLinkMeta meta = topSourceLinkMetaById[source.id]!;
      final Size sourceSize = sizeById[source.id] ?? Size.zero;
      final double preferredCenterX = otherCenterXById[meta.otherDeviceId] ?? (topConnectedSourceCursorX + sourceSize.width / 2);
      final double centerX = math.max(topConnectedSourceCursorX + sourceSize.width / 2, preferredCenterX);
      results.add(
        WiringLayoutResult(
          hardwareComponent: source,
          position: Offset(centerX, topConnectedSourceRowTop + topConnectedSourceRowHeight / 2),
        ),
      );
      topConnectedSourceCursorX = centerX + sourceSize.width / 2 + _topRowDeviceGap;
    }

    final Map<String, Offset> amplifierPositionById = <String, Offset>{};

    double currentTopY = 0;
    if (topRowHeight > 0) {
      currentTopY += topRowHeight + _verticalGroupGap;
    }
    if (topConnectedSourceRowHeight > 0) {
      currentTopY += topConnectedSourceRowHeight + _verticalGroupGap;
    }
    for (final int groupKey in orderedGroupKeys) {
      final _EquipmentGroup group = groups[groupKey]!;
      final List<Source> groupSources = sourcesByGroupKey[groupKey] ?? <Source>[];
      final double sourceStackHeight = _stackHeight(groupSources, sizeById);
      final double dspStackHeight = _stackHeight(group.dsps, sizeById);
      final double rightStackHeight = _stackHeight(group.amplifiers, sizeById);
      final double groupHeight = math.max(sourceStackHeight, math.max(dspStackHeight, rightStackHeight));

      double dspTopY = currentTopY + (groupHeight - dspStackHeight) / 2;
      final Map<String, double> dspCenterYById = <String, double>{};
      for (final FusionDsp dsp in group.dsps) {
        final Size dspSize = sizeById[dsp.id] ?? Size.zero;
        final double centerY = dspTopY + dspSize.height / 2;
        dspCenterYById[dsp.id] = centerY;
        results.add(
          WiringLayoutResult(
            hardwareComponent: dsp,
            position: Offset(dspColumnCenterX, centerY),
          ),
        );
        dspTopY += dspSize.height + _verticalGroupGap;
      }

      double sourceTopY = currentTopY + (groupHeight - sourceStackHeight) / 2;
      final List<_DesiredCenter> desiredSourceCenters = <_DesiredCenter>[];
      for (final Source source in groupSources) {
        final Size sourceSize = sizeById[source.id] ?? Size.zero;
        final String? connectedDspId = connectedDspIdBySourceId[source.id];
        final double? linkedDspCenterY = connectedDspId != null ? dspCenterYById[connectedDspId] : null;
        final double preferredY = linkedDspCenterY ?? (sourceTopY + sourceSize.height / 2);
        desiredSourceCenters.add(
          _DesiredCenter(
            id: source.id,
            preferredCenterY: preferredY,
            height: sourceSize.height,
          ),
        );
        sourceTopY += sourceSize.height + _verticalGroupGap;
      }
      final Map<String, double> resolvedSourceY = _resolveNonOverlappingCenters(
        desiredSourceCenters,
        _verticalGroupGap,
      );
      for (final Source source in groupSources) {
        final double centerY = resolvedSourceY[source.id] ?? 0;
        results.add(
          WiringLayoutResult(
            hardwareComponent: source,
            position: Offset(sourceColumnCenterX, centerY),
          ),
        );
      }

      double rightTopY = currentTopY + (groupHeight - rightStackHeight) / 2;
      final List<_DesiredCenter> desiredAmplifierCenters = <_DesiredCenter>[];
      for (final Amplifier amplifier in group.amplifiers) {
        final Size ampSize = sizeById[amplifier.id] ?? Size.zero;
        final String? connectedDspId = connectedDspIdByAmplifierId[amplifier.id];
        final double? linkedDspCenterY = connectedDspId != null ? dspCenterYById[connectedDspId] : null;
        final double preferredY = linkedDspCenterY ?? (rightTopY + ampSize.height / 2);
        desiredAmplifierCenters.add(
          _DesiredCenter(
            id: amplifier.id,
            preferredCenterY: preferredY,
            height: ampSize.height,
          ),
        );
        rightTopY += ampSize.height + _verticalGroupGap;
      }
      final Map<String, double> resolvedAmplifierY = _resolveNonOverlappingCenters(
        desiredAmplifierCenters,
        _verticalGroupGap,
      );
      for (final Amplifier amplifier in group.amplifiers) {
        final double centerY = resolvedAmplifierY[amplifier.id] ?? 0;
        final Offset ampPosition = Offset(rightColumnCenterX, centerY);
        amplifierPositionById[amplifier.id] = ampPosition;
        results.add(
          WiringLayoutResult(
            hardwareComponent: amplifier,
            position: ampPosition,
          ),
        );
      }

      currentTopY += groupHeight + _verticalGroupGap;
    }

    final Map<String, String> circuitToZoneId = _buildCircuitToZoneMap(zones: zones, zoneManager: zoneManager);
    final Map<String, _ZoneLinkMeta> zoneMetaById = _buildZoneLinkMeta(
      connections: connections,
      amplifierById: amplifierById,
      zoneById: zoneById,
      circuitToZoneId: circuitToZoneId,
    );

    final Map<String, List<Zone>> zonesByAmplifierId = <String, List<Zone>>{};
    final List<Zone> unconnectedZones = <Zone>[];
    for (final Zone zone in zones) {
      final _ZoneLinkMeta? meta = zoneMetaById[zone.id];
      if (meta == null || meta.amplifierId == null) {
        unconnectedZones.add(zone);
        continue;
      }
      zonesByAmplifierId.putIfAbsent(meta.amplifierId!, () => <Zone>[]).add(zone);
    }

    for (final MapEntry<String, List<Zone>> entry in zonesByAmplifierId.entries) {
      final List<Zone> connectedZones = entry.value;
      connectedZones.sort((Zone a, Zone b) {
        final int aOrder = zoneMetaById[a.id]?.amplifierPortOrder ?? 1 << 30;
        final int bOrder = zoneMetaById[b.id]?.amplifierPortOrder ?? 1 << 30;
        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    final List<_DesiredCenter> desiredZoneCenters = <_DesiredCenter>[];
    final List<Amplifier> amplifiersByY =
        amplifiers.toList()..sort((Amplifier a, Amplifier b) {
          final double ay = amplifierPositionById[a.id]?.dy ?? double.infinity;
          final double by = amplifierPositionById[b.id]?.dy ?? double.infinity;
          if (ay != by) {
            return ay.compareTo(by);
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    for (final Amplifier amplifier in amplifiersByY) {
      final Offset? ampPosition = amplifierPositionById[amplifier.id];
      if (ampPosition == null) {
        continue;
      }
      final List<Zone> connectedZones = zonesByAmplifierId[amplifier.id] ?? <Zone>[];
      if (connectedZones.isEmpty) {
        continue;
      }
      final double zonesStackHeight = _stackHeight(connectedZones, sizeById);
      double zoneTopY = ampPosition.dy - zonesStackHeight / 2;
      for (final Zone zone in connectedZones) {
        final Size zoneSize = sizeById[zone.id] ?? Size.zero;
        final double preferredCenterY = zoneTopY + zoneSize.height / 2;
        desiredZoneCenters.add(
          _DesiredCenter(
            id: zone.id,
            preferredCenterY: preferredCenterY,
            height: zoneSize.height,
          ),
        );
        zoneTopY += zoneSize.height + _verticalGroupGap;
      }
    }
    final Map<String, double> resolvedZoneY = _resolveNonOverlappingCenters(
      desiredZoneCenters,
      _verticalGroupGap,
    );
    for (final Zone zone in zones) {
      final double? centerY = resolvedZoneY[zone.id];
      if (centerY == null) {
        continue;
      }
      results.add(
        WiringLayoutResult(
          zone: zone,
          position: Offset(zoneColumnCenterX, centerY),
        ),
      );
    }

    if (unconnectedZones.isNotEmpty) {
      unconnectedZones.sort((Zone a, Zone b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      double fallbackZoneTopY = currentTopY;
      for (final Zone zone in unconnectedZones) {
        final Size zoneSize = sizeById[zone.id] ?? Size.zero;
        final double centerY = fallbackZoneTopY + zoneSize.height / 2;
        results.add(
          WiringLayoutResult(
            zone: zone,
            position: Offset(zoneColumnCenterX, centerY),
          ),
        );
        fallbackZoneTopY += zoneSize.height + _verticalGroupGap;
      }
    }

    return results;
  }

  Map<int, _EquipmentGroup> _buildEquipmentGroups({
    required List<FusionDsp> dsps,
    required List<Amplifier> amplifiers,
    required List<WiringConnectionModel> connections,
    required Map<String, FusionDsp> dspById,
  }) {
    final Map<int, _EquipmentGroup> groups = <int, _EquipmentGroup>{};

    for (final FusionDsp dsp in dsps) {
      final int key = _locationKey(dsp.equipmentLocationPosition);
      final _EquipmentGroup group = groups.putIfAbsent(key, _EquipmentGroup.new);
      group.dsps.add(dsp);
    }

    for (final Amplifier amplifier in amplifiers) {
      int key = _locationKey(amplifier.equipmentLocationPosition);
      if (amplifier.equipmentLocationPosition == null) {
        final String? connectedDspId = _findConnectedDspIdForAmplifier(
          amplifierId: amplifier.id,
          connections: connections,
          dspIds: dspById.keys,
        );
        if (connectedDspId != null) {
          final FusionDsp? connectedDsp = dspById[connectedDspId];
          key = _locationKey(connectedDsp?.equipmentLocationPosition);
        }
      }
      final _EquipmentGroup group = groups.putIfAbsent(key, _EquipmentGroup.new);
      group.amplifiers.add(amplifier);
    }

    for (final _EquipmentGroup group in groups.values) {
      group.dsps.sort((FusionDsp a, FusionDsp b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      group.amplifiers.sort((Amplifier a, Amplifier b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return groups;
  }

  Map<String, _SourceLinkMeta> _buildSourceLinkMeta({
    required List<Source> sources,
    required List<WiringConnectionModel> connections,
    required Map<String, FusionDsp> dspById,
    required List<int> orderedGroupKeys,
  }) {
    final Map<int, int> groupOrderByKey = <int, int>{
      for (int i = 0; i < orderedGroupKeys.length; i++) orderedGroupKeys[i]: i,
    };

    final Map<String, _SourceLinkMeta> metaBySourceId = <String, _SourceLinkMeta>{};

    for (final Source source in sources) {
      String? bestDspId;
      int bestDspPortOrder = 1 << 30;
      int bestSourcePortOrder = 1 << 30;
      int bestGroupOrder = 1 << 30;

      for (final WiringConnectionModel connection in connections) {
        final String? dspId = _counterpartIfConnected(connection, source.id, dspById.keys);
        if (dspId == null) {
          continue;
        }
        final FusionDsp? dsp = dspById[dspId];
        if (dsp == null) {
          continue;
        }

        final String? dspPortId = _portIdForDevice(connection, dspId);
        final int dspPortOrder = _portOrderOnDsp(dsp, dspPortId);
        final String? sourcePortId = _portIdForDevice(connection, source.id);
        final int sourcePortOrder = _portOrderOnSource(source, sourcePortId);
        final int groupOrder = groupOrderByKey[_locationKey(dsp.equipmentLocationPosition)] ?? (1 << 30);

        final bool isBetter =
            dspPortOrder < bestDspPortOrder ||
            (dspPortOrder == bestDspPortOrder && sourcePortOrder < bestSourcePortOrder) ||
            (dspPortOrder == bestDspPortOrder && sourcePortOrder == bestSourcePortOrder && groupOrder < bestGroupOrder) ||
            (dspPortOrder == bestDspPortOrder &&
                sourcePortOrder == bestSourcePortOrder &&
                groupOrder == bestGroupOrder &&
                (bestDspId == null || dspId.compareTo(bestDspId) < 0));

        if (isBetter) {
          bestDspId = dspId;
          bestDspPortOrder = dspPortOrder;
          bestSourcePortOrder = sourcePortOrder;
          bestGroupOrder = groupOrder;
        }
      }

      if (bestDspId == null) {
        metaBySourceId[source.id] = _SourceLinkMeta.unconnected(1 << 30);
      } else {
        final FusionDsp? bestDsp = dspById[bestDspId];
        final int groupKey = _locationKey(bestDsp?.equipmentLocationPosition);
        metaBySourceId[source.id] = _SourceLinkMeta(
          dspId: bestDspId,
          dspPortOrder: bestDspPortOrder,
          sourcePortOrder: bestSourcePortOrder,
          groupOrder: bestGroupOrder,
          groupKey: groupKey,
        );
      }
    }

    return metaBySourceId;
  }

  Map<String, String> _buildCircuitToZoneMap({required List<Zone> zones, required WiringZoneManager zoneManager}) {
    final Map<String, String> circuitToZone = <String, String>{};
    for (final Zone zone in zones) {
      final List<CircuitModel> zoneCircuits = zoneManager.getCircuitsInZone(zone.id);
      for (final CircuitModel circuit in zoneCircuits) {
        circuitToZone[circuit.id] = zone.id;
      }

      final List<SubZone> subZones = zoneManager.getSubZonesForZone(zone.id);
      for (final SubZone subZone in subZones) {
        final List<CircuitModel> subZoneCircuits = zoneManager.getCircuitsInSubZone(subZone.id);
        for (final CircuitModel circuit in subZoneCircuits) {
          circuitToZone[circuit.id] = zone.id;
        }
      }
    }
    return circuitToZone;
  }

  Map<String, _ZoneLinkMeta> _buildZoneLinkMeta({
    required List<WiringConnectionModel> connections,
    required Map<String, Amplifier> amplifierById,
    required Map<String, Zone> zoneById,
    required Map<String, String> circuitToZoneId,
  }) {
    final Map<String, _ZoneLinkMeta> zoneMetaByZoneId = <String, _ZoneLinkMeta>{};

    for (final WiringConnectionModel connection in connections) {
      String? amplifierId;
      String? otherDeviceId;

      if (amplifierById.containsKey(connection.deviceId)) {
        amplifierId = connection.deviceId;
        otherDeviceId = connection.targetDeviceId;
      } else if (amplifierById.containsKey(connection.targetDeviceId)) {
        amplifierId = connection.targetDeviceId;
        otherDeviceId = connection.deviceId;
      } else {
        continue;
      }

      String? zoneId;
      if (zoneById.containsKey(otherDeviceId)) {
        zoneId = otherDeviceId;
      } else {
        zoneId = circuitToZoneId[otherDeviceId];
      }

      if (zoneId == null) {
        continue;
      }

      final Amplifier? amplifier = amplifierById[amplifierId];
      final String? amplifierPortId = _portIdForDevice(connection, amplifierId);
      final int amplifierPortOrder = _portOrderOnAmplifier(amplifier, amplifierPortId);

      final _ZoneLinkMeta previous = zoneMetaByZoneId[zoneId] ?? _ZoneLinkMeta(amplifierId: null, amplifierPortOrder: 1 << 30);
      final bool isBetter =
          previous.amplifierId == null ||
          amplifierPortOrder < previous.amplifierPortOrder ||
          (amplifierPortOrder == previous.amplifierPortOrder && amplifierId.compareTo(previous.amplifierId!) < 0);

      if (isBetter) {
        zoneMetaByZoneId[zoneId] = _ZoneLinkMeta(amplifierId: amplifierId, amplifierPortOrder: amplifierPortOrder);
      }
    }

    return zoneMetaByZoneId;
  }

  static String? _counterpartIfConnected(WiringConnectionModel connection, String deviceId, Iterable<String> counterpartIds) {
    if (connection.deviceId == deviceId && counterpartIds.contains(connection.targetDeviceId)) {
      return connection.targetDeviceId;
    }
    if (connection.targetDeviceId == deviceId && counterpartIds.contains(connection.deviceId)) {
      return connection.deviceId;
    }
    return null;
  }

  static String? _portIdForDevice(WiringConnectionModel connection, String deviceId) {
    if (connection.deviceId == deviceId) {
      return connection.portId;
    }
    if (connection.targetDeviceId == deviceId) {
      return connection.targetPortId;
    }
    return null;
  }

  static int _portOrderOnDsp(FusionDsp dsp, String? portId) {
    if (portId == null) {
      return 1 << 30;
    }
    final PortData? inputPort = dsp.inputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (inputPort != null) {
      return inputPort.portNumber;
    }
    final PortData? outputPort = dsp.outputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (outputPort != null) {
      return outputPort.portNumber + 1000;
    }
    return 1 << 30;
  }

  static int _portOrderOnAmplifier(Amplifier? amplifier, String? portId) {
    if (amplifier == null || portId == null) {
      return 1 << 30;
    }
    final PortData? outputPort = amplifier.outputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (outputPort != null) {
      return outputPort.portNumber;
    }
    final PortData? inputPort = amplifier.inputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (inputPort != null) {
      return inputPort.portNumber + 1000;
    }
    return 1 << 30;
  }

  static int _portOrderOnSource(Source source, String? portId) {
    if (portId == null) {
      return 1 << 30;
    }
    final PortData? outputPort = source.outputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (outputPort != null) {
      return outputPort.portNumber;
    }
    final PortData? inputPort = source.inputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (inputPort != null) {
      return inputPort.portNumber + 1000;
    }
    return 1 << 30;
  }

  static int _portOrderOnHardware(HardwareComponent device, String? portId) {
    if (portId == null) {
      return 1 << 30;
    }
    final PortData? inputPort = device.inputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (inputPort != null) {
      return inputPort.portNumber;
    }
    final PortData? outputPort = device.outputPortsData.firstWhereOrNull((PortData port) => port.id == portId);
    if (outputPort != null) {
      return outputPort.portNumber + 1000;
    }
    final PortData? communicationPort = device.communicationPorts.firstWhereOrNull((PortData port) => port.id == portId);
    if (communicationPort != null) {
      return communicationPort.portNumber + 2000;
    }
    return 1 << 30;
  }

  static int _locationKey(int? equipmentLocationPosition) {
    return equipmentLocationPosition ?? (1 << 30);
  }

  static String? _findConnectedDspIdForAmplifier({
    required String amplifierId,
    required List<WiringConnectionModel> connections,
    required Iterable<String> dspIds,
  }) {
    for (final WiringConnectionModel connection in connections) {
      if (connection.deviceId == amplifierId && dspIds.contains(connection.targetDeviceId)) {
        return connection.targetDeviceId;
      }
      if (connection.targetDeviceId == amplifierId && dspIds.contains(connection.deviceId)) {
        return connection.deviceId;
      }
    }
    return null;
  }

  Map<String, _TopSourceLinkMeta> _buildTopSourceLinkMeta({
    required List<Source> sources,
    required List<WiringConnectionModel> connections,
    required Map<String, HardwareComponent> otherById,
    required Map<String, int> otherOrderById,
  }) {
    final Map<String, _TopSourceLinkMeta> metaBySourceId = <String, _TopSourceLinkMeta>{};

    for (final Source source in sources) {
      _TopSourceLinkMeta? best;
      for (final WiringConnectionModel connection in connections) {
        final String? otherDeviceId = _counterpartIfConnected(connection, source.id, otherById.keys);
        if (otherDeviceId == null) {
          continue;
        }
        final HardwareComponent? otherDevice = otherById[otherDeviceId];
        if (otherDevice == null) {
          continue;
        }
        final int otherOrder = otherOrderById[otherDeviceId] ?? (1 << 30);
        final int sourcePortOrder = _portOrderOnSource(source, _portIdForDevice(connection, source.id));
        final int otherPortOrder = _portOrderOnHardware(otherDevice, _portIdForDevice(connection, otherDeviceId));

        final _TopSourceLinkMeta candidate = _TopSourceLinkMeta(
          otherDeviceId: otherDeviceId,
          otherOrder: otherOrder,
          otherPortOrder: otherPortOrder,
          sourcePortOrder: sourcePortOrder,
        );

        if (best == null || candidate.isHigherPriorityThan(best)) {
          best = candidate;
        }
      }
      if (best != null) {
        metaBySourceId[source.id] = best;
      }
    }

    return metaBySourceId;
  }

  static Map<String, List<int>> _buildSourceConnectionPortRanks({
    required List<Source> sources,
    required List<WiringConnectionModel> connections,
    required Map<String, HardwareComponent> hardwareById,
  }) {
    final Set<String> sourceIds = sources.map((Source source) => source.id).toSet();
    final Map<String, List<int>> ranks = <String, List<int>>{};

    for (final Source source in sources) {
      final List<int> indices = <int>[];
      for (final WiringConnectionModel connection in connections) {
        String? counterpartId;
        String? counterpartPortId;
        if (connection.deviceId == source.id) {
          counterpartId = connection.targetDeviceId;
          counterpartPortId = connection.targetPortId;
        } else if (connection.targetDeviceId == source.id) {
          counterpartId = connection.deviceId;
          counterpartPortId = connection.portId;
        } else {
          continue;
        }

        if (sourceIds.contains(counterpartId)) {
          continue;
        }

        final HardwareComponent? counterpartDevice = hardwareById[counterpartId];
        if (counterpartDevice == null) {
          continue;
        }
        indices.add(_portOrderOnHardware(counterpartDevice, counterpartPortId));
      }

      indices.sort();
      ranks[source.id] = indices.isEmpty ? <int>[1 << 30] : indices;
    }

    return ranks;
  }

  static int _compareOrderedIntLists(List<int> a, List<int> b) {
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; i++) {
      if (a[i] != b[i]) {
        return a[i].compareTo(b[i]);
      }
    }
    return a.length.compareTo(b.length);
  }

  static double _maxWidth(Iterable<Size?> sizes) {
    double maxWidth = 0;
    for (final Size? size in sizes) {
      if (size != null) {
        maxWidth = math.max(maxWidth, size.width);
      }
    }
    return maxWidth;
  }

  static double _maxHeight(Iterable<Size?> sizes) {
    double maxHeight = 0;
    for (final Size? size in sizes) {
      if (size != null) {
        maxHeight = math.max(maxHeight, size.height);
      }
    }
    return maxHeight;
  }

  static double _stackHeight(List<dynamic> items, Map<String, Size> sizeById) {
    if (items.isEmpty) {
      return 0;
    }
    double total = 0;
    for (final dynamic item in items) {
      final String id = item.id as String;
      total += (sizeById[id] ?? Size.zero).height;
    }
    total += (items.length - 1) * _verticalGroupGap;
    return total;
  }

  static Map<String, double> _resolveNonOverlappingCenters(List<_DesiredCenter> desired, double gap) {
    if (desired.isEmpty) {
      return <String, double>{};
    }
    final List<_DesiredCenter> ordered =
        desired.toList()..sort((_DesiredCenter a, _DesiredCenter b) {
          if (a.preferredCenterY != b.preferredCenterY) {
            return a.preferredCenterY.compareTo(b.preferredCenterY);
          }
          return a.id.compareTo(b.id);
        });

    final Map<String, double> resolved = <String, double>{};
    double? previousCenter;
    double? previousHeight;
    for (final _DesiredCenter current in ordered) {
      double center = current.preferredCenterY;
      if (previousCenter != null && previousHeight != null) {
        final double minCenter = previousCenter + previousHeight / 2 + gap + current.height / 2;
        if (center < minCenter) {
          center = minCenter;
        }
      }
      resolved[current.id] = center;
      previousCenter = center;
      previousHeight = current.height;
    }
    return resolved;
  }
}

class _EquipmentGroup {
  final List<FusionDsp> dsps = <FusionDsp>[];
  final List<Amplifier> amplifiers = <Amplifier>[];
}

class _SourceLinkMeta {
  final String? dspId;
  final int dspPortOrder;
  final int sourcePortOrder;
  final int groupOrder;
  final int groupKey;

  _SourceLinkMeta({
    required this.dspId,
    required this.dspPortOrder,
    required this.sourcePortOrder,
    required this.groupOrder,
    required this.groupKey,
  });

  factory _SourceLinkMeta.unconnected(int groupOrder) {
    return _SourceLinkMeta(
      dspId: null,
      dspPortOrder: 1 << 30,
      sourcePortOrder: 1 << 30,
      groupOrder: groupOrder,
      groupKey: _unassignedGroupKey,
    );
  }
}

const int _unassignedGroupKey = 1 << 30;

class _ZoneLinkMeta {
  final String? amplifierId;
  final int amplifierPortOrder;

  _ZoneLinkMeta({required this.amplifierId, required this.amplifierPortOrder});
}

class _DesiredCenter {
  final String id;
  final double preferredCenterY;
  final double height;

  _DesiredCenter({required this.id, required this.preferredCenterY, required this.height});
}

class _TopSourceLinkMeta {
  final String otherDeviceId;
  final int otherOrder;
  final int otherPortOrder;
  final int sourcePortOrder;

  _TopSourceLinkMeta({
    required this.otherDeviceId,
    required this.otherOrder,
    required this.otherPortOrder,
    required this.sourcePortOrder,
  });

  bool isHigherPriorityThan(_TopSourceLinkMeta other) {
    if (otherOrder != other.otherOrder) {
      return otherOrder < other.otherOrder;
    }
    if (otherPortOrder != other.otherPortOrder) {
      return otherPortOrder < other.otherPortOrder;
    }
    return sourcePortOrder < other.sourcePortOrder;
  }
}

class WiringLayoutResult {
  final HardwareComponent? hardwareComponent;
  final CircuitModel? circuit;
  final Zone? zone;
  final Offset position;

  WiringLayoutResult({
    this.hardwareComponent,
    this.circuit,
    this.zone,
    required this.position,
  });
}
