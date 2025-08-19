/// Amplifier Matching Algorithm - Dart Implementation
/// 
/// This is a complete port of the 12-step amplifier matching algorithm
/// from the Go implementation, including all power sharing optimization
/// features and smart channel allocation strategies.

import 'dart:math' as math;
import '../../api_data/speakers/speakers.dart';
import '../../api_data/amplifiers/amplifiers.dart';
import 'amp_matching_types.dart';

/// Exception thrown when amplifier matching fails
class AmpMatchingException implements Exception {
  final String message;
  const AmpMatchingException(this.message);
  
  @override
  String toString() => 'AmpMatchingException: $message';
}

/// Main Amplifier Matching Algorithm Implementation
class AmplifierMatcher {
  /// Matches circuits to amplifiers using the 12-step algorithm with power sharing optimization
  /// 
  /// [circuits] - List of audio circuits to be matched
  /// [speakerDatabase] - Database of speaker specifications
  /// 
  /// Returns [AmpMatchingResult] with optimized amplifier assignments
  static Future<AmpMatchingResult> matchAmplifiers(
    List<Circuit> circuits,
    Map<String, Speaker> speakerDatabase,
  ) async {
    if (circuits.isEmpty) {
      throw const AmpMatchingException('No circuits provided for matching');
    }

    // Step 1-3: Compute required Ppk for each circuit and sort
    final computedCircuits = _computeAndSortCircuits(circuits, speakerDatabase);
    
    // Step 4-5: Initial amplifier allocation using tier rule
    final initialAssignments = _initialAmpAllocation(computedCircuits);
    
    // Step 6-12: Apply power sharing optimization
    final optimizedAssignments = _applyPowerSharingOptimization(initialAssignments, speakerDatabase);
    
    // Calculate final metrics and create result
    return _createMatchingResult(optimizedAssignments, computedCircuits);
  }

  /// Steps 1-3: Compute required peak power (Ppk) for each circuit and sort by power descending
  static List<CircuitWithPower> _computeAndSortCircuits(
    List<Circuit> circuits,
    Map<String, Speaker> speakerDatabase,
  ) {
    final List<CircuitWithPower> computed = [];

    for (final circuit in circuits) {
      final speakerSpec = speakerDatabase[circuit.model];
      if (speakerSpec == null) {
        throw AmpMatchingException('Speaker model ${circuit.model} not found in database');
      }

      double ppk = 0.0;

      switch (circuit.mode.toLowerCase()) {
        case 'hi-z':
          // High impedance calculation: Use tap watts
          double tapWatts = circuit.tapWatts;
          if (tapWatts == 0.0 && speakerSpec.hiZTaps.isNotEmpty) {
            tapWatts = speakerSpec.hiZTaps.first;
          }
          if (circuit.speakerCount <= 0) {
            throw AmpMatchingException('Speaker count required for circuit ${circuit.circuitId}');
          }
          final rmsTotal = tapWatts * circuit.speakerCount;
          ppk = rmsTotal * 2.0; // RMS to peak conversion
          break;

        case 'lo-z':
          // Low impedance calculation: Use speaker Ppk
          if (circuit.speakerCount <= 0) {
            throw AmpMatchingException('Speaker count required for circuit ${circuit.circuitId}');
          }
          ppk = speakerSpec.ppk * circuit.speakerCount;
          
          // Validate impedance
          final totalImpedance = speakerSpec.nominalOhms / circuit.speakerCount;
          if (totalImpedance < 4.0) {
            throw AmpMatchingException(
              'Circuit ${circuit.circuitId} impedance too low: ${totalImpedance.toStringAsFixed(2)} Ω'
            );
          }
          break;

        default:
          throw AmpMatchingException('Unknown circuit mode: ${circuit.mode}');
      }

      // Apply output offset attenuation if specified
      if (circuit.outputOffsetDb > 0) {
        ppk = ppk * math.pow(10, -circuit.outputOffsetDb / 10.0);
      }

      computed.add(CircuitWithPower(circuit: circuit, requiredPpk: ppk));
    }

    // Step 2: Sort by required power (descending order)
    computed.sort((a, b) => b.requiredPpk.compareTo(a.requiredPpk));

    return computed;
  }

  /// Steps 4-5: Initial amplifier allocation using tier rule with smart channel allocation
  static List<AmpAssignment> _initialAmpAllocation(
    List<CircuitWithPower> computedCircuits,
  ) {
    final List<AmpAssignment> assignments = [];
    AmpAssignment? currentAmp;
    int channelsNeeded = computedCircuits.length;

    for (final circuitWithPower in computedCircuits) {
      // Choose amplifier using tier rule
      final ampModel = _chooseAmpByTierRule(circuitWithPower.requiredPpk);
      
      // Apply smart channel strategy for optimal allocation
      final optimizedAmpModel = _applySmartChannelStrategy(
        ampModel, 
        channelsNeeded, 
        assignments.length,
        assignments,
      );

      // Create new amplifier assignment if needed
      if (currentAmp == null || 
          currentAmp.ampModel.name != optimizedAmpModel.name ||
          currentAmp.circuits.length >= optimizedAmpModel.channels) {
        currentAmp = AmpAssignment(
          ampModel: optimizedAmpModel,
          circuits: [],
        );
        assignments.add(currentAmp);
      }

      // Add circuit to current amplifier
      final updatedCircuits = List<Circuit>.from(currentAmp.circuits)
        ..add(circuitWithPower.circuit);
      
      currentAmp = AmpAssignment(
        ampModel: currentAmp.ampModel,
        circuits: updatedCircuits,
      );
      
      assignments[assignments.length - 1] = currentAmp;
      channelsNeeded--;
    }

    return assignments;
  }

  /// Apply smart channel allocation strategy: 4→8→4+4→8+8 pattern
  static AmpModel _applySmartChannelStrategy(
    AmpModel baseModel,
    int channelsRemaining,
    int existingAmpsCount,
    List<AmpAssignment> existingAssignments,
  ) {
    int totalChannelsAllocated = 0;

    // Count existing channels from actual assignments
    for (int i = 0; i < existingAmpsCount && i < existingAssignments.length; i++) {
      totalChannelsAllocated += existingAssignments[i].ampModel.channels;
    }

    final totalChannelsNeeded = totalChannelsAllocated + channelsRemaining;

    // Apply strategy based on total channel requirements
    if (totalChannelsNeeded <= 4) {
      return _find4ChannelVariant(baseModel);
    } else if (totalChannelsNeeded <= 8) {
      return _find8ChannelVariant(baseModel);
    } else if (totalChannelsNeeded <= 12) {
      // 8 + 4 pattern
      return existingAmpsCount == 0 
          ? _find8ChannelVariant(baseModel)
          : _find4ChannelVariant(baseModel);
    } else {
      // 8 + 8 pattern for 13+ channels
      return _find8ChannelVariant(baseModel);
    }
  }

  /// Find 4-channel variant of the given amplifier power tier
  static AmpModel _find4ChannelVariant(AmpModel baseModel) {
    final variant = AmpCatalog.models.where((amp) =>
        amp.peakPerChannel == baseModel.peakPerChannel && amp.channels == 4);
    return variant.isNotEmpty ? variant.first : baseModel;
  }

  /// Find 8-channel variant of the given amplifier power tier
  static AmpModel _find8ChannelVariant(AmpModel baseModel) {
    final variant = AmpCatalog.models.where((amp) =>
        amp.peakPerChannel == baseModel.peakPerChannel && amp.channels == 8);
    return variant.isNotEmpty ? variant.first : baseModel;
  }

  /// Steps 6-12: Apply power sharing optimization algorithm
  static List<AmpAssignment> _applyPowerSharingOptimization(
    List<AmpAssignment> assignments,
    Map<String, Speaker> speakerDatabase,
  ) {
    // Step 6: Run each amplifier through simplified power sharing calculator
    final List<PowerSharingInfo> powerSharingInfo = [];
    
    for (int i = 0; i < assignments.length; i++) {
      final info = _calculatePowerSharing(assignments[i], i, speakerDatabase);
      powerSharingInfo.add(info);
    }

    // Step 7-8: Identify and optimize channel allocation using power sharing
    final optimizedAssignments = _optimizeChannelAllocation(
      assignments, 
      powerSharingInfo,
      speakerDatabase,
    );

    // Step 11-12: Final validation and SKU reduction
    final finalAssignments = _validateAndReduceSKUs(optimizedAssignments, speakerDatabase);

    return finalAssignments;
  }

  /// Calculate power sharing analysis for an amplifier
  static PowerSharingInfo _calculatePowerSharing(
    AmpAssignment assignment,
    int ampIndex,
    Map<String, Speaker> speakerDatabase,
  ) {
    final channelLoads = List<double>.filled(assignment.ampModel.channels, 0.0);

    // Calculate actual load on each used channel
    for (int i = 0; i < assignment.circuits.length && i < channelLoads.length; i++) {
      final circuit = assignment.circuits[i];
      
      // Calculate circuit power based on mode
      double circuitPower = 0.0;
      
      if (circuit.mode.toLowerCase() == 'hi-z') {
        circuitPower = circuit.tapWatts * circuit.speakerCount * 2.0; // RMS to peak
      } else {
        // For lo-z, use actual speaker specification
        final speakerSpec = speakerDatabase[circuit.model];
        if (speakerSpec != null) {
          circuitPower = speakerSpec.ppk * circuit.speakerCount;
        } else {
          // Fallback to placeholder if speaker not found
          circuitPower = 100.0 * circuit.speakerCount;
        }
      }

      // Apply output offset attenuation
      if (circuit.outputOffsetDb > 0) {
        circuitPower = circuitPower * math.pow(10, -circuit.outputOffsetDb / 10.0);
      }

      channelLoads[i] = circuitPower;
    }

    // Calculate net power sharing (available power that can be shared)
    final symmetricalRating = assignment.ampModel.peakPerChannel;
    final totalUsedPower = channelLoads.fold<double>(0.0, (sum, load) => sum + load);
    final totalAvailablePower = assignment.ampModel.channels * symmetricalRating;
    final netPowerSharing = math.max(0.0, totalAvailablePower - totalUsedPower);

    return PowerSharingInfo(
      ampIndex: ampIndex,
      usedChannels: assignment.circuits.length,
      netPowerSharing: netPowerSharing,
      channelLoads: channelLoads,
    );
  }

  /// Optimize channel allocation by redistributing circuits across amplifiers
  static List<AmpAssignment> _optimizeChannelAllocation(
    List<AmpAssignment> assignments,
    List<PowerSharingInfo> powerInfo,
    Map<String, Speaker> speakerDatabase,
  ) {
    // Create list of movable circuits with their power requirements
    final List<_MovableCircuit> movableCircuits = [];

    for (int ampIdx = 0; ampIdx < assignments.length; ampIdx++) {
      final assignment = assignments[ampIdx];
      
      for (int circuitIdx = 0; circuitIdx < assignment.circuits.length; circuitIdx++) {
        final circuit = assignment.circuits[circuitIdx];
        
        // Calculate circuit power for ranking
        double power = 0.0;
        if (circuit.mode.toLowerCase() == 'hi-z') {
          power = circuit.tapWatts * circuit.speakerCount * 2.0;
        } else {
          // Use actual speaker spec for lo-z
          final speakerSpec = speakerDatabase[circuit.model];
          if (speakerSpec != null) {
            power = speakerSpec.ppk * circuit.speakerCount;
          } else {
            power = 100.0 * circuit.speakerCount; // Fallback
          }
        }

        if (circuit.outputOffsetDb > 0) {
          power = power * math.pow(10, -circuit.outputOffsetDb / 10.0);
        }

        movableCircuits.add(_MovableCircuit(
          circuitIndex: circuitIdx,
          ampIndex: ampIdx,
          power: power,
          circuit: circuit,
        ));
      }
    }

    // Sort circuits by power (highest first) for optimal movement priority
    movableCircuits.sort((a, b) => b.power.compareTo(a.power));

    // Create optimized assignments starting from current state
    final optimizedAssignments = assignments.map((a) => AmpAssignment(
      ampModel: a.ampModel,
      circuits: List<Circuit>.from(a.circuits),
    )).toList();

    final workingPowerInfo = powerInfo.map((info) => PowerSharingInfo(
      ampIndex: info.ampIndex,
      usedChannels: info.usedChannels,
      netPowerSharing: info.netPowerSharing,
      channelLoads: List<double>.from(info.channelLoads),
    )).toList();

    // Attempt to move circuits to optimize power usage
    final Set<int> processedCircuits = <int>{};
    
    for (int i = 0; i < movableCircuits.length; i++) {
      if (processedCircuits.contains(i)) continue;
      
      final movableCircuit = movableCircuits[i];
      final currentAmpIdx = movableCircuit.ampIndex;
      final currentAmpPower = assignments[currentAmpIdx].ampModel.peakPerChannel;

      // Look for lower-power amplifier that can accommodate this circuit
      for (int targetAmpIdx = 0; targetAmpIdx < workingPowerInfo.length; targetAmpIdx++) {
        final targetInfo = workingPowerInfo[targetAmpIdx];
        final targetAmpPower = assignments[targetAmpIdx].ampModel.peakPerChannel;

        // Only move to lower-power amps with available capacity
        if (targetAmpPower < currentAmpPower &&
            targetInfo.netPowerSharing >= movableCircuit.power &&
            optimizedAssignments[targetAmpIdx].circuits.length < 
            assignments[targetAmpIdx].ampModel.channels) {

          // Find and remove the specific circuit (not by index)
          final circuitToMove = movableCircuit.circuit;
          final sourceCircuits = optimizedAssignments[currentAmpIdx].circuits;
          final initialLength = sourceCircuits.length;
          sourceCircuits.removeWhere((c) => c.circuitId == circuitToMove.circuitId);
          final circuitFound = sourceCircuits.length < initialLength;

          if (circuitFound) {
            // Move the circuit
            optimizedAssignments[targetAmpIdx].circuits.add(circuitToMove);

            // Update power sharing information
            workingPowerInfo[targetAmpIdx] = PowerSharingInfo(
              ampIndex: targetInfo.ampIndex,
              usedChannels: targetInfo.usedChannels + 1,
              netPowerSharing: targetInfo.netPowerSharing - movableCircuit.power,
              channelLoads: targetInfo.channelLoads,
            );

            workingPowerInfo[currentAmpIdx] = PowerSharingInfo(
              ampIndex: workingPowerInfo[currentAmpIdx].ampIndex,
              usedChannels: workingPowerInfo[currentAmpIdx].usedChannels - 1,
              netPowerSharing: workingPowerInfo[currentAmpIdx].netPowerSharing + movableCircuit.power,
              channelLoads: workingPowerInfo[currentAmpIdx].channelLoads,
            );

            processedCircuits.add(i);
            break; // Circuit successfully moved
          }
        }
      }
    }

    return optimizedAssignments;
  }

  /// Steps 11-12: Final validation and SKU reduction
  static List<AmpAssignment> _validateAndReduceSKUs(
    List<AmpAssignment> assignments,
    Map<String, Speaker> speakerDatabase,
  ) {
    final List<AmpAssignment> finalAssignments = [];

    for (final assignment in assignments) {
      // Skip empty assignments
      if (assignment.circuits.isEmpty) {
        continue;
      }

      // Step 11: Find maximum circuit power requirement
      double maxCircuitPower = 0.0;
      for (final circuit in assignment.circuits) {
        double power = 0.0;
        
        if (circuit.mode.toLowerCase() == 'hi-z') {
          power = circuit.tapWatts * circuit.speakerCount * 2.0;
        } else {
          // Use actual speaker spec for lo-z
          final speakerSpec = speakerDatabase[circuit.model];
          if (speakerSpec != null) {
            power = speakerSpec.ppk * circuit.speakerCount;
          } else {
            power = 100.0 * circuit.speakerCount; // Fallback
          }
        }

        if (circuit.outputOffsetDb > 0) {
          power = power * math.pow(10, -circuit.outputOffsetDb / 10.0);
        }

        if (power > maxCircuitPower) {
          maxCircuitPower = power;
        }
      }

      // Check if current amplifier satisfies tier rule
      final currentAmp = assignment.ampModel;
      bool validTier = _validateTierRule(currentAmp, maxCircuitPower);

      // Step 12: If not valid, try to reduce to lower tier
      AmpModel finalAmp = currentAmp;
      if (!validTier) {
        final reducedAmp = _findLowerTierAmp(currentAmp, maxCircuitPower);
        if (reducedAmp != null) {
          finalAmp = reducedAmp;
        } else {
          throw AmpMatchingException(
            'Cannot find suitable amplifier tier for power requirement ${maxCircuitPower.toStringAsFixed(2)}W'
          );
        }
      }

      finalAssignments.add(AmpAssignment(
        ampModel: finalAmp,
        circuits: assignment.circuits,
      ));
    }

    return finalAssignments;
  }

  /// Validate if amplifier satisfies tier rule for given power requirement
  static bool _validateTierRule(AmpModel amp, double requiredPower) {
    final sortedCatalog = AmpCatalog.sortedByPower;
    
    for (int i = 0; i < sortedCatalog.length; i++) {
      final current = sortedCatalog[i];
      if (current.name != amp.name) continue;

      final double nextTierPower = (i < sortedCatalog.length - 1)
          ? sortedCatalog[i + 1].peakPerChannel
          : double.infinity;

      // Check tier rule: nextTierPower ≥ requiredPower ≥ currentTierPower
      return requiredPower >= current.peakPerChannel && requiredPower <= nextTierPower;
    }

    return false;
  }

  /// Find lowest suitable amplifier tier for the given power requirement
  static AmpModel? _findLowerTierAmp(AmpModel currentAmp, double requiredPower) {
    // Find amplifiers with same channel count as current
    final sameChannelAmps = AmpCatalog.models
        .where((amp) => amp.channels == currentAmp.channels)
        .toList();

    // Sort by power (ascending)
    sameChannelAmps.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));

    // Find lowest power amplifier that can handle the requirement
    for (final amp in sameChannelAmps) {
      if (amp.peakPerChannel >= requiredPower) {
        return amp;
      }
    }

    return null; // No suitable lower tier found
  }

  /// Choose amplifier model based on tier rule from specification
  static AmpModel _chooseAmpByTierRule(double requiredPpk) {
    final sortedCatalog = AmpCatalog.sortedByPower;

    // Find appropriate tier using spec's rule:
    // nextTierPower ≥ requiredPower ≥ currentTierPower
    for (int i = 0; i < sortedCatalog.length; i++) {
      final current = sortedCatalog[i];
      final double nextTierPower = (i < sortedCatalog.length - 1)
          ? sortedCatalog[i + 1].peakPerChannel
          : double.infinity;

      // If required power is between current and next tier, choose next tier
      if (requiredPpk >= current.peakPerChannel && requiredPpk < nextTierPower) {
        return (i < sortedCatalog.length - 1) ? sortedCatalog[i + 1] : current;
      }
    }

    // Edge cases
    if (requiredPpk < sortedCatalog.first.peakPerChannel) {
      return sortedCatalog.first; // Choose smallest if requirement is very low
    }

    return sortedCatalog.last; // Choose largest if requirement exceeds all
  }

  /// Create final matching result with all metrics and analysis
  static AmpMatchingResult _createMatchingResult(
    List<AmpAssignment> assignments,
    List<CircuitWithPower> computedCircuits,
  ) {
    final totalPowerRequirement = computedCircuits
        .fold<double>(0.0, (sum, circuit) => sum + circuit.requiredPpk);
    
    final totalSystemCapacity = assignments
        .fold<double>(0.0, (sum, assignment) => sum + assignment.totalCapacity);
    
    final totalChannelsUsed = assignments
        .fold<int>(0, (sum, assignment) => sum + assignment.usedChannels);
    
    final totalChannelsAvailable = assignments
        .fold<int>(0, (sum, assignment) => sum + assignment.totalChannels);

    // Generate optimization notes
    final StringBuffer notes = StringBuffer();
    if (assignments.length == 1) {
      notes.write('Single amplifier solution achieved. ');
    }
    
    final powerEfficiency = totalPowerRequirement / totalSystemCapacity;
    if (powerEfficiency > 0.8) {
      notes.write('High power efficiency (${(powerEfficiency * 100).toStringAsFixed(1)}%). ');
    } else if (powerEfficiency < 0.3) {
      notes.write('Consider power sharing optimization opportunities. ');
    }
    
    final channelEfficiency = totalChannelsUsed / totalChannelsAvailable;
    if (channelEfficiency > 0.75) {
      notes.write('Good channel utilization (${(channelEfficiency * 100).toStringAsFixed(1)}%).');
    }

    return AmpMatchingResult(
      assignments: assignments,
      totalPowerRequirement: totalPowerRequirement,
      totalSystemCapacity: totalSystemCapacity,
      totalChannelsUsed: totalChannelsUsed,
      totalChannelsAvailable: totalChannelsAvailable,
      optimizationNotes: notes.toString(),
    );
  }
}

/// Helper class for circuit movement during optimization
class _MovableCircuit {
  final int circuitIndex;
  final int ampIndex;
  final double power;
  final Circuit circuit;

  const _MovableCircuit({
    required this.circuitIndex,
    required this.ampIndex,
    required this.power,
    required this.circuit,
  });
}
