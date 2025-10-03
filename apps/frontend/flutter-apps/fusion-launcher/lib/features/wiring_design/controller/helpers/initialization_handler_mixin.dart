import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../circuit_controller.dart';

extension InitializationHandlerMixin on CircuitController {
  void initialize() {
    final List<HardwareComponent> components =
        projectManager.getAllHardwareComponents();

    for (int i = 0; i < components.length; i++) {
      addComponent(
        CircuitComponent.from(
          _getComponent(components[i]),
          i,
        ),
      );
    }
  }

  ComponentData _getComponent(HardwareComponent hardwareComponent) {
    return switch (hardwareComponent) {
      Speaker() => SpeakerComponentData.from(hardwareComponent),
      Source() => SourceComponentData.from(hardwareComponent),
      _ => DeviceSchematicComponentData.from(hardwareComponent),
    };
  }
}
