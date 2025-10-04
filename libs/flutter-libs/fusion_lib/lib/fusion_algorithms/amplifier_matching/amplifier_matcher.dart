import 'dart:math' as math;

import '../../api_data/amplifiers/amplifier_catalog.dart';
import '../../api_data/amplifiers/amplifier_types.dart';
import '../../api_data/speakers/speakers.dart';
import 'amp_matching_types.dart';
import 'amplifier_matching_error_handler.dart';
import 'amplifier_matching_logger.dart';

/// Power allocation strategy for amplifier selection
enum PowerAllocationStrategy {
  /// Symmetrical: Each circuit must fit within per-channel limits (Steps 1-5)
  symmetrical,
  
  /// Asymmetrical: Total power can be shared across channels (Steps 6+)
  asymmetrical,
  
  /// Comparison: Show both strategies side-by-side
  comparison;
  
  String get label {
    switch (this) {
      case PowerAllocationStrategy.symmetrical:
        return 'Symmetrical Only';
      case PowerAllocationStrategy.asymmetrical:
        return 'Asymmetrical (Power Sharing)';
      case PowerAllocationStrategy.comparison:
        return 'Compare Both';
    }
  }
  
  String get description {
    switch (this) {
      case PowerAllocationStrategy.symmetrical:
        return 'Traditional per-channel power limits';
      case PowerAllocationStrategy.asymmetrical:
        return 'Advanced total capacity optimization';
      case PowerAllocationStrategy.comparison:
        return 'Show side-by-side comparison';
    }
  }
}

/// Internal circuit calculation with computed power and errors
class _CircuitCalc {
  final Circuit base;
  double ppkTotal = 0.0;
  double offsetDb = 0.0;
  final List<String> errors = [];

  _CircuitCalc(this.base);
}

/// Internal assignment structure for optimization
class _InternalAssign {
  AmpModel amp;
  List<_CircuitCalc> loads;

  _InternalAssign({required this.amp, required this.loads});
}

/// Final assignment result
class Assignment {
  final AmpModel amp;
  final List<Circuit> loads;

  const Assignment({required this.amp, required this.loads});

  Map<String, dynamic> toJson() => {'amp': amp.toJson(), 'loads': loads.map((l) => l.toJson()).toList()};
}

/// Enhanced Amplifier Matching Algorithm with Comprehensive Logging and Error Handling
///
/// This implementation follows the 12-step algorithm specification:
/// 1. Determine Circuit Types and Calculate Total Power
/// 2. Apply Output Offsets
/// 3. Sort Circuits by Power Requirements
/// 4. Choose Amplifier Using Tier Rule
/// 5. Apply Channel Allocation Strategy
/// 6. Run Simplified Power Sharing Calculator
/// 7. Identify Channels with Positive Net Power Sharing
/// 8. Optimize Circuit Allocation
/// 9. Update Power Sharing Information
/// 10. Remove Empty Amplifier Assignments
/// 11. Final Tier Rule Validation
/// 12. SKU Reduction

class AmplifierMatcher {
  static int _optimizationIterations = 0;
  static int _circuitMovesPerformed = 0;

  /// Helper function to get asymmetrical power capacity based on circuit impedance/voltage
  static double _getAsymmetricalCapacity(AmpModel amp, List<_CircuitCalc> circuits) {
    // If we have enhanced power specs, use them
    if (amp.powerSpecs != null) {
      // Analyze circuits to determine the most restrictive impedance/voltage configuration
      double? maxVoltage;
      bool hasLoZ = false;
      
      for (final circuit in circuits) {
        if (circuit.base.mode == 'Hi-Z' || circuit.base.mode == 'hi-z') {
          // For Hi-Z circuits, estimate voltage from tap watts
          if (circuit.base.tapWatts > 0) {
            // Heuristic: Higher tap watts usually indicate 100V systems
            final estimatedVoltage = circuit.base.tapWatts > 50 ? 100.0 : 70.0;
            if (maxVoltage == null || estimatedVoltage > maxVoltage) {
              maxVoltage = estimatedVoltage;
            }
          }
        } else {
          // Lo-Z circuits detected
          hasLoZ = true;
        }
      }
      
      // Get asymmetrical capacity based on the most restrictive configuration
      if (maxVoltage != null) {
        // Use Hi-Z voltage-based rating
        return amp.powerSpecs!.getAsymmetricalPeakPower(voltage: maxVoltage);
      } else if (hasLoZ) {
        // Use 8Ω Lo-Z rating as conservative default
        return amp.powerSpecs!.getAsymmetricalPeakPower(impedance: 8.0);
      } else {
        // Default to 8Ω if unclear
        return amp.powerSpecs!.getAsymmetricalPeakPower(impedance: 8.0);
      }
    }
    
    // Fallback to legacy calculation for amplifiers without enhanced specs
    return amp.peakPerChannel * amp.channels;
  }

  /// Main entry point: matches amplifiers to circuits with comprehensive logging
  ///
  /// [input] - List of audio circuits to be matched
  /// [speakers] - Database of speaker specifications
  /// [amps] - List of available amplifier models
  /// [strategy] - Power allocation strategy (symmetrical or asymmetrical)
  ///
  /// Returns [List<Assignment>] with optimized amplifier assignments
  static List<Assignment> matchAmps(
    List<Circuit> input, 
    Map<String, SpeakerModel> speakers, 
    List<AmpModel> amps,
    {PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical}
  ) {
    final stopwatch = Stopwatch()..start();
    _optimizationIterations = 0;
    _circuitMovesPerformed = 0;

    try {
      // STEP 0: Comprehensive Input Validation
      AmpMatchingLogger.logInitialization(circuitCount: input.length, speakerModels: speakers.length, amplifierModels: amps.length);

      _validateInputs(input, speakers, amps);

      // STEP 1: Build internal circuit calculations
      final calcs = <_CircuitCalc>[];
      for (final circuit in input) {
        final cc = _CircuitCalc(circuit);
        cc.offsetDb = circuit.outputOffsetDb;
        calcs.add(cc);
      }

      // STEP 1 & 2: Compute circuit power and apply offsets
      _computeAllCircuitPowers(calcs, speakers);

      // STEP 3: Sort circuits by power requirements (descending)
      calcs.sort((a, b) => b.ppkTotal.compareTo(a.ppkTotal));
      _logSortedCircuits(calcs);

      // STEP 4 & 5: Initial assignment using tier rule + channel allocation
      final initial = _initialAssignWithLogging(calcs, strategy: strategy);

      // STEP 6-9: Power-sharing optimization
      final optimized = _powerShareOptimizeWithLogging(initial);

      // STEP 10: Remove empty assignments
      final cleaned = _removeEmptyAssignments(optimized);

      // STEP 11 & 12: Down-tier pass and final validation
      final finalAssigns = _downTierPassWithLogging(cleaned, strategy: strategy);

      stopwatch.stop();

      // Log performance metrics
      AmpMatchingLogger.logPerformanceMetrics(
        executionTime: stopwatch.elapsed,
        iterationsPerformed: _optimizationIterations,
        movesPerformed: _circuitMovesPerformed,
      );

      // Convert to outward Assignment type (with original circuits)
      return finalAssigns.map((a) => Assignment(amp: a.amp, loads: a.loads.map((l) => l.base).toList())).toList();
    } on Exception catch (e) {
      AmpMatchingLogger.logError('ALGORITHM_EXECUTION', 'Algorithm failed', e);
      final wrappedException = AmpMatchingErrorHandler.wrapException(e, 'ALGORITHM_EXECUTION', {
        'input_circuits': input.length,
        'execution_time_ms': stopwatch.elapsedMilliseconds,
      });
      throw wrappedException;
    }
  }

  /// Comprehensive input validation with detailed error reporting
  static void _validateInputs(List<Circuit> circuits, Map<String, SpeakerModel> speakers, List<AmpModel> amps) {
    // Validate circuits
    final circuitValidation = AmpMatchingErrorHandler.validateCircuits(circuits);
    if (circuitValidation.hasErrors) {
      throw InvalidCircuitException('Circuit validation failed: ${circuitValidation.errors.join('; ')}');
    }

    // Validate speaker database
    final speakerValidation = AmpMatchingErrorHandler.validateSpeakerDatabase(speakers, circuits);
    if (speakerValidation.hasErrors) {
      throw InvalidCircuitException('Speaker database validation failed: ${speakerValidation.errors.join('; ')}');
    }

    // Validate amplifier catalog
    final ampValidation = AmpMatchingErrorHandler.validateAmplifierCatalog(amps);
    if (ampValidation.hasErrors) {
      throw CatalogException('Amplifier catalog validation failed: ${ampValidation.errors.join('; ')}');
    }
  }

  /// STEP 1 & 2: Compute circuit power with comprehensive logging and error handling
  static void _computeAllCircuitPowers(List<_CircuitCalc> calcs, Map<String, SpeakerModel> speakerDatabase) {
    for (final c in calcs) {
      try {
        _computeCircuitPpkWithLogging(c, speakerDatabase);
      } on Exception catch (e) {
        AmpMatchingLogger.logError('CIRCUIT_POWER_CALCULATION', 'Failed to calculate power for circuit ${c.base.circuitId}', e);
        rethrow;
      }
    }
  }

  /// Enhanced circuit power calculation with detailed logging
  static void _computeCircuitPpkWithLogging(_CircuitCalc c, Map<String, SpeakerModel> speakerDatabase) {
    final circuit = c.base;

    // Validate circuit has model
    if (circuit.model.isEmpty) {
      throw InvalidCircuitException('Circuit ${circuit.circuitId} missing speaker model', context: {'circuit_id': circuit.circuitId});
    }

    // Lookup speaker in database
    final spec = speakerDatabase[circuit.model];
    if (spec == null) {
      throw InvalidCircuitException(
        'Speaker model "${circuit.model}" not found in database',
        context: {'circuit_id': circuit.circuitId, 'model': circuit.model},
      );
    }

    // Validate speaker count
    if (circuit.speakerCount <= 0) {
      throw InvalidCircuitException(
        'Invalid speaker count ${circuit.speakerCount} for circuit ${circuit.circuitId}',
        context: {'circuit_id': circuit.circuitId, 'speaker_count': circuit.speakerCount},
      );
    }

    // Calculate power based on mode
    final mode = circuit.mode.toLowerCase().replaceAll('_', '-');
    double powerPeak = 0.0;
    double powerRms = 0.0;
    double impedanceTotal = 0.0;
    bool impedanceValid = true;
    String circuitType = '';

    switch (mode) {
      case 'hi-z':
      case 'hiz':
      case 'high-z':
      case 'highz':
        circuitType = 'Hi-Z';
        final tap = _determineHiZTap(circuit, spec);
        
        // STEP 1: Hi-Z Power Calculation: Ppk_speaker_total = ∑(Loudspeaker_Ptaps) × 2
        final tapRmsTotal = circuit.speakerCount * tap; // Sum all tap wattages (RMS)
        powerPeak = tapRmsTotal * 2.0; // Multiply by 2 to convert from RMS to peak power
        powerRms = tapRmsTotal; // Keep RMS for amplifier comparison
        c.ppkTotal = powerPeak; // Store peak power as specified
        impedanceTotal = double.infinity; // Hi-Z doesn't have impedance issues

        AmpMatchingLogger.logCircuitAnalysis(
          circuit,
          circuitType: circuitType,
          powerRms: powerRms,
          powerPeak: powerPeak,
          impedanceTotal: impedanceTotal,
          impedanceValid: impedanceValid,
          notes: 'Hi-Z calculation: ${circuit.speakerCount} speakers × ${tap}W tap = ${tapRmsTotal}W RMS → ${powerPeak.toStringAsFixed(1)}W peak (×2)',
        );
        break;

      case 'lo-z':
      case 'loz':
      case 'low-z':
      case 'lowz':
        circuitType = 'Lo-Z';
        
        // STEP 1: Lo-Z Power Calculation: Ppk_speaker_total = ∑(Loudspeaker_Ppk)
        powerPeak = circuit.speakerCount * spec.ppk; // Sum peak power ratings of all speakers
        powerRms = powerPeak / 2.0; // Convert to RMS for amplifier comparison
        c.ppkTotal = powerPeak; // Store peak power as specified

        // Impedance validation for parallel speakers
        impedanceTotal = _calculateParallelImpedance(spec.nominalOhms, circuit.speakerCount);
        impedanceValid = impedanceTotal >= 4.0;

        if (!impedanceValid) {
          try {
            AmpMatchingErrorHandler.validateImpedance(circuit, impedanceTotal, spec);
          } on ImpedanceMismatchException catch (e) {
            c.errors.add(e.message);
            AmpMatchingLogger.logError('IMPEDANCE_VALIDATION', e.message);
          }
        }

        AmpMatchingLogger.logCircuitAnalysis(
          circuit,
          circuitType: circuitType,
          powerRms: powerRms,
          powerPeak: powerPeak,
          impedanceTotal: impedanceTotal,
          impedanceValid: impedanceValid,
          notes: 'Lo-Z calculation: ${circuit.speakerCount} speakers × ${spec.ppk}W peak = ${powerPeak.toStringAsFixed(1)}W peak, Parallel impedance = ${impedanceTotal.toStringAsFixed(2)}Ω',
        );
        break;

      default:
        throw InvalidCircuitException(
          'Unknown circuit mode "${circuit.mode}" for circuit ${circuit.circuitId}',
          context: {'circuit_id': circuit.circuitId, 'mode': circuit.mode},
        );
    }

    // STEP 2: Apply output offset if present
    if (circuit.outputOffsetDb > 0) {
      final originalPower = c.ppkTotal;
      final reductionFactor = math.pow(10.0, -circuit.outputOffsetDb / 10.0).toDouble();
      c.ppkTotal *= reductionFactor;
      c.offsetDb = circuit.outputOffsetDb;

      AmpMatchingLogger.logOffsetApplication(
        circuit.circuitId,
        originalPower: originalPower,
        offsetDb: circuit.outputOffsetDb,
        reducedPower: c.ppkTotal,
        reductionFactor: reductionFactor,
      );
    }

    // Final validation of calculated power
    AmpMatchingErrorHandler.validateCircuitPower(circuit, c.ppkTotal, spec);
  }

  /// Determine appropriate hi-z tap for circuit
  static double _determineHiZTap(Circuit circuit, SpeakerModel spec) {
    if (circuit.tapWatts > 0) {
      // Use specified tap watts if provided
      if (spec.hiZTaps.isNotEmpty && !spec.hiZTaps.contains(circuit.tapWatts)) {
        throw InvalidCircuitException(
          'Specified tap ${circuit.tapWatts}W not available for speaker ${circuit.model}',
          context: {'circuit_id': circuit.circuitId, 'requested_tap': circuit.tapWatts, 'available_taps': spec.hiZTaps},
        );
      }
      return circuit.tapWatts;
    }

    // Use first available tap if none specified
    if (spec.hiZTaps.isEmpty) {
      throw InvalidCircuitException(
        'Hi-Z circuit ${circuit.circuitId} lacks tap specification and speaker ${circuit.model} has no available taps',
        context: {'circuit_id': circuit.circuitId, 'speaker_model': circuit.model},
      );
    }

    return spec.hiZTaps[0];
  }

  /// Calculate parallel impedance for multiple speakers
  static double _calculateParallelImpedance(double nominalOhms, int speakerCount) {
    if (nominalOhms <= 0 || speakerCount <= 0) {
      return 0.0;
    }
    return nominalOhms / speakerCount;
  }

  /// Log sorted circuits after power calculation
  static void _logSortedCircuits(List<_CircuitCalc> sorted) {
    final circuitsWithPower = sorted.map((calc) => CircuitWithPower(circuit: calc.base, requiredPpk: calc.ppkTotal)).toList();

    AmpMatchingLogger.logCircuitSorting(circuitsWithPower);
  }

  /// STEP 4 & 5: Initial assignment with comprehensive logging
  static List<_InternalAssign> _initialAssignWithLogging(List<_CircuitCalc> sorted, {PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical}) {
    AmpMatchingLogger.logInitialization(
      circuitCount: sorted.length,
      speakerModels: 0, // Will be updated in actual implementation
      amplifierModels: AmpCatalog.models.length,
    );

    return _initialAssign(sorted, strategy: strategy);
  }

  /// STEP 6-9: Power sharing optimization with logging
  static List<_InternalAssign> _powerShareOptimizeWithLogging(List<_InternalAssign> assigns) {
    _optimizationIterations++;

    // Log initial power sharing analysis
    for (int i = 0; i < assigns.length; i++) {
      final assign = assigns[i];
      final channelLoads = List<double>.filled(assign.amp.channels, 0.0);
      double usedPower = 0.0;

      for (int j = 0; j < assign.loads.length; j++) {
        channelLoads[j] = assign.loads[j].ppkTotal;
        usedPower += assign.loads[j].ppkTotal;
      }

      final totalCapacity = _getAsymmetricalCapacity(assign.amp, assign.loads);
      final netSharing = totalCapacity - usedPower;

      AmpMatchingLogger.logPowerSharingAnalysis(
        ampIndex: i,
        amp: assign.amp,
        usedChannels: assign.loads.length,
        totalCapacity: totalCapacity,
        usedPower: usedPower,
        netSharing: netSharing,
        channelLoads: channelLoads,
      );
    }

    return _powerShareOptimize(assigns);
  }

  /// STEP 10: Remove empty assignments
  static List<_InternalAssign> _removeEmptyAssignments(List<_InternalAssign> assigns) {
    final result = <_InternalAssign>[];

    for (final assign in assigns) {
      if (assign.loads.isEmpty) {
        AmpMatchingLogger.logAmplifierRemoval(assign.amp, 'No circuits assigned after optimization');
      } else {
        result.add(assign);
      }
    }

    return result;
  }

  /// STEP 11 & 12: Down-tier pass with logging and validation
  static List<_InternalAssign> _downTierPassWithLogging(List<_InternalAssign> assigns, {PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical}) {
    final result = <_InternalAssign>[];

    for (final assign in assigns) {
      // Find maximum power requirement for tier validation
      double maxLoad = 0.0;
      double totalLoad = 0.0;
      for (final load in assign.loads) {
        if (load.ppkTotal > maxLoad) {
          maxLoad = load.ppkTotal;
        }
        totalLoad += load.ppkTotal;
      }

      // Validate based on strategy
      bool passesRule;
      if (strategy == PowerAllocationStrategy.symmetrical) {
        // Symmetrical: each circuit must fit within per-channel capacity
        passesRule = assign.amp.peakPerChannel >= maxLoad;
        AmpMatchingLogger.logTierValidation(amp: assign.amp, maxCircuitPower: maxLoad, passesRule: passesRule);
        
        if (!passesRule) {
          AmpMatchingLogger.logError(
            'TIER_VALIDATION',
            'Symmetrical mode: Amplifier ${assign.amp.name} fails tier rule: max load ${maxLoad.toStringAsFixed(1)}W > capacity ${assign.amp.peakPerChannel.toStringAsFixed(0)}W per channel',
          );
        }
      } else {
        // Asymmetrical: total power must fit within total amplifier capacity
        final totalCapacity = _getAsymmetricalCapacity(assign.amp, assign.loads);
        passesRule = totalCapacity >= totalLoad;
        AmpMatchingLogger.logTierValidation(amp: assign.amp, maxCircuitPower: totalLoad, passesRule: passesRule);
        
        if (!passesRule) {
          AmpMatchingLogger.logError(
            'TIER_VALIDATION',
            'Asymmetrical mode: Amplifier ${assign.amp.name} fails tier rule: total load ${totalLoad.toStringAsFixed(1)}W > total capacity ${totalCapacity.toStringAsFixed(0)}W',
          );
        }
      }

      result.add(assign);
    }

    return _downTierPass(result, strategy: strategy);
  }

  /// STEP 4 & 5: Initial assignment using tier rule + 4/8 packing
  static List<_InternalAssign> _initialAssign(List<_CircuitCalc> sorted, {PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical}) {
    // Prepare sorted amp catalog ascending by PeakPerChannel
    final catalog = List<AmpModel>.from(AmpCatalog.models);
    catalog.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));

    final out = <_InternalAssign>[];
    int i = 0;
    final n = sorted.length;

    while (i < n) {
      final remaining = n - i;
      final blockChannels = remaining > 4 ? 8 : 4;

      AmpModel ampModel;
      
      if (strategy == PowerAllocationStrategy.symmetrical) {
        // Symmetrical: Choose amp tier based on first (highest power) circuit in this block
        final first = sorted[i];
        ampModel = _chooseAmpByTierRule(first.ppkTotal, catalog);
        
        // Log tier selection
        AmpMatchingLogger.logTierSelection(
          circuitId: first.base.circuitId,
          requiredPower: first.ppkTotal,
          selectedAmp: ampModel,
          availableTiers: catalog,
          rationale: 'Symmetrical: Selected for highest power circuit in block',
        );
      } else {
        // Asymmetrical: Calculate total power needed for this block and choose by total capacity
        double totalPowerNeeded = 0.0;
        final blockSize = math.min(blockChannels, remaining);
        for (int j = i; j < i + blockSize; j++) {
          totalPowerNeeded += sorted[j].ppkTotal;
        }
        
        ampModel = _chooseAmpByTierRuleAsymmetrical(totalPowerNeeded, blockChannels, catalog);
        
        // Log tier selection
        AmpMatchingLogger.logTierSelection(
          circuitId: sorted[i].base.circuitId,
          requiredPower: totalPowerNeeded,
          selectedAmp: ampModel,
          availableTiers: catalog,
          rationale: 'Asymmetrical: Selected for total power sharing across ${blockSize} circuits',
        );
      }

      // Attempt to pick variant with requested channel count (but not for asymmetrical strategy)
      if (strategy == PowerAllocationStrategy.symmetrical) {
        ampModel = _pickChannelVariant(ampModel, blockChannels, catalog);
      } else {
        // For asymmetrical, we already chose based on total capacity, so only ensure channel count matches
        if (ampModel.channels < blockChannels) {
          // If selected amp doesn't have enough channels, find one with the right channel count but same asymmetrical capacity
          final sameTotalCapacity = catalog.where((amp) => 
            amp.channels >= blockChannels && 
            amp.getAsymmetricalPeakPower() == ampModel.getAsymmetricalPeakPower()
          ).toList();
          if (sameTotalCapacity.isNotEmpty) {
            ampModel = sameTotalCapacity.first;
          }
        }
      }

      // Log channel allocation strategy
      AmpMatchingLogger.logChannelAllocation(
        remainingCircuits: remaining,
        selectedChannels: blockChannels,
        strategy: remaining > 4 ? '8-channel optimization' : '4-channel final block',
        selectedAmp: ampModel,
      );

      final ass = _InternalAssign(amp: ampModel, loads: []);

      // Fill up to ampModel.channels circuits
      for (int ch = 0; ch < ampModel.channels && i < n; ch++) {
        ass.loads.add(sorted[i]);
        i++;
      }
      out.add(ass);
    }
    return out;
  }

  /// Choose amplifier by tier rule - symmetrical mode (per-channel limits)
  static AmpModel _chooseAmpByTierRule(double required, List<AmpModel> catalog) {
    if (catalog.isEmpty) {
      throw const AmpMatchingException('empty catalog');
    }

    // Convert circuit peak power to RMS for comparison with amplifier RMS specs
    // Note: catalog "peakPerChannel" values are actually RMS ratings (industry standard)
    final requiredRms = required / 2.0; // Convert peak to RMS

    // Symmetrical mode: select based on per-channel capacity
    // If <= smallest -> smallest
    if (requiredRms <= catalog[0].peakPerChannel) {
      return catalog[0];
    }

    for (int i = 0; i < catalog.length - 1; i++) {
      final cur = catalog[i];
      final next = catalog[i + 1];
      if (requiredRms > cur.peakPerChannel && requiredRms <= next.peakPerChannel) {
        return next;
      }
    }
    return catalog[catalog.length - 1];
  }

  /// Choose amplifier by tier rule - asymmetrical mode (total capacity sharing)
  static AmpModel _chooseAmpByTierRuleAsymmetrical(double totalPowerNeeded, int channelsNeeded, List<AmpModel> catalog) {
    if (catalog.isEmpty) {
      throw const AmpMatchingException('empty catalog');
    }

    // Convert total peak power to RMS for comparison with amplifier RMS specs
    final totalPowerNeededRms = totalPowerNeeded / 2.0; // Convert peak to RMS

    // Sort by total asymmetrical capacity for power sharing mode
    final sortedByTotal = catalog.where((amp) => amp.channels >= channelsNeeded).toList();
    sortedByTotal.sort((a, b) => a.getAsymmetricalPeakPower().compareTo(b.getAsymmetricalPeakPower()));

    if (sortedByTotal.isEmpty) {
      return catalog.last; // Fallback to largest available
    }

    // Find smallest amp with sufficient total capacity
    for (final amp in sortedByTotal) {
      // Use asymmetrical capacity calculation for power sharing mode
      final totalCapacity = amp.getAsymmetricalPeakPower() / 2.0; // Convert to RMS
      if (totalCapacity >= totalPowerNeededRms) {
        return amp;
      }
    }
    
    return sortedByTotal.last; // Largest available if none sufficient
  }

  /// Pick channel variant matching desired channels and peak
  static AmpModel _pickChannelVariant(AmpModel base, int desiredChannels, List<AmpModel> catalog) {
    // Try exact match: same PeakPerChannel and same Channels
    for (final m in catalog) {
      if (m.peakPerChannel == base.peakPerChannel && m.channels == desiredChannels) {
        return m;
      }
    }

    // Otherwise pick smallest model with desiredChannels and Peak >= base.peakPerChannel
    final cands = catalog.where((m) => m.channels == desiredChannels).toList();
    if (cands.isEmpty) {
      return base; // Fallback: return base (likely different channels)
    }

    cands.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));
    for (final c in cands) {
      if (c.peakPerChannel >= base.peakPerChannel) {
        return c;
      }
    }
    return cands[cands.length - 1];
  }

  /// STEP 6-9: Power sharing optimization with detailed logging
  static List<_InternalAssign> _powerShareOptimize(List<_InternalAssign> assigns) {
    if (assigns.isEmpty) {
      return assigns;
    }

    // Run loop until no moves possible
    while (true) {
      bool moved = false;

      // Sort target amps ascending (fill smaller amps first)
      assigns.sort((a, b) => a.amp.peakPerChannel.compareTo(b.amp.peakPerChannel));

      // For each target amp (small->big), try to find largest single load on any strictly larger amp that fits into net spare
      for (int tIdx = 0; tIdx < assigns.length; tIdx++) {
        final target = assigns[tIdx];
        final perCh = target.amp.peakPerChannel;
        final used = target.loads.length;
        final freeCh = target.amp.channels - used;

        // Compute net spare: sum(perCh - load.ppkTotal) + freeCh*perCh
        double netSpare = 0.0;
        for (final l in target.loads) {
          netSpare += perCh - l.ppkTotal;
        }
        netSpare += freeCh * perCh;

        if (netSpare <= 0 || freeCh <= 0) {
          continue;
        }

        // Search candidate on larger amps
        int bestSrcIdx = -1, bestLoadIdx = -1;
        double bestLoadVal = 0;

        for (int sIdx = 0; sIdx < assigns.length; sIdx++) {
          if (assigns[sIdx].amp.peakPerChannel <= target.amp.peakPerChannel) {
            continue; // Only consider strictly larger amps as source
          }

          // Iterate loads on source amp
          for (int li = 0; li < assigns[sIdx].loads.length; li++) {
            final load = assigns[sIdx].loads[li];
            if (load.ppkTotal <= netSpare) {
              // Prefer largest load that fits so we aggressively reduce higher amps
              if (load.ppkTotal > bestLoadVal) {
                bestLoadVal = load.ppkTotal;
                bestSrcIdx = sIdx;
                bestLoadIdx = li;
              }
            }
          }
        }

        if (bestSrcIdx >= 0) {
          // Move best load from src to target
          final loadToMove = assigns[bestSrcIdx].loads[bestLoadIdx];

          // Log the circuit move
          AmpMatchingLogger.logCircuitMove(
            circuitId: loadToMove.base.circuitId,
            fromAmp: assigns[bestSrcIdx].amp,
            toAmp: target.amp,
            circuitPower: loadToMove.ppkTotal,
            availableSharing: netSpare,
            reason: 'Power sharing optimization - move to lower-tier amplifier',
          );

          target.loads.add(loadToMove);
          _circuitMovesPerformed++;

          // Remove from source
          assigns[bestSrcIdx].loads.removeAt(bestLoadIdx);

          // If source empty -> remove source amp
          if (assigns[bestSrcIdx].loads.isEmpty) {
            AmpMatchingLogger.logAmplifierRemoval(assigns[bestSrcIdx].amp, 'All circuits moved to more efficient amplifiers');
            assigns.removeAt(bestSrcIdx);
            // Indices changed; break outer loop to restart
            moved = true;
            break;
          }

          moved = true;
          // After successful move continue to attempt fill this target next iteration
        }
      }

      if (!moved) {
        break;
      }
    }

    return assigns;
  }

  /// STEP 11 & 12: Down-tier pass to select smaller SKUs with logging
  static List<_InternalAssign> _downTierPass(List<_InternalAssign> assigns, {PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical}) {
    // Prepare sorted amp catalog ascending by PeakPerChannel
    final catalog = List<AmpModel>.from(AmpCatalog.models);
    catalog.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));

    final out = <_InternalAssign>[];

    for (final a in assigns) {
      double maxLoad = 0.0;
      double totalLoad = 0.0;
      for (final l in a.loads) {
        if (l.ppkTotal > maxLoad) {
          maxLoad = l.ppkTotal;
        }
        totalLoad += l.ppkTotal;
      }

      AmpModel best;
      
      if (strategy == PowerAllocationStrategy.symmetrical) {
        // Symmetrical: Pick smallest amp that covers maxLoad per channel
        // Convert peak power to RMS for comparison with amplifier specs
        final maxLoadRms = maxLoad / 2.0;
        best = catalog[catalog.length - 1];
        for (final c in catalog) {
          if (c.peakPerChannel >= maxLoadRms) {
            best = c;
            break;
          }
        }
      } else {
        // Asymmetrical: Pick smallest amp that covers totalLoad across all channels
        // Convert peak power to RMS for comparison with amplifier specs
        final totalLoadRms = totalLoad / 2.0;
        final sortedByTotal = catalog.where((amp) => amp.channels >= a.loads.length).toList();
        sortedByTotal.sort((x, y) => x.getAsymmetricalPeakPower().compareTo(y.getAsymmetricalPeakPower()));
        
        best = sortedByTotal.last; // fallback
        for (final c in sortedByTotal) {
          // Use asymmetrical capacity for power sharing mode
          final totalCapacity = c.getAsymmetricalPeakPower() / 2.0; // Convert to RMS
          if (totalCapacity >= totalLoadRms) {
            best = c;
            break;
          }
        }
      }

      final originalAmp = a.amp;

      // Prefer model with same channel count; if none, keep best
      bool found = false;
      for (final c in catalog) {
        if (c.peakPerChannel == best.peakPerChannel && c.channels == a.amp.channels) {
          a.amp = c;
          found = true;
          break;
        }
      }

      if (!found) {
        // Find any with same channels and >= maxLoad (convert peak to RMS)
        final maxLoadRms = maxLoad / 2.0;
        for (final c in catalog) {
          if (c.channels == a.amp.channels && c.peakPerChannel >= maxLoadRms) {
            a.amp = c;
            found = true;
            break;
          }
        }
      }

      if (!found) {
        a.amp = best;
      }

      // Log SKU reduction if applicable
      if (a.amp.name != originalAmp.name) {
        final savings = originalAmp.peakPerChannel > a.amp.peakPerChannel ? 'Reduced power tier - cost optimization' : 'Adjusted for channel count';

        AmpMatchingLogger.logSkuReduction(originalAmp: originalAmp, reducedAmp: a.amp, maxLoad: maxLoad, savings: savings);
      }

      out.add(a);
    }

    return out;
  }

  /// Enhanced main entry point with comprehensive logging and error handling
  static Future<AmpMatchingResult> matchAmplifiers(
    List<Circuit> circuits, 
    Map<String, SpeakerModel> speakerDatabase,
    {PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical}
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Execute the core matching algorithm
      final assignments = matchAmps(circuits, speakerDatabase, AmpCatalog.models, strategy: strategy);

      // Convert to legacy format
      final ampAssignments = assignments.map((assignment) {
        return AmpAssignment(ampModel: assignment.amp, circuits: assignment.loads);
      }).toList();

      // Calculate comprehensive metrics
      final metrics = _calculateSystemMetrics(ampAssignments, circuits, speakerDatabase);

      stopwatch.stop();

      // Create final result with all validation
      final result = AmpMatchingResult(
        assignments: ampAssignments,
        totalPowerRequirement: metrics['totalUsedPower']!,
        totalSystemCapacity: metrics['totalAvailablePower']!,
        totalChannelsUsed: metrics['usedChannels']!.toInt(),
        totalChannelsAvailable: metrics['totalChannels']!.toInt(),
        optimizationNotes: _generateOptimizationNotes(ampAssignments, metrics),
        warnings: metrics['warnings'] as List<String>,
        errors: metrics['errors'] as List<String>,
      );

      // Final result validation
      final finalValidation = AmpMatchingErrorHandler.validateFinalResults(result, circuits);
      if (finalValidation.hasErrors) {
        for (final error in finalValidation.errors) {
          AmpMatchingLogger.logError('FINAL_VALIDATION', error);
        }
      }

      // Log comprehensive final results
      AmpMatchingLogger.logFinalResults(
        assignments: ampAssignments,
        totalPowerReq: metrics['totalUsedPower']!,
        totalCapacity: metrics['totalAvailablePower']!,
        powerEfficiency: result.powerEfficiency,
        channelEfficiency: result.channelEfficiency,
        warnings: result.warnings,
        errors: result.errors,
      );

      return result;
    } on Exception catch (e) {
      stopwatch.stop();
      AmpMatchingLogger.logError('AMPLIFIER_MATCHING', 'Matching failed after ${stopwatch.elapsedMilliseconds}ms', e);
      rethrow;
    }
  }

  /// Calculate comprehensive system metrics
  static Map<String, dynamic> _calculateSystemMetrics(
    List<AmpAssignment> assignments,
    List<Circuit> originalCircuits,
    Map<String, SpeakerModel> speakerDatabase,
  ) {
    double totalAvailablePower = 0.0;
    double totalUsedPower = 0.0;
    int totalChannels = 0;
    int usedChannels = 0;
    final List<String> warnings = [];
    final List<String> errors = [];

    // Calculate power and channel metrics
    for (final assignment in assignments) {
      totalChannels += assignment.ampModel.channels;
      usedChannels += assignment.circuits.length;
      totalAvailablePower += assignment.ampModel.peakPerChannel * assignment.ampModel.channels;

      // Validate each circuit assignment
      for (final circuit in assignment.circuits) {
        final speaker = speakerDatabase[circuit.model];
        if (speaker == null) {
          errors.add('Circuit ${circuit.circuitId}: Unknown speaker model "${circuit.model}"');
          continue;
        }

        double circuitPower = _calculateCircuitPower(circuit, speaker);
        totalUsedPower += circuitPower;

        // Validate power requirements
        if (circuitPower > assignment.ampModel.peakPerChannel) {
          final channelsNeeded = (circuitPower / assignment.ampModel.peakPerChannel).ceil();
          warnings.add(
            'Circuit ${circuit.circuitId}: Requires ${circuitPower.toStringAsFixed(0)}W but assigned to single channel of ${assignment.ampModel.peakPerChannel.toStringAsFixed(0)}W capacity (needs $channelsNeeded channels)',
          );
        }

        // Validate impedance for lo-z circuits
        if (circuit.mode.toLowerCase().contains('lo')) {
          final totalImpedance = speaker.nominalOhms / circuit.speakerCount;
          if (totalImpedance < 4.0) {
            if (totalImpedance < 2.0) {
              errors.add('Circuit ${circuit.circuitId}: Dangerous impedance ${totalImpedance.toStringAsFixed(2)}Ω - risk of amplifier damage');
            } else {
              warnings.add('Circuit ${circuit.circuitId}: Low impedance ${totalImpedance.toStringAsFixed(2)}Ω - monitor amplifier performance');
            }
          }
        }
      }
    }

    // System-level warnings
    final powerEfficiency = totalUsedPower / totalAvailablePower;
    if (powerEfficiency < 0.2) {
      warnings.add('Very low power efficiency (${(powerEfficiency * 100).toStringAsFixed(1)}%) - system is significantly oversized');
    } else if (powerEfficiency < 0.3) {
      warnings.add('Low power efficiency (${(powerEfficiency * 100).toStringAsFixed(1)}%) - consider using smaller amplifiers');
    }

    final channelEfficiency = usedChannels / totalChannels;
    if (channelEfficiency < 0.3) {
      warnings.add('Very low channel efficiency (${(channelEfficiency * 100).toStringAsFixed(1)}%) - many channels unused');
    } else if (channelEfficiency < 0.5) {
      warnings.add('Low channel efficiency (${(channelEfficiency * 100).toStringAsFixed(1)}%) - some optimization potential remains');
    }

    // Check for power sharing opportunities
    if (assignments.length > 1) {
      warnings.add('Multiple amplifiers required - review if power sharing or tier adjustments could reduce amplifier count');
    }

    return {
      'totalAvailablePower': totalAvailablePower,
      'totalUsedPower': totalUsedPower,
      'totalChannels': totalChannels.toDouble(),
      'usedChannels': usedChannels.toDouble(),
      'warnings': warnings,
      'errors': errors,
    };
  }

  /// Calculate circuit power requirement
  static double _calculateCircuitPower(Circuit circuit, SpeakerModel speaker) {
    final mode = circuit.mode.toLowerCase();
    double power = 0.0;

    if (mode.contains('hi')) {
      final tap = circuit.tapWatts > 0 ? circuit.tapWatts : (speaker.hiZTaps.isNotEmpty ? speaker.hiZTaps[0] : 0.0);
      power = circuit.speakerCount * tap * 2.0; // RMS to peak conversion
    } else {
      power = circuit.speakerCount * speaker.ppk;
    }

    // Apply offset if present
    if (circuit.outputOffsetDb > 0) {
      final reductionFactor = math.pow(10.0, -circuit.outputOffsetDb / 10.0);
      power *= reductionFactor.toDouble();
    }

    return power;
  }

  /// Generate optimization notes based on results
  static String _generateOptimizationNotes(List<AmpAssignment> assignments, Map<String, dynamic> metrics) {
    final notes = <String>[];

    if (assignments.length == 1) {
      notes.add('Single amplifier solution achieved through power sharing optimization');
    } else {
      notes.add('Multiple amplifiers required due to high power requirements or capacity constraints');
    }

    final powerEfficiency = metrics['totalUsedPower']! / metrics['totalAvailablePower']!;
    if (powerEfficiency > 0.7) {
      notes.add('High power efficiency indicates well-optimized system sizing');
    } else if (powerEfficiency > 0.5) {
      notes.add('Good power efficiency with reasonable headroom for future expansion');
    }

    final channelEfficiency = metrics['usedChannels']! / metrics['totalChannels']!;
    if (channelEfficiency > 0.8) {
      notes.add('Excellent channel utilization minimizes unused capacity');
    }

    notes.add('Applied tier selection rule and power sharing algorithms for cost optimization');

    return notes.join('. ');
  }
}
