import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:fusion_lib/fusion_lib.dart';

import 'ffi_constants.dart';
import 'mace_engine_provider.dart';

class SPLCalculation {
  final ListeningArea surface;
  final int fphHandle;
  List<double> spl = <double>[];

  SPLCalculation(this.surface, this.fphHandle);
}

class SPLCalculationManager {
  // Cache the calculations by FieldPoints handle to avoid re-running or losing surface context.
  static final Map<int, SPLCalculation> _calcByFph = <int, SPLCalculation>{};

  /// 1) clear engine state,
  /// 2) add speakers & surfaces,
  /// 3) create measurement + group,
  /// 4) calculate,
  /// 5) fetch SPLs
  static Future<void> calculateSpl(
    MaceEngine engine,
    List<HardwareComponent> speakers,
    List<ListeningArea> surfaces,
    double resolutionSpacing,
  ) async {
    if (speakers.isEmpty || surfaces.isEmpty) {
      return;
    }

    // reset
    engine.clear();
    final List<SPLCalculation> calculations = <SPLCalculation>[];
    _calcByFph.clear();

    // add speakers
    final List<int> clusterIds = <int>[];
    for (final HardwareComponent sp in speakers) {
      if (sp is! Speaker) continue;
      final int cid = engine.addSpeaker(
        sp.speakerSKU,
        sp.pos.dx,
        sp.pos.dy,
        sp.zAxis,
        sp.gain,
        (sp.roll) * (pi / 180),
        (sp.pitch) * (pi / 180),
        (sp.yaw) * (pi / 180),
      );
      clusterIds.add(cid);
    }

    // add each surface and its field points
    for (final ListeningArea cs in surfaces) {
      final List<List<double>> poly3d =
          cs.vertices.map((Offset o) => <double>[o.dx, o.dy, 0.0]).toList();
      engine.addSurface(poly3d);

      final List<Offset> pts = cs.getFieldPoints(resolutionSpacing);
      final List<List<double>> list3d =
          pts.map((Offset o) => <double>[o.dx, o.dy, 0.0]).toList();
      final int fph = engine.addFieldPoints(list3d);

      final SPLCalculation sc = SPLCalculation(cs, fph);
      calculations.add(sc);
      _calcByFph[fph] = sc; // cache for later lookups
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

    return;
  }

  static Iterable<SPLCalculation> currentCalculations() => _calcByFph.values;

  static List<SPLCalculation> getSplAt(
    MaceEngine engine,
    int fph,
    Bandwidth bandwidth,
    double freqHz,
    Weighting weighting,
    bool relative,
    double resolutionSpacing,
  ) {
    final SPLCalculation? sc = _calcByFph[fph];
    if (sc == null) {
      throw StateError(
        'Unknown FieldPoints handle $fph. Run calculateSpl(...) first.',
      );
    }

    // Map Bandwidth enum to int as expected by FFI
    int bwInt;
    switch (bandwidth) {
      case Bandwidth.allBands:
        bwInt = -1;
        break;
      case Bandwidth.oneOctave:
        bwInt = 1;
        break;
      case Bandwidth.oneThirdOctave:
        bwInt = 3;
        break;
      case Bandwidth.vocalBands:
        bwInt = -2;
        break;
    }

    String weightingStr;
    switch (weighting) {
      case Weighting.a:
        weightingStr = 'A';
        break;
      case Weighting.c:
        weightingStr = 'C';
        break;
      case Weighting.z:
        weightingStr = 'Z';
        break;
    }

    // Call the FFI method to get SPL data
    final List<Offset> pts = sc.surface.getFieldPoints(resolutionSpacing);
    final List<double> splData = engine.getSplAt(
      fph,
      bwInt,
      freqHz,
      pts.length,
      weightingStr,
    );

    if (relative) {
      final List<double> relData = _getRelativeSpls(splData);
      for (int i = 0; i < relData.length; i++) {
        splData[i] = relData[i];
      }
    }

    debugPrint(
      'SPL Data for FPH $fph at ${freqHz}Hz (${bandwidth.toString().split('.').last}), total points ${splData.length}',
    );

    // Update the SPLCalculation with the new data
    sc.spl = splData;

    return <SPLCalculation>[sc];
  }

  static List<double> _getRelativeSpls(List<double> spls) {
    if (spls.isEmpty) return const <double>[];

    // Energy-average: Lavg = 10 * log10( mean(10^(Li/10)) )
    double sumLin = 0.0;
    int n = 0;
    for (final double v in spls) {
      if (v.isFinite) {
        sumLin += math.pow(10.0, v / 10.0) as double;
        n++;
      }
    }
    if (n == 0) return List<double>.filled(spls.length, 0.0);

    final double avgDb = 10.0 * math.log(sumLin / n) / math.ln10;

    const double window = 6.0;
    final double lo = avgDb - window;
    final double hi = avgDb + window;

    // Clamp each SPL to [avg-6, avg+6]
    return List<double>.generate(spls.length, (int i) {
      final double v = spls[i];
      final double x = v.isFinite ? v : avgDb; // treat non-finite as avg
      return x.clamp(lo, hi);
    });
  }
}
