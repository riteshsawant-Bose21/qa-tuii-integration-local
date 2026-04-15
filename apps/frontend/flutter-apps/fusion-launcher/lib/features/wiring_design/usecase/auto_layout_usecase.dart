// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;
import 'dart:ui';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/wiring_controller_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/wiring_devices_painter.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/connection_manager.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/zone_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_zone_painter.dart';

class WiringAutoLayoutUseCase {
  static const double _horizontalGroupGap = 300;
  static const double _verticalGroupGap = 100;
  static const double _topRowDeviceGap = 120;

  final List<HardwareComponent> devices;
  final List<WiringConnectionModel> connections;
  final List<Zone> zones;
  final WiringZoneManager zoneManager;
  WiringAutoLayoutUseCase({
    required this.devices,
    required this.connections,
    required this.zones,
    required this.zoneManager,
  }) {
    _initialize();
  }

  ///
  ///
  ///
  ///
  void _initialize() {
    connectionManager.syncWithProjectManager(serviceLocator.get<ProjectViewModel>());
    final List<WiringZonePainter> zonePainters =
        zones.map((Zone zone) => WiringZonePainter(zone: zone, zoneManager: zoneManager, connectionManager: connectionManager)).toList();
    final List<WiringSourcePainter> sourcePainters = <WiringSourcePainter>[];
    final List<WiringDevicesPainter> dspPainters = <WiringDevicesPainter>[];
    final List<WiringDevicesPainter> amplifierPainters = <WiringDevicesPainter>[];
    final List<WiringControllerPainter> otherPainters = <WiringControllerPainter>[];

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

    for (final Zone zone in zones) {
      final List<CircuitModel> circuitsInZone = zoneManager.getCircuitsInZone(zone.id);
      circuitsByZoneId[zone.id] = circuitsInZone;
      for (final CircuitModel circuit in circuitsInZone) {
        circuitById[circuit.id] = circuit;
        if (!circuits.contains(circuit)) {
          circuits.add(circuit);
          zoneForCircuitId[circuit.id] = zone;
        }
      }

      final List<SubZone> subZones = zoneManager.getSubZonesForZone(zone.id);
      for (final SubZone subZone in subZones) {
        final List<CircuitModel> circuitsInSubZone = zoneManager.getCircuitsInSubZone(subZone.id);
        for (final CircuitModel circuit in circuitsInSubZone) {
          circuitById[circuit.id] = circuit;
          if (!circuits.contains(circuit)) {
            circuits.add(circuit);
            zoneForCircuitId[circuit.id] = zone;
          }
        }
      }
    }

    sizeById = <String, Size>{
      for (final WiringSourcePainter painter in sourcePainters) painter.source.id: painter.getSize(),
      for (final WiringDevicesPainter painter in dspPainters) painter.device.id: painter.getSize(),
      for (final WiringDevicesPainter painter in amplifierPainters) painter.device.id: painter.getSize(),
      for (final WiringControllerPainter painter in otherPainters) painter.device.id: painter.getSize(),
      for (final WiringZonePainter painter in zonePainters) painter.zone.id: painter.getSize(),
    };
    painterById = <String, PortPainter>{
      for (final WiringSourcePainter painter in sourcePainters) painter.source.id: painter,
      for (final WiringDevicesPainter painter in dspPainters) painter.device.id: painter,
      for (final WiringDevicesPainter painter in amplifierPainters) painter.device.id: painter,
      for (final WiringControllerPainter painter in otherPainters) painter.device.id: painter,
      for (final WiringZonePainter painter in zonePainters) painter.zone.id: painter,
    };
    zoneById = <String, Zone>{
      for (final WiringZonePainter painter in zonePainters) painter.zone.id: painter.zone,
    };

    sources.clear();
    sources.addAll(sourcePainters.map((WiringSourcePainter painter) => painter.source));
    dsps.clear();
    dsps.addAll(dspPainters.map((WiringDevicesPainter painter) => painter.device).whereType<FusionDsp>());
    amplifiers.clear();
    amplifiers.addAll(amplifierPainters.map((WiringDevicesPainter painter) => painter.device).whereType<Amplifier>());
    others.clear();
    others.addAll(otherPainters.map((WiringControllerPainter painter) => painter.device));
    deviceById = <String, HardwareComponent>{
      for (final HardwareComponent device in devices) device.id: device,
    };
  }

  Map<String, HardwareComponent> deviceById = <String, HardwareComponent>{};
  Map<String, CircuitModel> circuitById = <String, CircuitModel>{};
  final List<CircuitModel> circuits = <CircuitModel>[];
  Map<String, Zone> zoneForCircuitId = <String, Zone>{};
  Map<String, List<CircuitModel>> circuitsByZoneId = <String, List<CircuitModel>>{};

  Map<String, Size> sizeById = <String, Size>{};
  final ConnectionManager connectionManager = ConnectionManager();
  Map<String, PortPainter> painterById = <String, PortPainter>{};
  Map<String, Zone> zoneById = <String, Zone>{};

  final List<Source> sources = <Source>[];
  final List<FusionDsp> dsps = <FusionDsp>[];
  final List<Amplifier> amplifiers = <Amplifier>[];
  final List<HardwareComponent> others = <HardwareComponent>[];

  ///
  ///Algorithm:
  ///     1. Find all groups of connected devices to DSPs. Each group will have a DSP as the center, with its connected devices as left and right elements based on input/output.
  ///     2. Place each group on the layout grid, starting from the top-left corner and moving right and down as needed.
  ///     3. For any remaining unplaced devices, attempt to place them near their connected DSP if they have one, otherwise place them in the next available spot on the grid.
  ///
  List<WiringLayoutResult> execute() {
    final List<_PlacementGroup> dspPlacements = <_PlacementGroup>[];

    for (FusionDsp dsp in dsps) {
      dspPlacements.add(_getPlacementGroupForHardwareComponent(dsp, connectionManager));
    }

    final List<Amplifier> unplacedAmplifiers = amplifiers.where((Amplifier amplifier) => !_placedDeviceMap.containsKey(amplifier.id)).toList();
    final List<_PlacementGroup> unplacedAmplifiersGroup = <_PlacementGroup>[];

    for (final Amplifier amplifier in unplacedAmplifiers) {
      unplacedAmplifiersGroup.add(_getPlacementGroupForHardwareComponent(amplifier, connectionManager));
    }

    final List<HardwareComponent> unplacedOthers = others.where((HardwareComponent device) => !_placedDeviceMap.containsKey(device.id)).toList();
    final List<_PlacementGroup> unplacedOthersGroup = <_PlacementGroup>[];

    for (final HardwareComponent device in unplacedOthers) {
      if (device is Speaker || device is HardwareRack) continue;
      unplacedOthersGroup.add(_getPlacementGroupForHardwareComponent(device, connectionManager));
    }

    final List<Source> unplacedSources = sources.where((Source source) => !_placedDeviceMap.containsKey(source.id)).toList();
    final List<_PlacementGroup> unplacedSourcesGroup = <_PlacementGroup>[];

    for (final Source source in unplacedSources) {
      unplacedSourcesGroup.add(_getPlacementGroupForHardwareComponent(source, connectionManager));
    }
    final List<Zone> unplacedZones = zones.where((Zone zone) => !_placedDeviceMap.containsKey(zone.id)).toList();
    final List<_PlacementGroup> unplacedZonesGroup = <_PlacementGroup>[];

    for (final Zone zone in unplacedZones) {
      unplacedZonesGroup.add(_getPlacementGroupForZone(zone, connectionManager));
    }

    final _LayoutGrid layoutGrid = _LayoutGrid();

    Offset currentOffset = Offset.zero;
    for (final _PlacementGroup group in dspPlacements) {
      final Rect rect = _placeGroup(
        centerPosition: currentOffset,
        layoutGrid: layoutGrid,
        element: group,
        sizeById: sizeById,
        painterById: painterById,
      );
      currentOffset = Offset(0, rect.bottom + _topRowDeviceGap);
    }

    for (final _PlacementGroup group in unplacedSourcesGroup) {
      _placeGroup(
        centerPosition: _offsetForUnplacedDevice(
          group: group,
          lastPlacedRectForType: () => layoutGrid.getLastPlacedRectForPainter((PortPainter painter) => painter is WiringSourcePainter),
          offsetFromDSP: (Rect rect) => rect.topLeft - Offset(_horizontalGroupGap + group.size.width, 0),
          offsetFromSameType: (Rect rect) => rect.bottomLeft + const Offset(0, _verticalGroupGap),
          layoutGrid: layoutGrid,
        ),
        layoutGrid: layoutGrid,
        element: group,
        sizeById: sizeById,
        painterById: painterById,
      );
    }
    for (final _PlacementGroup group in unplacedAmplifiersGroup) {
      _placeGroup(
        centerPosition: _offsetForUnplacedDevice(
          group: group,
          lastPlacedRectForType:
              () => layoutGrid.getLastPlacedRectForPainter(
                (PortPainter painter) => painter is WiringDevicesPainter && painter.device is Amplifier,
              ),
          offsetFromDSP: (Rect rect) => rect.topRight + const Offset(_horizontalGroupGap, 0),
          offsetFromSameType: (Rect rect) => rect.bottomLeft + const Offset(0, _verticalGroupGap),
          layoutGrid: layoutGrid,
        ),
        layoutGrid: layoutGrid,
        element: group,
        sizeById: sizeById,
        painterById: painterById,
      );
    }

    for (final _PlacementGroup group in unplacedOthersGroup) {
      _placeGroup(
        centerPosition: _offsetForUnplacedDevice(
          group: group,
          lastPlacedRectForType:
              () => layoutGrid.getLastPlacedRectForPainter(
                (PortPainter painter) => painter is WiringControllerPainter && (painter.device is FusionController || painter.device is FusionEndpoints),
              ),
          offsetFromDSP: (Rect rect) => Offset(-500, -group.size.height - _verticalGroupGap * 2),
          offsetFromSameType: (Rect rect) {
            final Offset offset = rect.topRight + const Offset(_horizontalGroupGap / 2, 0);
            return layoutGrid.getNextAvilablePosHorizontally(
              Rect.fromLTWH(offset.dx, offset.dy, group.size.width, group.size.height),
            );
          },

          layoutGrid: layoutGrid,
        ),
        layoutGrid: layoutGrid,
        element: group,
        sizeById: sizeById,
        painterById: painterById,
      );
    }
    for (final _PlacementGroup group in unplacedZonesGroup) {
      _placeGroup(
        centerPosition: _offsetForUnplacedDevice(
          group: group,
          lastPlacedRectForType: () {
            final Rect? lastPlacedRectForPainter = layoutGrid.getLastPlacedRectForPainter(
              (PortPainter painter) => painter is WiringZonePainter,
            );
            if (lastPlacedRectForPainter != null) {
              return lastPlacedRectForPainter;
            }
            final Rect? amplifierRect = layoutGrid.getFirstPlacedRectForPainter(
              (PortPainter painter) => painter is WiringDevicesPainter && painter.device is Amplifier,
            );
            if (amplifierRect != null) {
              return Rect.fromLTWH(amplifierRect.right + _horizontalGroupGap, amplifierRect.top - group.size.height, amplifierRect.width, amplifierRect.height);
            }
            return null;
          },
          offsetFromDSP: (Rect rect) => rect.topRight + const Offset(_horizontalGroupGap, 0),
          offsetFromSameType: (Rect rect) => rect.bottomLeft + const Offset(0, _verticalGroupGap),

          layoutGrid: layoutGrid,
        ),
        layoutGrid: layoutGrid,
        element: group,
        sizeById: sizeById,
        painterById: painterById,
      );
    }

    final List<WiringLayoutResult> placements = layoutGrid.getPlacements(
      deviceById: deviceById,
      circuitById: circuitById,
      painterById: painterById,
      zoneForCircuitId: zoneForCircuitId,
      zoneById: zoneById,
    );

    return placements;
  }

  Offset _offsetForUnplacedDevice({
    required _PlacementGroup group,
    required Rect? Function() lastPlacedRectForType,

    required Offset Function(Rect rect) offsetFromDSP,
    required Offset Function(Rect rect) offsetFromSameType,
    required _LayoutGrid layoutGrid,
  }) {
    final Rect? lastDeviceRect = lastPlacedRectForType();
    if (lastDeviceRect != null) {
      return offsetFromSameType(lastDeviceRect);
    }
    final Rect? dspRect = layoutGrid.getFirstPlacedRectForPainter((PortPainter painter) => painter is WiringDevicesPainter && painter.device is FusionDsp);
    if (dspRect != null) {
      return offsetFromDSP(dspRect);
    }
    return offsetFromDSP(const Rect.fromLTWH(0, 0, 0, 0));
  }

  Rect _placeGroup({
    required Offset centerPosition,
    required _LayoutGrid layoutGrid,
    required _PlacingElement element,
    required Map<String, Size> sizeById,
    required Map<String, PortPainter> painterById,
  }) {
    if (element is _PlacementElement) {
      final Size elementSize = sizeById[element.id] ?? Size.zero;
      final PortPainter? elementPainter = painterById[element.id];
      if (elementPainter == null) return Rect.zero;
      final Rect elementRect = Rect.fromLTWH(centerPosition.dx, centerPosition.dy, elementSize.width, elementSize.height);
      layoutGrid.addPlacement(elementRect, elementPainter);
      return elementRect;
    } else if (element is _PlacementGroup) {
      Rect fullRect = Rect.zero;
      final Offset actialCenter = layoutGrid.getNextAvilablePosVertically(
        Rect.fromLTWH(centerPosition.dx, centerPosition.dy, element.size.width, element.size.height),
      );
      print("Placing element ${element.center.id} at $centerPosition.  Actual center: $actialCenter");

      final Rect centerRect = _placeGroup(
        centerPosition: actialCenter,
        layoutGrid: layoutGrid,
        element: element.center,
        sizeById: sizeById,
        painterById: painterById,
      );
      fullRect = centerRect;

      final double leftGroupX = centerRect.left - _horizontalGroupGap - 500;
      double leftGroupY = centerRect.top;
      for (final _PlacingElement leftElement in element.leftElements) {
        final Rect leftRect = _placeGroup(
          centerPosition: Offset(leftGroupX, leftGroupY),
          layoutGrid: layoutGrid,
          element: leftElement,
          sizeById: sizeById,
          painterById: painterById,
        );
        leftGroupY = leftRect.bottom + _verticalGroupGap;
        fullRect = fullRect.expandToInclude(leftRect);
      }
      final double rightGroupX = centerRect.right + _horizontalGroupGap;
      double rightGroupY = centerRect.top;
      for (final _PlacingElement rightElement in element.rightElements) {
        final Rect rightRect = _placeGroup(
          centerPosition: Offset(rightGroupX, rightGroupY),
          layoutGrid: layoutGrid,
          element: rightElement,
          sizeById: sizeById,
          painterById: painterById,
        );
        rightGroupY = rightRect.bottom + _verticalGroupGap;
        fullRect = fullRect.expandToInclude(rightRect);
      }
      return fullRect;
    }
    return Rect.zero;
  }

  _PlacementGroup _getPlacementGroupForZone(Zone zone, ConnectionManager connectionManager) {
    final List<CircuitModel> circuitsInZone = circuitsByZoneId[zone.id] ?? <CircuitModel>[];
    final List<_PlacingElement> leftElements = _constructGroup(
      _inputConnectedDevices(circuitsInZone.map((CircuitModel e) => e.inputPort).toList(), connectionManager),
      connectionManager,
    );

    return _PlacementGroup(
      center: _PlacementElement(id: zone.id, size: sizeById[zone.id] ?? const Size(100, 100)),
      leftElements: leftElements,
      rightElements: <_PlacingElement>[],
      bottomElements: <_PlacingElement>[],
    );
  }

  _PlacementGroup _getPlacementGroupForHardwareComponent(HardwareComponent component, ConnectionManager connectionManager) {
    _placedDeviceMap[component.id] = true;
    final List<_PlacingElement> leftElements = _constructGroup(_inputConnectedDevices(component.inputPortsData, connectionManager), connectionManager);
    final List<_PlacingElement> rightElements = _constructGroup(_inputConnectedDevices(component.outputPortsData, connectionManager), connectionManager);
    final List<_PlacingElement> bottomElements = _constructGroup(_inputConnectedDevices(component.communicationPorts, connectionManager), connectionManager);

    return _PlacementGroup(
      center: _PlacementElement(id: component.id, size: sizeById[component.id] ?? const Size(100, 100)),
      leftElements: leftElements,
      rightElements: rightElements,
      bottomElements: bottomElements,
    );
  }

  List<_PlacingElement> _constructGroup(List<_PlacementElement> inputGroups, ConnectionManager connectionManager) {
    final List<_PlacingElement> leftElements = <_PlacingElement>[];
    for (final _PlacementElement element in inputGroups) {
      final HardwareComponent? hardware = deviceById[element.id];

      if (hardware != null) {
        final _PlacementGroup elementGroup = _getPlacementGroupForHardwareComponent(hardware, connectionManager);
        if (elementGroup.leftElements.isEmpty && elementGroup.rightElements.isEmpty && elementGroup.bottomElements.isEmpty) {
          leftElements.add(elementGroup.center);
        } else {
          leftElements.add(elementGroup);
        }
        continue;
      }
      final CircuitModel? circuit = circuitById[element.id];
      if (circuit != null) {
        final Zone? zone = zoneForCircuitId[circuit.id];
        if (zone != null) {
          if (_placedDeviceMap[zone.id] == true) {
            continue;
          }
          _placedDeviceMap[zone.id] = true;
          leftElements.add(_PlacementElement(id: zone.id, size: sizeById[zone.id] ?? const Size(100, 100)));
          continue;
        }
      }
      _placedDeviceMap[element.id] = true;
      leftElements.add(element);
    }
    return leftElements;
  }

  final Map<String, bool> _placedDeviceMap = <String, bool>{};

  ///
  ///
  /// Returns all the connected Unplaced devices to given port.
  ///
  ///
  List<_PlacementElement> _inputConnectedDevices(List<PortData> ports, ConnectionManager connectionManager) {
    final List<_PlacementElement> elements = <_PlacementElement>[];
    double yPos = 0;
    for (final PortData port in ports) {
      final WiringConnectionModel? connection = connectionManager.getConnectionForPort(port.id);

      if (connection == null) continue;
      final String otherDeviceId = connection.portId == port.id ? connection.targetDeviceId : connection.deviceId;

      ///
      /// If Already Placed, then Skip the device.
      ///
      if (_placedDeviceMap[otherDeviceId] == true) {
        continue;
      }

      _placedDeviceMap[otherDeviceId] = true;
      final _PlacementElement element = _PlacementElement(id: otherDeviceId, size: sizeById[otherDeviceId] ?? const Size(100, 100));
      yPos++;

      if (!elements.any((_PlacementElement element) => element.id == otherDeviceId)) {
        elements.add(element);
      }
    }

    return elements;
  }

  ///
  ///
  ///
  ///

  List<WiringLayoutResult> placeTheseDevices({
    required List<HardwareComponent> newDevices,
    required List<Zone> newZones,
  }) {
    final _LayoutGrid grid = _LayoutGrid();

    for (final HardwareComponent device in devices) {
      _placedDeviceMap[device.id] = true;
      final PortPainter? painter = painterById[device.id];
      if (painter == null) continue;
      final Size size = sizeById[device.id] ?? const Size(100, 100);
      final Offset? offset = device.wiringPos;
      if (offset == null) continue;
      final Rect rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
      grid.addPlacement(rect, painter);
    }

    for (final Zone zone in zones) {
      _placedDeviceMap[zone.id] = true;

      final PortPainter? painter = painterById[zone.id];
      if (painter == null) continue;
      final Size size = sizeById[zone.id] ?? const Size(100, 100);
      final Offset? offset = zone.wiringPos;
      if (offset == null) continue;
      final Rect rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
      grid.addPlacement(rect, painter);
    }
    final List<String> newIds = <String>[];
    for (final HardwareComponent device in newDevices) {
      newIds.add(device.id);
      final _PlacementGroup group = _getPlacementGroupForHardwareComponent(device, connectionManager);

      _placeGroup(centerPosition: getOffsetForNewDevice(grid, group), layoutGrid: grid, element: group, sizeById: sizeById, painterById: painterById);
    }
    for (final Zone zone in newZones) {
      newIds.add(zone.id);
      final _PlacementGroup group = _getPlacementGroupForZone(zone, connectionManager);
      _placeGroup(centerPosition: getOffsetForNewDevice(grid, group), layoutGrid: grid, element: group, sizeById: sizeById, painterById: painterById);
    }

    return grid
        .getPlacements(
          deviceById: deviceById,
          circuitById: circuitById,
          painterById: painterById,
          zoneForCircuitId: zoneForCircuitId,
          zoneById: zoneById,
        )
        .where((WiringLayoutResult result) => (newIds.contains(result.hardwareComponent?.id)) || (newIds.contains(result.zone?.id)))
        .toList();
  }

  bool Function(PortPainter) _buildTypeCheckFor(dynamic device) {
    if (device is Source) {
      return (PortPainter painter) => painter is WiringSourcePainter;
    } else if (device is Amplifier) {
      return (PortPainter painter) => painter is WiringDevicesPainter && painter.device is Amplifier;
    } else if (device is FusionDsp) {
      return (PortPainter painter) => painter is WiringDevicesPainter && painter.device is FusionDsp;
    } else if (device is Zone) {
      return (PortPainter painter) => painter is WiringZonePainter;
    } else if (device is FusionController || device is FusionEndpoints) {
      return (PortPainter painter) => painter is WiringControllerPainter && (painter.device is FusionController || painter.device is FusionEndpoints);
    }
    return (PortPainter painter) => painter is WiringControllerPainter && (painter.device is FusionController || painter.device is FusionEndpoints);
  }

  Offset _getOffsetFromDSP(Rect rect, dynamic device, _LayoutGrid layoutGrid) {
    if (device is Source) {
      return rect.topLeft - Offset(_horizontalGroupGap + (sizeById[device.id]?.width ?? 100), 0);
    } else if (device is Amplifier) {
      return rect.topRight + const Offset(_horizontalGroupGap, 0);
    } else if (device is Zone) {
      return rect.topRight + const Offset(_horizontalGroupGap, 0);
    } else if (device is FusionController || device is FusionEndpoints) {
      return layoutGrid.getNextAvilablePosVertically(Rect.fromLTWH(rect.left, -500, sizeById[device.id]?.width ?? 100, sizeById[device.id]?.height ?? 100));
    } else if (device is FusionDsp) {
      return rect.bottomLeft + const Offset(0, _verticalGroupGap);
    }
    return rect.topRight + const Offset(_horizontalGroupGap, 0);
  }

  Offset getOffsetForNewDevice(_LayoutGrid layoutGrid, _PlacementGroup group) {
    return _offsetForUnplacedDevice(
      group: group,
      lastPlacedRectForType: () {
        final HardwareComponent? device = deviceById[group.center.id];
        if (device != null) {
          return layoutGrid.getLastPlacedRectForPainter(_buildTypeCheckFor(device));
        }
        final Zone? zone = zoneById[group.center.id];
        if (zone != null) {
          final Rect? lastPlacedRectForPainter = layoutGrid.getLastPlacedRectForPainter(
            (PortPainter painter) => painter is WiringZonePainter,
          );
          if (lastPlacedRectForPainter != null) {
            return lastPlacedRectForPainter;
          }
          final Rect? amplifierRect = layoutGrid.getFirstPlacedRectForPainter(
            (PortPainter painter) => painter is WiringDevicesPainter && painter.device is Amplifier,
          );
          if (amplifierRect != null) {
            return Rect.fromLTWH(amplifierRect.right + _horizontalGroupGap, amplifierRect.top - group.size.height, amplifierRect.width, amplifierRect.height);
          }
        }
        return layoutGrid.getLastPlacedRectForPainter(_buildTypeCheckFor(deviceById[group.center.id]));
      },
      offsetFromDSP: (Rect rect) => _getOffsetFromDSP(rect, deviceById[group.center.id] ?? zoneById[group.center.id], layoutGrid),
      offsetFromSameType: (Rect rect) {
        final HardwareComponent? device = deviceById[group.center.id];
        if (device is FusionEndpoints || device is FusionController) {
          final Offset offset = rect.topRight + const Offset(_horizontalGroupGap / 2, 0);
          return layoutGrid.getNextAvilablePosHorizontally(
            Rect.fromCenter(center: offset, width: group.size.width, height: group.size.height),
          );
        }
        return rect.bottomLeft + const Offset(0, _verticalGroupGap);
      },
      layoutGrid: layoutGrid,
    );
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

abstract class _PlacingElement {
  Size get size;
}

class _PlacementElement extends _PlacingElement {
  final String id;
  @override
  final Size size;
  _PlacementElement({
    required this.id,
    required this.size,
  });
}

class _PlacementGroup extends _PlacingElement {
  final _PlacementElement center;
  final List<_PlacingElement> leftElements;
  final List<_PlacingElement> rightElements;
  final List<_PlacingElement> bottomElements;

  @override
  Size get size {
    double width = center.size.width;
    double height = center.size.height;

    for (final _PlacingElement element in leftElements) {
      width += element.size.width + WiringAutoLayoutUseCase._horizontalGroupGap;
      height = math.max(height, element.size.height);
    }
    for (final _PlacingElement element in rightElements) {
      width += element.size.width + WiringAutoLayoutUseCase._horizontalGroupGap;
      height = math.max(height, element.size.height);
    }
    for (final _PlacingElement element in bottomElements) {
      height += element.size.height + WiringAutoLayoutUseCase._verticalGroupGap;
      width = math.max(width, element.size.width);
    }

    return Size(width, height);
  }

  _PlacementGroup({
    required this.center,
    required this.leftElements,
    required this.rightElements,
    required this.bottomElements,
  });
}

class _LayoutGrid {
  Map<PortPainter, Rect> placements = <PortPainter, Rect>{};

  void addPlacement(Rect rect, PortPainter painter) {
    placements[painter] = rect;
  }

  Offset getNextAvilablePosVertically(Rect rect, {double gap = 50}) {
    final double x = rect.left;
    double y = rect.top;
    while (placements.values.any((Rect r) => r.overlaps(Rect.fromLTWH(x, y, rect.width, rect.height)))) {
      y += gap;
    }
    return Offset(x, y);
  }

  Offset getNextAvilablePosHorizontally(Rect rect) {
    double x = rect.right + 50;
    final double y = rect.top;
    while (placements.values.any((Rect r) => r.overlaps(Rect.fromCenter(center: Offset(x, y), width: rect.width, height: rect.height)))) {
      x += 50;
    }
    return Offset(x, y);
  }

  Rect? getLastPlacedRectForPainter(bool Function(PortPainter painter) typeCheck) {
    final List<Rect> rects =
        placements.entries.where((MapEntry<PortPainter, Rect> entry) => typeCheck(entry.key)).map((MapEntry<PortPainter, Rect> entry) => entry.value).toList();
    if (rects.isEmpty) return null;
    rects.sort((Rect a, Rect b) => a.top.compareTo(b.top));
    return rects.last;
  }

  Rect? getFirstPlacedRectForPainter(bool Function(PortPainter painter) typeCheck) {
    final List<Rect> rects =
        placements.entries.where((MapEntry<PortPainter, Rect> entry) => typeCheck(entry.key)).map((MapEntry<PortPainter, Rect> entry) => entry.value).toList();
    if (rects.isEmpty) return null;
    rects.sort((Rect a, Rect b) => a.top.compareTo(b.top));
    return rects.first;
  }

  List<WiringLayoutResult> getPlacements({
    required Map<String, HardwareComponent> deviceById,
    required Map<String, CircuitModel> circuitById,
    required Map<String, PortPainter> painterById,
    required Map<String, Zone> zoneById,
    required Map<String, Zone> zoneForCircuitId,
  }) {
    final List<WiringLayoutResult> results = <WiringLayoutResult>[];
    placements.forEach((PortPainter painter, Rect rect) {
      final String id = painter.id ?? "";
      final HardwareComponent? device = deviceById[id];
      final CircuitModel? circuit = circuitById[id];
      final Zone? zone = zoneById[id];
      if (device != null) {
        results.add(WiringLayoutResult(hardwareComponent: device, position: rect.topLeft));
      } else if (circuit != null) {
        final Zone? zone = zoneForCircuitId[circuit.id];
        results.add(WiringLayoutResult(circuit: circuit, zone: zone, position: rect.topLeft));
      } else if (zone != null) {
        results.add(WiringLayoutResult(zone: zone, position: rect.topLeft));
      }
    });
    return results;
  }
}
