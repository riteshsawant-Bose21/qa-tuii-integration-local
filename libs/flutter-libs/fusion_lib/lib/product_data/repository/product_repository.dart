import '../data_sources/data_sources.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Product Repository
///
/// Provides a unified, offline-first API for accessing product data.
/// Orchestrates remote/local data sources and image caching.
///
/// ## Usage
/// ```dart
/// final repository = ProductRepository(baseUrl: 'http://localhost:8080');
/// final catalog = await repository.getProducts();
/// ```
class ProductRepository {
  final ProductLocalDataSource _localDataSource;
  final ProductRemoteDataSource _remoteDataSource;
  final ProductImageCacheService _imageCacheService;

  ProductRepository({
    required String baseUrl,
    ProductLocalDataSource? localDataSource,
    ProductRemoteDataSource? remoteDataSource,
    ProductImageCacheService? imageCacheService,
  })  : _localDataSource = localDataSource ?? ProductLocalDataSource(),
        _remoteDataSource =
            remoteDataSource ?? ProductRemoteDataSource(baseUrl: baseUrl),
        _imageCacheService = imageCacheService ??
            ProductImageCacheService(
              localDataSource: localDataSource ?? ProductLocalDataSource(),
            );

  /// Get product catalog with offline-first strategy
  ///
  /// Workflow:
  /// 1. Check network status
  /// 2. If offline → return local cache
  /// 3. If online → send version to server
  /// 4. If 304 (unchanged) → load local data
  /// 5. If 200 (updated) → save new JSON + version
  /// 6. Cache product images
  /// 7. Return offline-ready products
  Future<ProductCatalog> getProducts({bool forceRefresh = false}) async {
    // Try to load from cache first for instant response
    final cachedCatalog = await _localDataSource.loadCachedCatalog();
    final currentVersion = await _localDataSource.getVersion();

    // Check if remote is reachable
    final isOnline = await _remoteDataSource.isReachable();

    if (!isOnline) {
      // Offline mode - return cache or empty catalog
      return cachedCatalog ?? ProductCatalog.empty();
    }

    try {
      // Online mode - check for updates
      final result = await _remoteDataSource.fetchProducts(
        currentVersion: forceRefresh ? null : currentVersion,
      );

      if (!result.isModified && cachedCatalog != null) {
        // Data unchanged, use cache
        return cachedCatalog;
      }

      if (result.catalog != null) {
        // New data available - save and cache images
        await _localDataSource.saveCatalog(result.catalog!);
        await _cacheProductImages(result.catalog!);
        return result.catalog!;
      }

      // Fallback to cache
      return cachedCatalog ?? ProductCatalog.empty();
    } catch (e) {
      // On error, return cached data
      return cachedCatalog ?? ProductCatalog.empty();
    }
  }

  /// Get all speakers
  Future<List<SpeakerProduct>> getSpeakers({bool forceRefresh = false}) async {
    final catalog = await getProducts(forceRefresh: forceRefresh);
    return catalog.speakers;
  }

  /// Get all amplifiers
  Future<List<AmplifierProduct>> getAmplifiers(
      {bool forceRefresh = false}) async {
    final catalog = await getProducts(forceRefresh: forceRefresh);
    return catalog.amplifiers;
  }

  /// Get all controllers
  Future<List<ControllerProduct>> getControllers(
      {bool forceRefresh = false}) async {
    final catalog = await getProducts(forceRefresh: forceRefresh);
    return catalog.controllers;
  }

  /// Get all DSPs
  Future<List<DspProduct>> getDsps({bool forceRefresh = false}) async {
    final catalog = await getProducts(forceRefresh: forceRefresh);
    return catalog.dsps;
  }

  /// Get all accessories
  Future<List<AccessoryProduct>> getAccessories(
      {bool forceRefresh = false}) async {
    final catalog = await getProducts(forceRefresh: forceRefresh);
    return catalog.accessories;
  }

  /// Get all I/O endpoints
  Future<List<IoEndpointProduct>> getIoEndpoints(
      {bool forceRefresh = false}) async {
    final catalog = await getProducts(forceRefresh: forceRefresh);
    return catalog.ioEndpoints;
  }

  /// Get current catalog version
  Future<String?> getCurrentVersion() async {
    return _localDataSource.getVersion();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _localDataSource.clearCache();
    await _imageCacheService.clearImageCache();
  }

  /// Check if there's cached data available
  Future<bool> hasCachedData() async {
    return _localDataSource.hasCachedData();
  }

  /// Cache images for all products in a catalog
  Future<void> _cacheProductImages(ProductCatalog catalog) async {
    final allImageUrls = <String>[];

    // Collect all image URLs from all products
    for (final speaker in catalog.speakers) {
      allImageUrls.addAll(speaker.assets.allAssetUrls);
    }
    for (final amp in catalog.amplifiers) {
      allImageUrls.addAll(amp.assets.allAssetUrls);
    }
    for (final controller in catalog.controllers) {
      allImageUrls.addAll(controller.assets.allAssetUrls);
    }
    for (final dsp in catalog.dsps) {
      allImageUrls.addAll(dsp.assets.allAssetUrls);
    }
    for (final accessory in catalog.accessories) {
      allImageUrls.addAll(accessory.assets.allAssetUrls);
    }
    for (final endpoint in catalog.ioEndpoints) {
      allImageUrls.addAll(endpoint.assets.allAssetUrls);
    }

    // Filter only valid URLs (not local filenames)
    final validUrls = allImageUrls
        .where((url) => url.startsWith('http://') || url.startsWith('https://'))
        .toList();

    // Cache all images
    await _imageCacheService.cacheImages(validUrls);
  }

  /// Get local image path for a given URL
  ///
  /// Returns local path if cached, otherwise the original URL.
  Future<String> getImagePath(String imageUrl) async {
    return _imageCacheService.getImagePath(imageUrl);
  }
}
