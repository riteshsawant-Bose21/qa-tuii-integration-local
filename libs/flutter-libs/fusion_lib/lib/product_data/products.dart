import 'dart:convert';
import 'dart:io';

import 'models/models.dart';
import 'data_sources/product_catalog.dart';

/// Products API - Offline-first product data access
///
/// All API calls happen internally. The library manages caching automatically.
/// Local cache is the source of truth.
///
/// Usage:
/// ```dart
/// final products = Products(baseUrl: 'http://localhost:8080');
/// await products.initialize();
///
/// final speakers = products.speakers;  // From local cache
/// ```
class Products {
  final String baseUrl;
  final String cacheDir;

  ProductCatalog? _catalog;
  bool _syncedFromApi = false;
  bool _imageCachingInProgress = false;

  Products({
    required this.baseUrl,
    String? cacheDir,
  }) : cacheDir = cacheDir ?? _getDefaultCacheDir();

  static String _getDefaultCacheDir() {
    return '${Directory.current.path}/.product_cache';
  }

  File get _cacheFile => File('$cacheDir/products.json');
  File get _versionFile => File('$cacheDir/version.txt');
  Directory get _imagesDir => Directory('$cacheDir/images');

  /// Initialize products - offline first
  ///
  /// 1. Try to sync from API (if online)
  /// 2. If API fails or offline, load from local cache
  /// 3. If no cache exists and API fails, throws error
  Future<void> initialize() async {
    // Try to sync from API first
    try {
      await _syncFromApi();
      _syncedFromApi = true;
    } catch (e) {
      // API failed - that's okay, we'll use cache
      _syncedFromApi = false;
    }

    // Load from cache
    if (await _cacheFile.exists()) {
      await _loadFromCache();
    } else if (!_syncedFromApi) {
      throw Exception('No cached data and API is unavailable');
    }
  }

  /// Force refresh from API (with fallback to cache)
  Future<void> refresh() async {
    try {
      await _syncFromApi();
      await _loadFromCache();
      _syncedFromApi = true;
    } catch (e) {
      // API failed - load from cache if available
      if (await _cacheFile.exists()) {
        await _loadFromCache();
        _syncedFromApi = false;
      } else {
        throw Exception('API unavailable and no cached data');
      }
    }
  }

  /// Check if last operation synced from API
  bool get wasSyncedFromApi => _syncedFromApi;

  /// Check if image caching is in progress
  bool get isImageCachingInProgress => _imageCachingInProgress;

  /// Internal: Sync from API and save to local cache
  Future<void> _syncFromApi() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(
        Uri.parse('$baseUrl/products'),
      );
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final catalog = ProductCatalog.fromJson(json);

      // Ensure cache directory exists
      await _ensureCacheDir();

      // Save JSON to cache
      await _cacheFile.writeAsString(body);
      await _versionFile.writeAsString(catalog.version);

      // Start image caching in background (non-blocking)
      _cacheImagesInBackground(catalog);

    } finally {
      client.close();
    }
  }

  /// Internal: Load products from local cache
  Future<void> _loadFromCache() async {
    final jsonString = await _cacheFile.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    _catalog = ProductCatalog.fromJson(json);
  }

  /// Check if local cache exists
  Future<bool> hasCachedData() async {
    return _cacheFile.exists();
  }

  /// Get cached version
  Future<String?> getCachedVersion() async {
    if (await _versionFile.exists()) {
      return _versionFile.readAsString();
    }
    return null;
  }

  /// Clear local cache
  Future<void> clearCache() async {
    final dir = Directory(cacheDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> _ensureCacheDir() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    if (!await _imagesDir.exists()) {
      await _imagesDir.create(recursive: true);
    }
  }

  /// Cache images in background (non-blocking)
  void _cacheImagesInBackground(ProductCatalog catalog) {
    // Don't wait for this - let it run in background
    _cacheImagesAsync(catalog);
  }

  /// Cache all product images asynchronously
  Future<void> _cacheImagesAsync(ProductCatalog catalog) async {
    if (_imageCachingInProgress) return;
    _imageCachingInProgress = true;

    try {
      final allUrls = <String>{};

      // Collect all unique image URLs
      for (final s in catalog.speakers) {
        allUrls.addAll(s.assets.allAssetUrls);
      }
      for (final a in catalog.amplifiers) {
        allUrls.addAll(a.assets.allAssetUrls);
      }
      for (final c in catalog.controllers) {
        allUrls.addAll(c.assets.allAssetUrls);
      }
      for (final d in catalog.dsps) {
        allUrls.addAll(d.assets.allAssetUrls);
      }
      for (final a in catalog.accessories) {
        allUrls.addAll(a.assets.allAssetUrls);
      }
      for (final e in catalog.ioEndpoints) {
        allUrls.addAll(e.assets.allAssetUrls);
      }

      // Filter valid HTTP URLs only
      final validUrls = allUrls.where((u) => u.startsWith('http')).toList();

      if (validUrls.isEmpty) return;

      await _ensureCacheDir();

      // Download images with concurrency limit
      const maxConcurrent = 5;
      for (var i = 0; i < validUrls.length; i += maxConcurrent) {
        final batch = validUrls.skip(i).take(maxConcurrent);
        await Future.wait(batch.map((url) => _downloadImage(url)));
      }
    } finally {
      _imageCachingInProgress = false;
    }
  }

  /// Download a single image
  Future<void> _downloadImage(String url) async {
    try {
      // Generate filename from URL
      final uri = Uri.parse(url);
      final fileName = _sanitizeFileName(uri.pathSegments.last);
      final file = File('${_imagesDir.path}/$fileName');

      if (await file.exists()) return; // Skip if already cached

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>(
            <int>[],
            (prev, element) => prev..addAll(element),
          );
          await file.writeAsBytes(bytes);
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // Silently skip failed downloads
    }
  }

  /// Sanitize filename for filesystem
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\-.]'), '_');
  }

  /// Get local path for an image (returns cached path if available)
  String getImagePath(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      final uri = Uri.parse(imageUrl);
      final fileName = _sanitizeFileName(uri.pathSegments.last);
      final localPath = '${_imagesDir.path}/$fileName';
      if (File(localPath).existsSync()) {
        return localPath;
      }
    }
    return imageUrl; // Return original if not cached
  }

  /// Check if an image is cached locally
  bool isImageCached(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      final uri = Uri.parse(imageUrl);
      final fileName = _sanitizeFileName(uri.pathSegments.last);
      final localPath = '${_imagesDir.path}/$fileName';
      return File(localPath).existsSync();
    }
    return false;
  }

  /// Manually trigger image caching
  Future<void> cacheImages() async {
    if (_catalog != null) {
      await _cacheImagesAsync(_catalog!);
    }
  }

  // ============= Getters (from local cache) =============

  bool get isLoaded => _catalog != null;
  String get version => _catalog?.version ?? '';
  int get totalCount => _catalog?.totalCount ?? 0;

  List<SpeakerProduct> get speakers => _catalog?.speakers ?? [];
  List<AmplifierProduct> get amplifiers => _catalog?.amplifiers ?? [];
  List<ControllerProduct> get controllers => _catalog?.controllers ?? [];
  List<DspProduct> get dsps => _catalog?.dsps ?? [];
  List<AccessoryProduct> get accessories => _catalog?.accessories ?? [];
  List<IoEndpointProduct> get ioEndpoints => _catalog?.ioEndpoints ?? [];

  // ============= Lookup by ID =============

  SpeakerProduct? getSpeaker(int productId) =>
      speakers.where((s) => s.productId == productId).firstOrNull;

  AmplifierProduct? getAmplifier(int productId) =>
      amplifiers.where((a) => a.productId == productId).firstOrNull;

  ControllerProduct? getController(int productId) =>
      controllers.where((c) => c.productId == productId).firstOrNull;

  DspProduct? getDsp(int productId) =>
      dsps.where((d) => d.productId == productId).firstOrNull;

  AccessoryProduct? getAccessory(int productId) =>
      accessories.where((a) => a.productId == productId).firstOrNull;

  IoEndpointProduct? getIoEndpoint(int productId) =>
      ioEndpoints.where((e) => e.productId == productId).firstOrNull;
}
