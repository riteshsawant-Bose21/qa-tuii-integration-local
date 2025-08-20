import 'dart:async';
import 'dart:ui';

import 'mace_engine_provider.dart';
import 'models/hardware_component_entity.dart';
import 'models/listening_area_entity.dart';
import 'models/speaker_entity.dart';

class SPLCalculation {
  final ListeningArea surface;
  final int fphHandle;
  List<double> spl = <double>[];

  SPLCalculation(this.surface, this.fphHandle);
}

class SPLCalculationManager {
  /// 1) clear engine state,
  /// 2) add speakers & surfaces,
  /// 3) create measurement + group,
  /// 4) calculate,
  /// 5) fetch SPLs
  static Future<List<SPLCalculation>> calculateSpl(MaceEngine engine, List<HardwareComponent> speakers, List<ListeningArea> surfaces) async {
    if (speakers.isEmpty || surfaces.isEmpty) {
      return <SPLCalculation>[];
    }

    // reset
    engine.clear();
    final List<SPLCalculation> calculations = <SPLCalculation>[];

    // add speakers
    final List<int> clusterIds = <int>[];
    for (final HardwareComponent sp in speakers) {
      if (sp is! Speaker) continue;
      final int cid = engine.addSpeaker(sp.speakerSKU, sp.pos.dx, sp.pos.dy, sp.rotation, sp.gain);
      clusterIds.add(cid);
    }

    // add each surface and its field points
    for (final ListeningArea cs in surfaces) {
      final List<List<double>> poly3d = cs.vertices.map((Offset o) => <double>[o.dx, o.dy, 0.0]).toList();
      engine.addSurface(poly3d);

      final List<Offset> pts = cs.getFieldPoints();
      final List<List<double>> list3d = pts.map((Offset o) => <double>[o.dx, o.dy, 0.0]).toList();
      final int fph = engine.addFieldPoints(list3d);
      calculations.add(SPLCalculation(cs, fph));
    }

    // measurement + group
    final int measId = engine.createMeasurement(0);
    final int groupId = engine.createGroup();

    // add to group
    for (final SPLCalculation sc in calculations) {
      for (final int cid in clusterIds) {
        engine.addToGroup(groupId, cid, sc.fphHandle);
      }
    }

    // associate and run
    engine.addGroupsToMeasurement(measId, groupId);
    engine.runCalculation();

    // fetch SPLs (matching the same field‐points count)
    for (final SPLCalculation sc in calculations) {
      final List<Offset> pts = sc.surface.getFieldPoints();
      sc.spl = engine.getSpl(sc.fphHandle, 1000, pts.length);
    }

    return calculations;
  }
}
