import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;

import 'data_sources/product_catalog.dart';
import 'models/models.dart';

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
  final FusionNetworkClient networkClient;
  final String cacheDir;
  final bool fusionOnly;
  final String productCacheZipAssetPath = 'assets/zip/product_cache.zip';

  ProductCatalog? _catalog;
  bool _syncedFromApi = false;
  bool _imageCachingInProgress = false;

  static String? localProductDirPath;

  Products({
    required this.baseUrl,
    required this.networkClient,
    String? cacheDir,
    this.fusionOnly = false,
  }) : cacheDir = cacheDir ?? _getDefaultCacheDir();

  static String _getDefaultCacheDir() {
    return '${Directory.current.path}/.product_cache_temp';
  }

  File get _cacheFile => File('$cacheDir/products.json');

  File get _versionFile => File('$cacheDir/version.txt');

  Directory get _imagesDir => Directory('$cacheDir/images');

  /// Initialize products - offline first
  /// 1. Try to sync from API (if online)
  /// 2. If API fails or offline, load from local cache
  /// 3. If no cache exists and API fails, throws error
  Future<void> initialize() async {
    try {
      // debugPrint("Extracting local product assets...");
      // await extractLocalProductsZip();
      // debugPrint("Syncing from API...");
      await _syncFromApi();
      _syncedFromApi = true;
    } catch (e) {
      // API failed - that's okay, we'll use cache
      _syncedFromApi = false;
    }

    // Load from cache
    // if (await _cacheFile.exists()) {
    //   debugPrint("Loading products from cache...");
    //   await _loadFromCache();
    // } else {
    debugPrint("No cached data found, loading from local asset...");
    loadFromLocalAsset();
    // }
    if (!_syncedFromApi) {
      // throw Exception('No cached data and API is unavailable');
    }
  }

  /// Force refresh from API (with fallback to cache)
  Future<void> refresh() async {
    try {
      log("Refreshing products from API...");
      await _syncFromApi();
      // await _loadFromCache();
      _syncedFromApi = true;
    } catch (e) {
      // API failed - load from cache if available
      if (await _cacheFile.exists()) {
        await _loadFromCache();
        _syncedFromApi = false;
      } else {
        // No cache exists - load from local asset
        loadFromLocalAsset();
      }
    }
  }

  Future<String> getCachedProductDirectoryPath() async {
    final Directory dir = await FusionUtils.getFusionAppDirectory();
    final String localPath = dir.path;

    //create a directory named 'extracted_images' inside localPath
    localProductDirPath = p.join(localPath, 'localProductCache');
    return localProductDirPath!;
  }

  Future<void> extractLocalProductsZip() async {
    try {
      // 1. Get the images directory path
      final String imagesDirPath = await getCachedProductDirectoryPath();
      final Directory assetsProductDir = Directory(imagesDirPath);

      // 2. Check if images directory exists and has files
      if (!await assetsProductDir.exists() || (await assetsProductDir.list().isEmpty)) {
        // Create the directory if it doesn't exist
        await assetsProductDir.create(recursive: true);

        // 3. Load the zip file from assets
        final ByteData data = await rootBundle.load(productCacheZipAssetPath);
        final List<int> bytes = data.buffer.asUint8List();

        // 4. Decode the zip
        final Archive archive = ZipDecoder().decodeBytes(bytes);

        // 5. Loop through the archive
        for (final ArchiveFile file in archive) {
          final String filename = file.name;

          // Construct the full output path - extract to assetsProductDir, not localPath
          final String outputPath = p.join(imagesDirPath, filename);

          if (file.isFile) {
            // Ensure the directory for this file exists
            final File outFile = File(outputPath);
            await outFile.parent.create(recursive: true);

            // Write the file
            await outFile.writeAsBytes(file.content as List<int>);
          } else {
            // If it's a directory entry in the zip, create it
            await Directory(outputPath).create(recursive: true);
          }
        }
      } else {
        debugPrint("Images already extracted at: $imagesDirPath");
      }
    } catch (e) {
      debugPrint("Error extracting zip: $e");
    }
  }

  /// Check if last operation synced from API
  bool get wasSyncedFromApi => _syncedFromApi;

  /// Check if image caching is in progress
  bool get isImageCachingInProgress => _imageCachingInProgress;

  /// Internal: Sync from API and save to local cache
  Future<void> _syncFromApi() async {
    try {
      final response = await networkClient.get<ProductCatalog>(
        api: FusionApiEndpoint.products,
        fromJson: (p0) => ProductCatalog.fromJson(p0),
      );

      if (!response.success) {
        FusionLogger.log(tag: LogTag.project, message: "Products sync failed: ${response.message}");
        throw Exception(response.message);
      }

      final catalog = response.data!;

      // Ensure cache directory exists
      await _ensureCacheDir();

      // Save JSON to cache
      await _cacheFile.writeAsString(jsonEncode(catalog.toJson()));
      await _versionFile.writeAsString(catalog.version);

      // Start image caching in background (non-blocking)
      _cacheImagesInBackground(catalog);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Products sync error: $e");
      // Don't throw - we'll fallback to cache
    }
  }

  Future<void> loadFromLocalAsset() async {
    try {
      if (localProductDirPath == null) {
        await extractLocalProductsZip();
      }
      if (localProductDirPath != null) {
        final String jsonFilePath = p.join(localProductDirPath!, 'product_cache/products.json');
        final File jsonFile = File(jsonFilePath);
        if (await jsonFile.exists()) {
          final jsonString = await jsonFile.readAsString();
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          print("Loading products from local asset at: $jsonFilePath");
          _catalog = ProductCatalog.fromJson(json);
          print(_catalog);
          print("Loaded products from local asset at: $jsonFilePath");
        }
      }
    } catch (e) {
      // Loading from local asset failed
      FusionLogger.log(tag: LogTag.project, message: "Error loading products from local asset: $e");
    }
  }

  /// Internal: Load products from local cache
  Future<void> _loadFromCache() async {
    if (!await _cacheFile.exists()) {
      FusionLogger.log(tag: LogTag.project, message: "Cache file does not exist at path: ${_cacheFile.path}");
      loadFromLocalAsset();
    } else {
      final jsonString = await _cacheFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _catalog = ProductCatalog.fromJson(json);
    }
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
      // final localPath = '${_imagesDir.path}/$fileName';
      // if (File(localPath).existsSync()) {
      //   return localPath;
      // } else {
      final fallbackPath = p.join(localProductDirPath ?? '', 'product_cache/images/$fileName');
      if (File(fallbackPath).existsSync()) {
        return fallbackPath;
      }
      // }
    }
    return imageUrl; // Return original if not cached
  }

  String getImageName(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      final uri = Uri.parse(imageUrl);
      final fileName = _sanitizeFileName(uri.pathSegments.last);
      return fileName;
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

  int get totalCount =>
      fusionOnly ? speakers.length + amplifiers.length + controllers.length + dsps.length + accessories.length + ioEndpoints.length : _catalog?.totalCount ?? 0;

  List<SpeakerProduct> get speakers => fusionOnly ? (_catalog?.speakers ?? []).where((s) => s.isFusionCompatible).toList() : _catalog?.speakers ?? [];

  List<AmplifierProduct> get amplifiers => fusionOnly ? (_catalog?.amplifiers ?? []).where((a) => a.isFusionCompatible).toList() : _catalog?.amplifiers ?? [];

  List<ControllerProduct> get controllers =>
      fusionOnly ? (_catalog?.controllers ?? []).where((c) => c.isFusionCompatible).toList() : _catalog?.controllers ?? [];

  List<DspProduct> get dsps => fusionOnly ? (_catalog?.dsps ?? []).where((d) => d.isFusionCompatible).toList() : _catalog?.dsps ?? [];

  List<AccessoryProduct> get accessories =>
      fusionOnly ? (_catalog?.accessories ?? []).where((a) => a.isFusionCompatible).toList() : _catalog?.accessories ?? [];

  List<IoEndpointProduct> get ioEndpoints =>
      fusionOnly ? (_catalog?.ioEndpoints ?? []).where((e) => e.isFusionCompatible).toList() : _catalog?.ioEndpoints ?? [];

  // ============= Fusion Compatible Filtering =============

  /// Get all speakers that are Fusion compatible
  List<SpeakerProduct> get fusionCompatibleSpeakers => speakers.where((s) => s.isFusionCompatible).toList();

  /// Get all amplifiers that are Fusion compatible
  List<AmplifierProduct> get fusionCompatibleAmplifiers => amplifiers.where((a) => a.isFusionCompatible).toList();

  /// Get all controllers that are Fusion compatible
  List<ControllerProduct> get fusionCompatibleControllers => controllers.where((c) => c.isFusionCompatible).toList();

  /// Get all DSPs that are Fusion compatible
  List<DspProduct> get fusionCompatibleDsps => dsps.where((d) => d.isFusionCompatible).toList();

  /// Get all accessories that are Fusion compatible
  List<AccessoryProduct> get fusionCompatibleAccessories => accessories.where((a) => a.isFusionCompatible).toList();

  /// Get all I/O endpoints that are Fusion compatible
  List<IoEndpointProduct> get fusionCompatibleIoEndpoints => ioEndpoints.where((e) => e.isFusionCompatible).toList();

  // ============= Lookup by ID =============

  SpeakerProduct? getSpeaker(int productId) => speakers.where((s) => s.id == productId).firstOrNull;

  AmplifierProduct? getAmplifier(int productId) => amplifiers.where((a) => a.id == productId).firstOrNull;

  ControllerProduct? getController(int productId) => controllers.where((c) => c.id == productId).firstOrNull;

  DspProduct? getDsp(int productId) => dsps.where((d) => d.id == productId).firstOrNull;

  AccessoryProduct? getAccessory(int productId) => accessories.where((a) => a.id == productId).firstOrNull;

  IoEndpointProduct? getIoEndpoint(int productId) => ioEndpoints.where((e) => e.id == productId).firstOrNull;
}
