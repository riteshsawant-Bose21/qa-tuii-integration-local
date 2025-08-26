/// SPL calculation fusion_acoustic_calculation_engine
/// Re-exports speaker database from API data layer and adds SPL-specific fusion_acoustic_calculation_engine

// Re-export speaker database from API data layer
export '../../api_data/speakers/speakers.dart';
// Also export the legacy speakerDatabase constant for backward compatibility
export '../shared/speaker_database.dart';
