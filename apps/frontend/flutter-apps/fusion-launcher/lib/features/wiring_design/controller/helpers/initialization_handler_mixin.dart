import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/model/model.dart';

import '../circuit_controller.dart';

extension InitializationHandlerMixin on CircuitController {
  void initialize() {
    for (int i = 0; i < 2; i++) {
      final DspComponent component = DspComponent(
        id: "Comp_$i",
        position: Offset(50 + (i * 120), 200),
      );

      addComponent(component);
    }
  }
}

class DspComponent extends CircuitComponent {
  DspComponent({required super.id, required super.position})
    : super(size: const Size(100, 100), ports: <CircuitPort>[]) {
    /// Input Ports
    ports.addAll(
      List<CircuitPort>.generate(
        4,
        (int index) => CircuitPort(
          id: '${id}_${index}_input',
          parent: this,
          relativePosition: Offset(size.width, size.height / 5 * (index + 1)),
          padding: Offset(10 * (index + 1) + 5, 0),
        ),
      ),
    );

    /// Output Ports
    ports.addAll(
      List<CircuitPort>.generate(
        4,
        (int index) => CircuitPort(
          id: '${id}_${index}_output',
          parent: this,
          relativePosition: Offset(0, size.height / 5 * (index + 1)),
          padding: Offset(-10 * (index + 1) - 5, 0),
        ),
      ),
    );
  }
}
