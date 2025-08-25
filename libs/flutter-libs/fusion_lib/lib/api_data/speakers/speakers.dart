/// Speaker API Data Module
/// 
/// This module exports all speaker-related data structures and catalogs
/// that would typically be fetched from a product catalog API.

library speaker_api_data;

import 'dart:convert';
import 'speaker_catalog.dart';

export 'speaker_types.dart';
export 'speaker_catalog.dart';

/// Returns all speakers as a JSON string
String getAllSpeakersCatalog() {
	final speakers = SpeakerCatalog.database.values.map((s) => s.toJson()).toList();
	return jsonEncode(speakers);
}
