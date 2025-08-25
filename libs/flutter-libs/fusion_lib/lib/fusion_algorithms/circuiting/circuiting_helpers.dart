/// Circuiting algorithm helper functions
/// Ported from Go fusion-algo circuiting package

import 'dart:developer' as developer;

import '../../api_data/speakers/speakers.dart';
import 'circuiting_types.dart';

/// Key for grouping speakers by area and model
class AreaModelKey {
  final String area;
  final String model;

  const AreaModelKey(this.area, this.model);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AreaModelKey && runtimeType == other.runtimeType && area == other.area && model == other.model;

  @override
  int get hashCode => area.hashCode ^ model.hashCode;

  @override
  String toString() => 'AreaModelKey($area, $model)';
}

/// Calculates total impedance for speakers in parallel using Ωtotal = 1 / ( ∑ 1 / Z )
double calculateParallelImpedance(List<double> impedances) {
  if (impedances.isEmpty) {
    return 0.0;
  }

  double sum = 0.0;
  for (final z in impedances) {
    if (z <= 0) {
      return 0.0; // invalid impedance
    }
    sum += 1.0 / z;
  }

  if (sum == 0) {
    return 0.0;
  }

  return 1.0 / sum;
}

/// Groups input speakers into circuits by Area + Model
Map<AreaModelKey, List<InputSpeaker>> groupSpeakersByAreaModel(List<InputSpeaker> speakers) {
  final grouped = <AreaModelKey, List<InputSpeaker>>{};

  for (final speaker in speakers) {
    final key = AreaModelKey(speaker.area, speaker.model);
    grouped.putIfAbsent(key, () => <InputSpeaker>[]).add(speaker);
  }

  return grouped;
}

/// Gets speaker specification from the shared database
/// Returns null if speaker model not found
SpeakerModel? getSpeakerSpecFromSharedDb(String model) {
  return SpeakerCatalog.findByModel(model);
}

/// Logs a message with step formatting for debugging
void logStep(String message) {
  developer.log(message, name: 'Circuiting');
}
