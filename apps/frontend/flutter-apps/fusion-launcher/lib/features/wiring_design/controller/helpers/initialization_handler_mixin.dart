import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_launcher/features/wiring_design/model/wire.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../../dto/component_data.dart';
import '../../dto/factory.dart';
import '../../model/circuit_port.dart';
import '../circuit_controller.dart';
import '../state/wiring_state.dart';

extension InitializationHandlerMixin on CircuitController {
  void loadFromPM() {
    final List<CircuitComponent> circuitComponents = <CircuitComponent>[];
    final List<Wire> wires = <Wire>[];

    void addComponent(CircuitComponent component) {
      for (final CircuitPort port in component.ports) {
        componentDB.addPort(port);
      }
      circuitComponents.add(component);
    }

    void addExistingWire(Wire wire) {
      componentDB.addWire(wire);
      wires.add(wire);
    }

    final List<Zone> zones = projectManager.zones;
    for (int i = 0; i < zones.length; i++) {
      final Zone zone = zones[i];
      final ZoneComponentData componentData = ComponentDataFactory.fromZone(
        zone,
      );
      final CircuitComponent? existingCirComponent = componentDB
          .getCircuitComponent(zone.id);
      final CircuitComponent component =
      // existingCirComponent ??
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
        final SubZoneComponentData subZoneData =
            ComponentDataFactory.fromSubZone(
              subZone,
            );

        final CircuitComponent? existingSubZoneComponent = componentDB
            .getCircuitComponent(subZone.id);
        final CircuitComponent subZoneComponent =
        // existingSubZoneComponent ??
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
          addCircuit(circuit, subZoneComponent, addComponent);
        }
      }

      final List<CircuitModel> circuits = projectManager.getCircuitsInZone(
        zone.id,
      );
      for (final CircuitModel circuit in circuits) {
        addCircuit(circuit, component, addComponent);
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

      final ComponentData componentData = ComponentDataFactory.fromHardware(
        component,
      );
      final CircuitComponent from =
      // componentDB.getCircuitComponent(componentData.id) ??
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
    _initializePositions(circuitComponents);
    setState(
      IdleWiringState(
        canvasState: canvasState,
        components: circuitComponents,
        wires: wires,
      ),
    );
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
    setState(
      IdleWiringState(
        canvasState: canvasState,
        components: circuitComponents,
        wires: wires,
      ),
    );
    cache.cacheForState(state);
    stack.push(state.toMap());
  }

  void addCircuit(
    CircuitModel circuit,
    CircuitComponent subZoneComponent,
    ValueChanged<CircuitComponent> addComponent,
  ) {
    final List<HardwareComponent> hardwareForCircuit = projectManager
        .getHardwareForCircuit(circuitId: circuit.id);
    if (hardwareForCircuit.isEmpty) return;
    final CircuitComponentData cirCom = ComponentDataFactory.fromCircuit(
      circuit,
      hardwareForCircuit,
    );
    final CircuitComponent circuitComponent =
    // componentDB.getCircuitComponent(cirCom.id) ??
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

  void _initializePositions(List<CircuitComponent> components) {
    final double sourceX = -200;
    final double endpointsX = 100.0;
    final double dspX = 600.0;
    final double amplifierX = 1100.0;
    final double speakerX = 1700.0;
    final double controllerX = 2100.0;

    double sourceY = 0.0;
    double endpointsY = 0.0;
    double dspY = 0.0;
    double amplifierY = 0.0;
    double speakerY = 0.0;
    double controllerY = 0.0;

    for (final CircuitComponent component in components) {
      if (component.data is SourceComponentData) {
        component.setPosition(
          (component.data as SourceComponentData).source.wiringPos ??
              Offset(sourceX, sourceY),
        );
        sourceY += component.size.height + 100;
      } else if (component.data is DeviceSchematicComponentData) {
        final HardwareComponent hardware =
            (component.data as DeviceSchematicComponentData).data;
        if (hardware is Amplifier) {
          component.setPosition(
            hardware.wiringPos ?? Offset(amplifierX, amplifierY),
          );
          amplifierY += component.size.height + 100;
        } else if (hardware is FusionEndpoints) {
          component.setPosition(
            hardware.wiringPos ?? Offset(endpointsX, endpointsY),
          );
          endpointsY += component.size.height + 100;
          continue;
        } else if (hardware is FusionDsp) {
          component.setPosition(
            hardware.wiringPos ?? Offset(dspX, dspY),
          );
          dspY += component.size.height + 100;
          continue;
        } else if (hardware is FusionController) {
          component.setPosition(
            hardware.wiringPos ?? Offset(controllerX, controllerY),
          );
          controllerY += component.size.height + 100;
          continue;
        }
      } else if (component.data is SpeakerComponentData) {
        component.setPosition(
          (component.data as SpeakerComponentData).speaker.wiringPos ??
              Offset(speakerX, speakerY),
        );
        speakerY += component.size.height + 100;
      } else if (component.data is ZoneComponentData) {
        component.setPosition(
          (component.data as ZoneComponentData).zone.wiringPos ??
              Offset(speakerX, speakerY),
        );
        speakerY += component.size.height + 100;
      }
    }
  }
}
