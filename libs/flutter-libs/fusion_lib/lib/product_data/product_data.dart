/// Product Data Module
///
/// An offline-first product data layer for Flutter applications.
/// Provides product data with local caching, version-based synchronization,
/// and image caching for offline access.
///
/// ## Features
/// - Offline-first product access
/// - Local JSON caching for fast data retrieval
/// - Version-based synchronization to minimize network usage
/// - Local image caching for offline image loading
/// - Repository Pattern with clean separation of concerns
///
/// ## Usage
/// ```dart
/// import 'package:fusion_lib/product_data/product_data.dart';
///
/// final repository = ProductRepository(baseUrl: 'http://localhost:8080');
/// final catalog = await repository.getProducts();
/// final speakers = await repository.getSpeakers();
/// ```

library product_data;

// Models
export 'models/models.dart';

// Data Sources
export 'data_sources/data_sources.dart';

// Services
export 'services/services.dart';

// Repository
export 'repository/repository.dart';
