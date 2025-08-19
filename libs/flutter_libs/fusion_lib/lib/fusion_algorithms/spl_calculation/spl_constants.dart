/// SPL calculation constants
/// Re-exports speaker database from API data layer and adds SPL-specific constants

// Re-export speaker database from API data layer
export '../../api_data/speakers/speakers.dart';
// Also export the legacy speakerDatabase constant for backward compatibility
export '../shared/speaker_database.dart';
