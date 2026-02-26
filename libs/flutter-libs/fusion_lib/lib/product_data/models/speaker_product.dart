import 'product_asset.dart';

/// Represents a frequency range with high and low values
class FrequencyRange {
  final int high;
  final int low;
  final String unit;

  const FrequencyRange({
    required this.high,
    required this.low,
    this.unit = 'Hz',
  });

  factory FrequencyRange.fromJson(Map<String, dynamic> json) {
    return FrequencyRange(
      high: (json['high'] as num?)?.toInt() ?? 0,
      low: (json['low'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'Hz',
    );
  }

  Map<String, dynamic> toJson() => {
        'high': high,
        'low': low,
        'unit': unit,
      };
}

/// Represents an impedance specification with high/low values
class ImpedanceSpec {
  final double high;
  final double low;
  final String unit;

  const ImpedanceSpec({
    required this.high,
    required this.low,
    this.unit = 'ohms',
  });

  factory ImpedanceSpec.fromJson(Map<String, dynamic> json) {
    return ImpedanceSpec(
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'ohms',
    );
  }

  Map<String, dynamic> toJson() => {
        'high': high,
        'low': low,
        'unit': unit,
      };
}

/// Represents a nominal impedance value
class NominalImpedance {
  final String unit;
  final double value;

  const NominalImpedance({
    this.unit = 'ohms',
    required this.value,
  });

  factory NominalImpedance.fromJson(Map<String, dynamic> json) {
    return NominalImpedance(
      unit: json['unit'] as String? ?? 'ohms',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'unit': unit,
        'value': value,
      };
}

/// Represents a measurement value with key, unit, and value
class MeasurementValue {
  final String key;
  final String unit;
  final double value;

  const MeasurementValue({
    required this.key,
    required this.unit,
    required this.value,
  });

  factory MeasurementValue.fromJson(Map<String, dynamic> json) {
    return MeasurementValue(
      key: json['key'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'unit': unit,
        'value': value,
      };
}

/// Represents max SPL specification
class MaxSpl {
  final List<MeasurementValue> at;
  final String unit;

  const MaxSpl({
    required this.at,
    this.unit = 'dB',
  });

  factory MaxSpl.fromJson(Map<String, dynamic> json) {
    return MaxSpl(
      at: (json['at'] as List<dynamic>?)
              ?.map((e) => MeasurementValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unit: json['unit'] as String? ?? 'dB',
    );
  }

  Map<String, dynamic> toJson() => {
        'at': at.map((e) => e.toJson()).toList(),
        'unit': unit,
      };
}

/// Represents sensitivity specification
class Sensitivity {
  final List<MeasurementValue> at;
  final String unit;

  const Sensitivity({
    required this.at,
    this.unit = 'dB',
  });

  factory Sensitivity.fromJson(Map<String, dynamic> json) {
    return Sensitivity(
      at: (json['at'] as List<dynamic>?)
              ?.map((e) => MeasurementValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unit: json['unit'] as String? ?? 'dB',
    );
  }

  Map<String, dynamic> toJson() => {
        'at': at.map((e) => e.toJson()).toList(),
        'unit': unit,
      };
}

/// Represents power handling specification
class PowerHandling {
  final double longTermRms;
  final double peak;
  final String unit;

  const PowerHandling({
    required this.longTermRms,
    required this.peak,
    this.unit = 'Watts',
  });

  factory PowerHandling.fromJson(Map<String, dynamic> json) {
    return PowerHandling(
      longTermRms: (json['long_term_rms'] as num?)?.toDouble() ?? 0.0,
      peak: (json['peak'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'Watts',
    );
  }

  Map<String, dynamic> toJson() => {
        'long_term_rms': longTermRms,
        'peak': peak,
        'unit': unit,
      };
}

/// Represents available taps configuration for speakers
class AvailableTaps {
  final List<double> taps100V;
  final List<double> taps70V;

  const AvailableTaps({
    required this.taps100V,
    required this.taps70V,
  });

  factory AvailableTaps.fromJson(Map<String, dynamic> json) {
    return AvailableTaps(
      taps100V: (json['100v'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      taps70V: (json['70v'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        '100v': taps100V,
        '70v': taps70V,
      };
}

/// Represents coverage pattern specification
class Coverage {
  final FrequencyRange? frequencyRange;
  final int horizontalDeg;
  final String type;
  final int verticalDeg;

  const Coverage({
    this.frequencyRange,
    required this.horizontalDeg,
    required this.type,
    required this.verticalDeg,
  });

  factory Coverage.fromJson(Map<String, dynamic> json) {
    final freqRangeJson = json['frequency_range'] as Map<String, dynamic>?;
    FrequencyRange? freqRange;

    if (freqRangeJson != null) {
      final highJson = freqRangeJson['high'];
      final lowJson = freqRangeJson['low'];

      if (highJson is Map<String, dynamic>) {
        freqRange = FrequencyRange(
          high: (highJson['value'] as num?)?.toInt() ?? 0,
          low: (lowJson is Map<String, dynamic>)
              ? (lowJson['value'] as num?)?.toInt() ?? 0
              : 0,
          unit: highJson['unit'] as String? ?? 'Hz',
        );
      } else {
        freqRange = FrequencyRange.fromJson(freqRangeJson);
      }
    }

    return Coverage(
      frequencyRange: freqRange,
      horizontalDeg: (json['horizontal_deg'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      verticalDeg: (json['vertical_deg'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'frequency_range': frequencyRange?.toJson(),
        'horizontal_deg': horizontalDeg,
        'type': type,
        'vertical_deg': verticalDeg,
      };
}

/// Speaker product model
///
/// Represents a speaker product from the product catalog API.
/// Field names follow the README specification.
class SpeakerProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final AvailableTaps? availableTaps;
  final String? bsfFileUrl;
  final List<Coverage> coverage;
  final String? environment;
  final FrequencyRange? frequencyRange;
  final List<double> highImpedanceTaps;
  final ImpedanceSpec? impedance;
  final bool isHighImpedanceRated;
  final bool isSubwoofer;
  final bool isWeatherRated;
  final MaxSpl? maxSpl;
  final String? mountType;
  final NominalImpedance? nominalImpedance;
  final PowerHandling? powerHandling;
  final Sensitivity? sensitivity;
  final String? shortDescription;
  final List<int> skus;
  final bool isFusionCompatible;

  const SpeakerProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.availableTaps,
    this.bsfFileUrl,
    this.coverage = const [],
    this.environment,
    this.frequencyRange,
    this.highImpedanceTaps = const [],
    this.impedance,
    this.isHighImpedanceRated = false,
    this.isSubwoofer = false,
    this.isWeatherRated = false,
    this.maxSpl,
    this.mountType,
    this.nominalImpedance,
    this.powerHandling,
    this.sensitivity,
    this.shortDescription,
    this.skus = const [],
    this.isFusionCompatible = false,
  });

  factory SpeakerProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return SpeakerProduct(
      productId: (json['productid'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'speaker'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'Professional speaker delivering exceptional audio quality',
      availableTaps: specs['available_taps'] != null
          ? AvailableTaps.fromJson(
              specs['available_taps'] as Map<String, dynamic>)
          : null,
      bsfFileUrl: specs['bsf_file_url'] as String?,
      coverage: (specs['coverage'] as List<dynamic>?)
              ?.map((e) => Coverage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      environment: specs['environment'] as String?,
      frequencyRange: specs['frequency_range'] != null
          ? FrequencyRange.fromJson(
              specs['frequency_range'] as Map<String, dynamic>)
          : null,
      highImpedanceTaps: (specs['high_impedance_taps'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      impedance: specs['impedance'] != null
          ? ImpedanceSpec.fromJson(specs['impedance'] as Map<String, dynamic>)
          : null,
      isHighImpedanceRated: specs['is_high_impedance_rated'] as bool? ?? false,
      isSubwoofer: specs['is_subwoofer'] as bool? ?? false,
      isWeatherRated: specs['is_weather_rated'] as bool? ?? false,
      maxSpl: specs['max_spl'] != null
          ? MaxSpl.fromJson(specs['max_spl'] as Map<String, dynamic>)
          : null,
      mountType: specs['mount_type'] as String?,
      nominalImpedance: specs['nominal_impedance'] != null
          ? NominalImpedance.fromJson(
              specs['nominal_impedance'] as Map<String, dynamic>)
          : null,
      powerHandling: specs['power_handling'] != null
          ? PowerHandling.fromJson(
              specs['power_handling'] as Map<String, dynamic>)
          : null,
      sensitivity: specs['sensitivity'] != null
          ? Sensitivity.fromJson(specs['sensitivity'] as Map<String, dynamic>)
          : null,
      shortDescription: specs['short_description'] as String?,
      skus: (specs['skus'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'productid': productId,
        'assets': [assets.toJson()],
        'model_name': modelName,
        'model_family': modelFamily,
        'description': description,
        'specifications': {
          if (availableTaps != null) 'available_taps': availableTaps!.toJson(),
          if (bsfFileUrl != null) 'bsf_file_url': bsfFileUrl,
          'coverage': coverage.map((e) => e.toJson()).toList(),
          if (environment != null) 'environment': environment,
          if (frequencyRange != null)
            'frequency_range': frequencyRange!.toJson(),
          'high_impedance_taps': highImpedanceTaps,
          if (impedance != null) 'impedance': impedance!.toJson(),
          'is_high_impedance_rated': isHighImpedanceRated,
          'is_subwoofer': isSubwoofer,
          'is_weather_rated': isWeatherRated,
          if (maxSpl != null) 'max_spl': maxSpl!.toJson(),
          if (mountType != null) 'mount_type': mountType,
          if (nominalImpedance != null)
            'nominal_impedance': nominalImpedance!.toJson(),
          if (powerHandling != null) 'power_handling': powerHandling!.toJson(),
          if (sensitivity != null) 'sensitivity': sensitivity!.toJson(),
          if (shortDescription != null) 'short_description': shortDescription,
          'skus': skus,
        },
        'is_fusion_compatible': isFusionCompatible,
      };

  @override
  String toString() =>
      'SpeakerProduct(productId: $productId, modelName: $modelName)';
}
