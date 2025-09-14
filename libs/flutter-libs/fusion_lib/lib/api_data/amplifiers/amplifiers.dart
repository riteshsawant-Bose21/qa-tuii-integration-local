/// Amplifier API Data Module
///
/// This module exports all amplifier-related data structures and catalogs

import 'dart:convert';
import 'dart:math' as math;
import 'amplifier_types.dart';
import 'amplifier_catalog.dart';

/// Returns all amplifiers as a JSON string
String getAllAmplifiersCatalog() {
  final amps = AmpCatalog.models.map((a) => a.toJson()).toList();
  return jsonEncode(amps);
}

/// Main entry point: match amplifiers to circuits
List<Assignment2> matchAmps(List<AmpCircuit> input, List<AmpModel> amps) {
  if (input.isEmpty) {
    throw Exception('No circuits provided');
  }
  if (amps.isEmpty) {
    throw Exception('Amp catalog is empty');
  }

  // Build internal CircuitCalc list
  final calcs = input.map((c) {
    final cc = CircuitCalc(base: c);
    cc.offsetDB = c.offsetDB ?? 0;
    return cc;
  }).toList();

  // Compute PpkTotal and check impedance
  for (final c in calcs) {
    computeCircuitPpk(c);
  }

  // Sort circuits desc by PpkTotal
  calcs.sort((a, b) => b.ppkTotal.compareTo(a.ppkTotal));

  // Initial assignment (tier rule + 4/8 channel blocks)
  final initial = initialAssign(calcs, amps);

  // Power-sharing optimization
  final optimized = powerShareOptimize(initial);

  // Down-tier pass
  final finalAssigns = downTierPass(optimized, amps);

  // Convert to outward Assignment type
  return finalAssigns
      .map(
        (a) => Assignment2(
          amp: a.amp,
          loads: a.loads.map((l) => l.base).toList(),
        ),
      )
      .toList();
}

// Function to collect all errors from circuit calculations
List<String> collectCircuitErrors(List<CircuitCalc> calcs) {
  final allErrors = <String>[];
  for (final calc in calcs) {
    for (final error in calc.errors) {
      allErrors.add('Circuit ${calc.base.model}: $error');
    }
  }
  return allErrors;
}

// Helper: compute PpkTotal for a circuit
void computeCircuitPpk(CircuitCalc c) {
  // For demo, use simple logic. Expand as needed.
  final mode = c.base.mode.toLowerCase();
  final spCount = c.base.speakerCount;
  if (mode.contains('hi-z')) {
    final tap = c.base.tapWatts ?? 1.0;
    c.ppkTotal = spCount * tap * 2.0;
  } else if (mode.contains('lo-z')) {
    // For demo, use tapWatts as Ppk
    final ppk = c.base.tapWatts ?? 1.0;
    c.ppkTotal = spCount * ppk;
    final nom = c.base.impedance ?? 8.0;
    final zTotal = nom / spCount;
    if (zTotal < 4.0) {
      c.errors.add('Total impedance $zTotal Ω < 4 Ω');
    }
  } else {
    throw Exception('Unknown mode: ${c.base.mode}');
  }
  // Offset dB
  final d = c.base.offsetDB ?? 0;
  if (d > 0) {
    final factor = math.pow(10.0, -d / 10.0);
    c.ppkTotal *= factor;
    c.offsetDB = d;
  }
}

// Internal assignment structure
class InternalAssign {
  AmpModel amp;
  List<CircuitCalc> loads;
  InternalAssign({required this.amp, List<CircuitCalc>? loads}) : loads = loads ?? [];
}

// Helper function to handle oversized circuits that need multiple channels
List<InternalAssign> handleOversizedCircuit(CircuitCalc circuit, List<AmpModel> catalog) {
  final maxPerChannel = catalog.isEmpty ? 0.0 : catalog.last.peakPerChannel;
  final channelsNeeded = (circuit.ppkTotal / maxPerChannel).ceil();

  // Find best amplifier that can accommodate the required channels
  AmpModel? bestAmp;
  for (final amp in catalog.reversed) {
    if (amp.channels >= channelsNeeded) {
      bestAmp = amp;
      break;
    }
  }

  if (bestAmp == null) {
    // No single amplifier can handle this - use largest available
    bestAmp = catalog.last;
    circuit.errors.add('Circuit requires ${channelsNeeded} channels but maximum available is ${bestAmp.channels}');
  }

  // Create single assignment with the circuit spread across multiple channels
  final ass = InternalAssign(amp: bestAmp);
  final powerPerChannel = circuit.ppkTotal / channelsNeeded;

  // Add the circuit once, but mark it as using multiple channels
  circuit.errors.add('Multi-channel: Uses ${channelsNeeded} channels at ${powerPerChannel.toStringAsFixed(0)}W each');
  ass.loads.add(circuit);

  return [ass];
}

// Initial assignment logic
List<InternalAssign> initialAssign(List<CircuitCalc> sorted, List<AmpModel> amps) {
  final catalog = List<AmpModel>.from(amps);
  catalog.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));
  final out = <InternalAssign>[];
  int i = 0;
  final n = sorted.length;

  // Find maximum amplifier power per channel for validation
  final maxPerChannel = catalog.isEmpty ? 0.0 : catalog.last.peakPerChannel;

  while (i < n) {
    final circuit = sorted[i];

    // Check if circuit exceeds maximum amplifier per-channel capacity
    if (circuit.ppkTotal > maxPerChannel) {
      // Handle oversized circuit with dedicated function
      final oversizedAssignments = handleOversizedCircuit(circuit, catalog);
      out.addAll(oversizedAssignments);
      i++;
      continue;
    }

    // Standard assignment for circuits that fit in single channels
    final remaining = n - i;
    int blockChannels = remaining > 4 ? 8 : 4;
    var ampModel = chooseAmpByTierRule(circuit.ppkTotal, catalog);
    ampModel = pickChannelVariant(ampModel, blockChannels, catalog);
    final ass = InternalAssign(amp: ampModel);

    // Assign circuits to this amplifier, ensuring each fits per channel
    for (int ch = 0; ch < ampModel.channels && i < n; ch++) {
      final currentCircuit = sorted[i];

      // Validate circuit fits in this amplifier's channel
      if (currentCircuit.ppkTotal <= ampModel.peakPerChannel) {
        ass.loads.add(currentCircuit);
        i++;
      } else {
        // Circuit too large for this amplifier - will be handled in next iteration
        break;
      }
    }

    // Only add assignment if it has circuits
    if (ass.loads.isNotEmpty) {
      out.add(ass);
    }
  }
  return out;
}

AmpModel chooseAmpByTierRule(double required, List<AmpModel> catalog) {
  if (catalog.isEmpty) return catalog.first;
  if (required <= catalog.first.peakPerChannel) return catalog.first;
  for (int i = 0; i < catalog.length - 1; i++) {
    final cur = catalog[i];
    final next = catalog[i + 1];
    if (required > cur.peakPerChannel && required <= next.peakPerChannel) {
      return next;
    }
  }
  return catalog.last;
}

AmpModel pickChannelVariant(AmpModel base, int desiredChannels, List<AmpModel> catalog) {
  for (final m in catalog) {
    if (m.peakPerChannel == base.peakPerChannel && m.channels == desiredChannels) {
      return m;
    }
  }
  final cands = catalog.where((m) => m.channels == desiredChannels).toList();
  if (cands.isEmpty) return base;
  cands.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));
  for (final c in cands) {
    if (c.peakPerChannel >= base.peakPerChannel) return c;
  }
  return cands.last;
}

List<InternalAssign> powerShareOptimize(List<InternalAssign> assigns) {
  if (assigns.isEmpty) return assigns;
  bool moved;
  do {
    moved = false;
    assigns.sort((a, b) => a.amp.peakPerChannel.compareTo(b.amp.peakPerChannel));
    for (int tIdx = 0; tIdx < assigns.length; tIdx++) {
      final target = assigns[tIdx];
      final perCh = target.amp.peakPerChannel;
      final used = target.loads.length;
      final freeCh = target.amp.channels - used;
      double netSpare = 0.0;
      for (final l in target.loads) {
        netSpare += perCh - l.ppkTotal;
      }
      netSpare += freeCh * perCh;
      if (netSpare <= 0 || freeCh <= 0) continue;
      int bestSrcIdx = -1, bestLoadIdx = -1;
      double bestLoadVal = 0;
      for (int sIdx = 0; sIdx < assigns.length; sIdx++) {
        if (assigns[sIdx].amp.peakPerChannel <= perCh) continue;
        for (int li = 0; li < assigns[sIdx].loads.length; li++) {
          final load = assigns[sIdx].loads[li];
          // Enhanced validation: circuit must fit in target amplifier's per-channel capacity
          if (load.ppkTotal <= perCh && load.ppkTotal <= netSpare && load.ppkTotal > bestLoadVal) {
            bestLoadVal = load.ppkTotal;
            bestSrcIdx = sIdx;
            bestLoadIdx = li;
          }
        }
      }
      if (bestSrcIdx >= 0) {
        final loadToMove = assigns[bestSrcIdx].loads[bestLoadIdx];
        target.loads.add(loadToMove);
        assigns[bestSrcIdx].loads.removeAt(bestLoadIdx);
        if (assigns[bestSrcIdx].loads.isEmpty) {
          assigns.removeAt(bestSrcIdx);
          moved = true;
          break;
        }
        moved = true;
      }
    }
  } while (moved);
  return assigns;
}

List<InternalAssign> downTierPass(List<InternalAssign> assigns, List<AmpModel> amps) {
  final catalog = List<AmpModel>.from(amps);
  catalog.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));
  final out = <InternalAssign>[];
  for (final a in assigns) {
    double maxLoad = 0.0;
    for (final l in a.loads) {
      if (l.ppkTotal > maxLoad) maxLoad = l.ppkTotal;
    }
    var best = catalog.last;
    for (final c in catalog) {
      if (c.peakPerChannel >= maxLoad) {
        best = c;
        break;
      }
    }
    var found = false;
    for (final c in catalog) {
      if (c.peakPerChannel == best.peakPerChannel && c.channels == a.amp.channels) {
        a.amp = c;
        found = true;
        break;
      }
    }
    if (!found) {
      for (final c in catalog) {
        if (c.channels == a.amp.channels && c.peakPerChannel >= maxLoad) {
          a.amp = c;
          found = true;
          break;
        }
      }
    }
    if (!found) {
      a.amp = best;
    }
    out.add(a);
  }
  return out;
}
