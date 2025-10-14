import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

import 'canvas_element.dart';
import 'circuit_port.dart';

class Wire extends CanvasElement {
  @override
  final String id;
  final CircuitPort from;
  final CircuitPort to;
  final List<Offset> joints; // includes start and end

  Wire({
    required this.id,
    required this.from,
    required this.to,
    required this.joints,
  });

  void setPath(List<Offset> path) {
    joints.clear();
    joints.addAll(path);
  }

  @override
  Offset get position => Offset(
    from.absolutePositionWithOffset.dx,
    to.absolutePositionWithOffset.dy,
  );

  @override
  Size get size => Size(
    (to.absolutePositionWithOffset.dx - from.absolutePositionWithOffset.dx)
        .abs(),
    (to.absolutePositionWithOffset.dy - from.absolutePositionWithOffset.dy)
        .abs(),
  );

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "id": id,
      "from": from.id,
      "to": to.id,
      'joints':
          joints
              .map((Offset e) => <String, double>{"x": e.dx, "y": e.dy})
              .toList(),
    };
  }

  @override
  void restoreFromMap(Map<dynamic, dynamic> map) {
    final List<Offset>? path =
        WiringSerializationUtil.listDeserializer
            .deserialize(map['joints'])
            ?.map(
              (dynamic e) =>
                  WiringSerializationUtil.offsetDeserializer.deserialize(e),
            )
            .where((Offset? e) => e != null)
            .map((Offset? e) => e!)
            .toList();
    if (path != null && path.isNotEmpty) {
      setPath(path);
    }
  }
}
