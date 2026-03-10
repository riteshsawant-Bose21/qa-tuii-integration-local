/// Amplifier Catalog
/// 
/// Contains the complete catalog of amplifiers with both symmetrical and asymmetrical power specifications.
/// Each amplifier has:
/// - Symmetrical: Fixed power per channel that cannot be shared
/// - Asymmetrical: Power that can be shared across channels
/// - Total Capacity: Maximum power the amplifier can deliver

import 'amplifier_types.dart';

/// Complete catalog of amplifier models
class AmplifierCatalog {
  // Total amplifier capacities
  static const PSX1204D_TOTAL_CAPACITY = 2400; // Watts
  static const PSX2404D_TOTAL_CAPACITY = 4800; // Watts
  static const PSX4804D_TOTAL_CAPACITY = 9600; // Watts

  /// PSX1204D Model
  /// - Channels: 4
  /// - Symmetrical: 600W per channel (2400W total)
  /// - Asymmetrical: 2200W shareable power
  /// - Total Capacity: 2400W
  static const AmplifierModel psx1204d = AmplifierModel(
    name: 'PSX1204D',
    channels: 4,
    symmetrical: PowerSpec(
      watts: 600,
      channelInfo: 'per channel',
      totalCapacity: PSX1204D_TOTAL_CAPACITY,
    ),
    asymmetrical: PowerSpec(
      watts: 2200,
      channelInfo: 'shareable total',
      totalCapacity: PSX1204D_TOTAL_CAPACITY,
    ),
  );

  /// PSX2404D Model
  /// - Channels: 4
  /// - Symmetrical: 1200W per channel (4800W total)
  /// - Asymmetrical: 3400W shareable power
  /// - Total Capacity: 4800W
  static const AmplifierModel psx2404d = AmplifierModel(
    name: 'PSX2404D',
    channels: 4,
    symmetrical: PowerSpec(
      watts: 1200,
      channelInfo: 'per channel',
      totalCapacity: PSX2404D_TOTAL_CAPACITY,
    ),
    asymmetrical: PowerSpec(
      watts: 3400,
      channelInfo: 'shareable total',
      totalCapacity: PSX2404D_TOTAL_CAPACITY,
    ),
  );

  /// PSX4804D Model
  /// - Channels: 4
  /// - Symmetrical: 2400W per channel (9600W total)
  /// - Asymmetrical: 4200W shareable power
  /// - Total Capacity: 9600W
  static const AmplifierModel psx4804d = AmplifierModel(
    name: 'PSX4804D',
    channels: 4,
    symmetrical: PowerSpec(
      watts: 2400,
      channelInfo: 'per channel',
      totalCapacity: PSX4804D_TOTAL_CAPACITY,
    ),
    asymmetrical: PowerSpec(
      watts: 4200,
      channelInfo: 'shareable total',
      totalCapacity: PSX4804D_TOTAL_CAPACITY,
    ),
  );

  /// Get all available amplifier models
  static List<AmplifierModel> getAllAmplifiers() {
    return <AmplifierModel>[
      psx1204d,
      psx2404d,
      psx4804d,
    ];
  }

  /// Get all amplifier models as a static list
  static const List<AmplifierModel> allModels = <AmplifierModel>[
    psx1204d,
    psx2404d,
    psx4804d,
  ];
}

// // Example usage
// void main() {
//   // Print all models
//   print('Amplifier Catalog\n${'=' * 40}');
//   for (final model in AmplifierCatalog.allModels) {
//     print('\n$model');
//   }

//   // Find specific model
//   print('\n${'=' * 40}');
//   final model = AmplifierCatalog.getByModelNumber('PSX2404D');
//   if (model != null) {
//     print('\nFound model: ${model.name}');
//     print('Symmetrical mode: ${model.getPowerSpec(PowerMode.symmetrical)}');
//     print('Asymmetrical mode: ${model.getPowerSpec(PowerMode.asymmetrical)}');
//   }
// }