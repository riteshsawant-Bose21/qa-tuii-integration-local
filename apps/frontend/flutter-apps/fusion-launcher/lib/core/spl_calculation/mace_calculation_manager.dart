import 'dart:async';
import 'dart:ui';

import 'package:fusion_lib/models/fusion_models.dart';

import 'ffi_mace.dart' show Bandwidth;
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
  static Future<List<SPLCalculation>> calculateSpl(
    MaceEngine engine,
    List<HardwareComponent> speakers,
    List<ListeningArea> surfaces,
  ) async {
    if (speakers.isEmpty || surfaces.isEmpty) {
      return <SPLCalculation>[];
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
        sp.roll,
        sp.pitch,
        sp.yaw,
      );
      clusterIds.add(cid);
    }

    // add each surface and its field points
    for (final ListeningArea cs in surfaces) {
      final List<List<double>> poly3d = cs.vertices.map((Offset o) => <double>[o.dx, o.dy, 0.0]).toList();
      engine.addSurface(poly3d);

      final List<Offset> pts = cs.getFieldPoints();
      final List<List<double>> list3d = pts.map((Offset o) => <double>[o.dx, o.dy, 0.0]).toList();
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

    // fetch SPLs (matching the same field‐points count) – default @1 kHz (1/3-oct) for initial fill
    for (final SPLCalculation sc in calculations) {
      final List<Offset> pts = sc.surface.getFieldPoints();
      sc.spl = engine.getSpl(sc.fphHandle, 1000, pts.length);
    }

    return calculations;
  }

  static Iterable<SPLCalculation> currentCalculations() => _calcByFph.values;

  /// Reads SPL values from the existing calculation (does NOT run the engine again).
  ///
  /// - For [Bandwidth.oneThirdOctave] and [Bandwidth.oneOctave], you MUST pass an exact [freqHz]
  ///   that exists in the native "frequencies" list; otherwise throws [ArgumentError].
  /// - For [Bandwidth.vocalBands] and [Bandwidth.broadband], [freqHz] must be null.
  ///
  /// Returns a single updated [SPLCalculation] (wrapped in a List) for the requested [fph].
  static List<SPLCalculation> getSplForBandwidth(
    MaceEngine engine,
    int fph, {
    required Bandwidth bandwidth,
    int? freqHz,
  }) {
    final SPLCalculation? sc = _calcByFph[fph];
    if (sc == null) {
      throw StateError(
        'Unknown FieldPoints handle $fph. Run calculateSpl(...) first so we can link fph -> surface.',
      );
    }

    // Pull the already-computed SPL JSON from native (no runCalculation here).
    final Map<String, dynamic> json = engine.getAllSplJson(fph);

    switch (bandwidth) {
      case Bandwidth.oneThirdOctave:
      case Bandwidth.oneOctave:
        if (freqHz == null) {
          throw ArgumentError('freqHz must be provided for $bandwidth');
        }

        // Fix: Properly cast dynamic list to num list
        final List<num> freqs = (json['frequencies'] as List<dynamic>).map((dynamic e) => e as num).toList();
        final int idx = freqs.indexOf(freqHz);
        if (idx == -1) {
          throw ArgumentError('Frequency $freqHz Hz not available in data: $freqs');
        }
        final String key = (bandwidth == Bandwidth.oneThirdOctave) ? 'oneThirdOctave' : 'oneOctave';

        // Fix: Correctly parse the matrix structure
        final List<List<double>> mat =
            (json['spl'][key] as List<dynamic>)
                .map<List<double>>((dynamic row) => (row as List<dynamic>).cast<num>().map((num e) => e.toDouble()).toList())
                .toList();

        sc.spl = List<double>.generate(mat.length, (int p) => mat[p][idx]);
        return <SPLCalculation>[sc];

      case Bandwidth.vocalBands:
        if (freqHz != null) {
          throw ArgumentError('freqHz must be null for vocalBands');
        }
        sc.spl = (json['spl']['vocalBands'] as List<dynamic>).map((dynamic e) => (e as num).toDouble()).toList();
        return <SPLCalculation>[sc];

      case Bandwidth.broadband:
        if (freqHz != null) {
          throw ArgumentError('freqHz must be null for broadband');
        }
        sc.spl = (json['spl']['broadband'] as List<dynamic>).map((dynamic e) => (e as num).toDouble()).toList();
        return <SPLCalculation>[sc];
    }
  }
}
