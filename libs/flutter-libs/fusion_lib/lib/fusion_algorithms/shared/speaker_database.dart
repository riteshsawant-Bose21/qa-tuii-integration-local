/// Legacy speaker database module for backward compatibility
/// 
/// This module re-exports speaker database from the API data layer
/// to maintain backward compatibility with existing algorithm code.

// Re-export speaker database from API data layer
export '../../api_data/speakers/speaker_catalog.dart';

// For direct backward compatibility, provide the legacy speakerDatabase constant
import '../../api_data/speakers/speaker_catalog.dart';

/// Legacy speaker database access - now delegates to API data layer
/// 
/// This maintains backward compatibility for existing algorithm code
/// while using the centralized speaker catalog from the API data layer.
const speakerDatabase = SpeakerCatalog.database;
