import 'dart:developer';
import 'dart:ui';

import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_launcher/features/wiring_design/model/wire.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/component_data.dart';
import '../../dto/factory.dart';
import '../../model/circuit_port.dart';
import '../circuit_controller.dart';

extension InitializationHandlerMixin on CircuitController {
  void loadFromPM() {
    final List<Zone> zones = projectManager.zones;
    for (int i = 0; i < zones.length; i++) {
      final Zone zone = zones[i];
      final ComponentData? existingcomData = componentDB.getComponentData(
        zone.id,
      );
      final ZoneComponentData componentData =
          existingcomData is ZoneComponentData
              ? existingcomData
              : ComponentDataFactory.fromZone(
                zone,
              );
      final CircuitComponent? existingCirComponent = componentDB
          .getCircuitComponent(zone.id);
      final CircuitComponent component =
          existingCirComponent ??
          CircuitComponent.from(
            componentData,
            null,
          );

      componentDB.addComponent(component);
      componentDB.addComponentData(componentData);
      addComponent(component);

      final List<SubZone> subZones = projectManager.getSubZonesForZone(
        parentZoneId: zone.id,
      );
      for (final SubZone subZone in subZones) {
        final ComponentData? subZoneComData = componentDB.getComponentData(
          subZone.id,
        );
        final SubZoneComponentData subZoneData =
            subZoneComData is SubZoneComponentData
                ? subZoneComData
                : ComponentDataFactory.fromSubZone(
                  subZone,
                );

        final CircuitComponent? existingSubZoneComponent = componentDB
            .getCircuitComponent(subZone.id);
        final CircuitComponent subZoneComponent =
            existingSubZoneComponent ??
            CircuitComponent.from(
              subZoneData,
              component,
            );

        componentDB.addComponent(subZoneComponent);
        componentDB.addComponentData(subZoneData);

        subZoneComponent.setParent(component);

        addComponent(
          subZoneComponent,
        );

        final List<CircuitModel> circuits = projectManager.getCircuitsInSubZone(
          subZoneId: subZone.id,
        );
        for (final CircuitModel circuit in circuits) {
          addCircuit(
            circuit,
            subZoneComponent,
          );
        }
      }

      final List<CircuitModel> circuits = projectManager.getCircuitsInZone(
        zone.id,
      );
      for (final CircuitModel circuit in circuits) {
        addCircuit(
          circuit,
          component,
        );
      }
    }

    final List<HardwareComponent> components =
        projectManager.hardwareComponents;

    for (int i = 0; i < components.length; i++) {
      final HardwareComponent component = components[i];
      CircuitComponent? parent;
      if (component is Speaker || component is HardwareRack) {
        continue;
      }

      final ComponentData componentData =
          componentDB.getComponentData(component.id) ??
          ComponentDataFactory.fromHardware(
            component,
          );
      final CircuitComponent from =
          componentDB.getCircuitComponent(componentData.id) ??
          CircuitComponent.from(
            componentData,
            parent,
          );

      componentDB.addComponent(from);
      componentDB.addComponentData(componentData);

      addComponent(
        from,
      );
    }
    _initializePositions();

    final List<WiringConnectionModel> connections =
        projectManager.getAllWiringConnections();
    log("Connections to be initialized: ${connections.length}");
    for (final WiringConnectionModel connection in connections) {
      log("Connection initializing: ${connection.toJson()}");
      final CircuitPort? fromPort = componentDB.getPort(connection.portId);
      final CircuitPort? toPort = componentDB.getPort(connection.targetPortId);
      log(" From Port: $fromPort , To Port: $toPort ");
      if (fromPort != null && toPort != null) {
        addExistingWire(
          Wire(
            id: connection.id,
            from: fromPort,
            to: toPort,
            joints: pathFinder.findPath(
              fromPort.absolutePositionWithOffset,
              toPort.absolutePositionWithOffset,
            ),
          ),
        );
      }
    }
  }

  void addCircuit(CircuitModel circuit, CircuitComponent subZoneComponent) {
    final List<HardwareComponent> hardwareForCircuit = projectManager
        .getHardwareForCircuit(circuitId: circuit.id);
    final ComponentData? cirComData = componentDB.getComponentData(circuit.id);
    final CircuitComponentData cirCom =
        cirComData is CircuitComponentData
            ? cirComData
            : ComponentDataFactory.fromCircuit(
              circuit,
              hardwareForCircuit,
            );
    final CircuitComponent circuitComponent =
        componentDB.getCircuitComponent(cirCom.id) ??
        CircuitComponent.from(
          cirCom,
          subZoneComponent,
        );
    componentDB.addComponent(circuitComponent);
    componentDB.addComponentData(cirCom);
    circuitComponent.setParent(subZoneComponent);

    addComponent(
      circuitComponent,
    );
  }

  void _initializePositions() {
    final double sourceX = -200;
    final double amplifierX = 100.0;
    final double speakerX = 700.0;
    final double controllerX = 450.0;
    final double accessoriesX = 600.0;

    double sourceY = 0.0;
    double amplifierY = 0.0;
    double speakerY = 0.0;
    final double controllerY = 0.0;
    final double accessoriesY = 0.0;

    for (final CircuitComponent component in state.components) {
      if (component.data is SourceComponentData) {
        component.changePosition(
          (component.data as SourceComponentData).source.wiringPos ??
              Offset(sourceX, sourceY),
        );
        sourceY += component.size.height + 100;
      } else if (component.data is DeviceSchematicComponentData) {
        final HardwareComponent hardware =
            (component.data as DeviceSchematicComponentData).data;
        // if (hardware is Amplifier) {
        log("Hardware Wiring Pos: ${hardware.wiringPos}");
        component.changePosition(
          hardware.wiringPos ?? Offset(amplifierX, amplifierY),
        );
        amplifierY += component.size.height + 100;

        // } else if(hardware is Fusion){
        //   component.changePosition(Offset(controllerX, controllerY));
        //   continue;
        // } else if(hardware is Accessory){
        //   component.changePosition(Offset(accessoriesX, accessoriesY));
        //   continue;
        // }
      } else if (component.data is SpeakerComponentData) {
        component.changePosition(
          (component.data as SpeakerComponentData).speaker.wiringPos ??
              Offset(speakerX, speakerY),
        );
        speakerY += component.size.height + 100;
      } else if (component.data is ZoneComponentData) {
        component.changePosition(
          (component.data as ZoneComponentData).zone.wiringPos ??
              Offset(speakerX, speakerY),
        );
        speakerY += component.size.height + 100;
      }
    }
  }
}
