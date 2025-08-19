/// Common validation utilities shared across fusion algorithms
/// Provides consistent validation patterns for different input types

/// Validates speaker model name
void validateSpeakerModel(String model, {String? context}) {
  if (model.trim().isEmpty) {
    throw ArgumentError('Speaker model cannot be empty${context != null ? ' ($context)' : ''}');
  }
}

/// Validates height values (speaker and listener heights)
void validateHeight(double height, String heightType, {String? context}) {
  if (height < 0) {
    throw ArgumentError('$heightType cannot be negative${context != null ? ' ($context)' : ''}');
  }
}

/// Validates voltage system (70V or 100V)
void validateVoltage(int voltage, {String? context}) {
  if (voltage != 70 && voltage != 100) {
    throw ArgumentError(
      'Invalid voltage $voltage${context != null ? ' ($context)' : ''}. '
      'Only 70V or 100V supported.'
    );
  }
}

/// Validates environment string
void validateEnvironment(String environment, {String? context}) {
  final validEnvironments = {'indoor', 'outdoor'};
  if (!validEnvironments.contains(environment.toLowerCase())) {
    throw ArgumentError(
      'Invalid environment: $environment${context != null ? ' ($context)' : ''}. '
      'Must be either "indoor" or "outdoor".'
    );
  }
}

/// Validates mounting type
void validateMountingType(String mountingType, {String? context}) {
  final validMountingTypes = {'surface', 'ceiling', 'pendant'};
  if (!validMountingTypes.contains(mountingType.toLowerCase().trim())) {
    throw ArgumentError(
      'Invalid mounting type: $mountingType${context != null ? ' ($context)' : ''}. '
      'Valid types: ${validMountingTypes.join(', ')}'
    );
  }
}

/// Validates SPL range (must have exactly 2 values, min < max)
void validateSplRange(List<double> splRange, {String? context}) {
  if (splRange.length != 2) {
    throw ArgumentError(
      'SPL range must contain exactly 2 values [min, max]${context != null ? ' ($context)' : ''}'
    );
  }
  
  if (splRange[0] >= splRange[1]) {
    throw ArgumentError(
      'SPL range minimum (${splRange[0]}) must be less than maximum (${splRange[1]})'
      '${context != null ? ' ($context)' : ''}'
    );
  }
}

/// Validates that a list is not empty
void validateNotEmpty<T>(List<T> list, String listType, {String? context}) {
  if (list.isEmpty) {
    throw ArgumentError(
      '$listType cannot be empty${context != null ? ' ($context)' : ''}'
    );
  }
}

/// Validates that a value is positive (greater than 0)
void validatePositive(double value, String valueType, {String? context}) {
  if (value <= 0) {
    throw ArgumentError(
      '$valueType must be positive${context != null ? ' ($context)' : ''}'
    );
  }
}

/// Validates that a value is non-negative (greater than or equal to 0)
void validateNonNegative(double value, String valueType, {String? context}) {
  if (value < 0) {
    throw ArgumentError(
      '$valueType cannot be negative${context != null ? ' ($context)' : ''}'
    );
  }
}

/// Common validation constants
class ValidationConstants {
  /// Valid voltage systems for distributed audio
  static const Set<int> validVoltages = {70, 100};
  
  /// Valid environment types
  static const Set<String> validEnvironments = {'indoor', 'outdoor'};
  
  /// Valid mounting types for speakers
  static const Set<String> validMountingTypes = {'surface', 'ceiling', 'pendant'};
  
  /// Minimum reasonable height in feet
  static const double minimumHeightFeet = 0.0;
  
  /// Maximum reasonable height in feet (for validation)
  static const double maximumHeightFeet = 100.0;
  
  /// Minimum reasonable SPL value in dB
  static const double minimumSplDb = 20.0;
  
  /// Maximum reasonable SPL value in dB
  static const double maximumSplDb = 150.0;
}

/// Enhanced validation with range checking
void validateHeightRange(double height, String heightType, {String? context}) {
  validateHeight(height, heightType, context: context);
  
  if (height > ValidationConstants.maximumHeightFeet) {
    throw ArgumentError(
      '$heightType ${height.toStringAsFixed(1)}ft seems unreasonably high '
      '(max: ${ValidationConstants.maximumHeightFeet}ft)'
      '${context != null ? ' ($context)' : ''}'
    );
  }
}

/// Enhanced SPL validation with reasonable range checking
void validateSplValue(double spl, String splType, {String? context}) {
  if (spl < ValidationConstants.minimumSplDb || spl > ValidationConstants.maximumSplDb) {
    throw ArgumentError(
      '$splType ${spl.toStringAsFixed(1)}dB is outside reasonable range '
      '(${ValidationConstants.minimumSplDb}-${ValidationConstants.maximumSplDb}dB)'
      '${context != null ? ' ($context)' : ''}'
    );
  }
}
