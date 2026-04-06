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
  final bool loadFromZip;
  final String _productCacheZipAssetPath = 'assets/zip/product_cache.zip';

  ProductCatalog? _catalog;
  bool _syncedFromApi = false;
  bool _imageCachingInProgress = false;
  final Map<String, String> _imagePathByUrl = <String, String>{};
  final Map<int, ProductCachedImage> _productImagesById = <int, ProductCachedImage>{};

  static String? localProductDirPath;

  Products({
    required this.baseUrl,
    required this.networkClient,
    String? cacheDir,
    this.fusionOnly = false,
    this.loadFromZip = false,
  }) : cacheDir = cacheDir ?? _getDefaultCacheDir();

  static String _getDefaultCacheDir() => '${Directory.current.path}/.product_cache_temp';

  Directory get _productsCacheDir => Directory('$cacheDir/products');

  File get _cacheFile => File('${_productsCacheDir.path}/products.json');

  File get _versionFile => File('${_productsCacheDir.path}/version.txt');

  File get _imageIndexFile => File('${_productsCacheDir.path}/image_index.json');

  Directory get _imagesDir => Directory('${_productsCacheDir.path}/images');

  /// Initialize products - offline first
  /// 1. Try to sync from API (if online)
  /// 2. If API fails or offline, load from local cache
  /// 3. If no cache exists and API fails, throws error
  Future<void> initialize() async {
    await _ensureCacheDir();
    await _loadImageIndex();

    // 1) Load quickly from existing cache if present.
    final bool loadedFromCache = await _loadFromCache();

    // 2) Try network sync and refresh cache.
    final bool syncSuccess = await _syncFromApi();
    _syncedFromApi = syncSuccess;

    // 3) If network sync succeeded, cache was refreshed.
    if (syncSuccess) {
      await _loadFromCache();
      return;
    }

    // 4) Optional final fallback: bundled local asset zip cache.
    if (!loadedFromCache) {
      if (loadFromZip) {
        debugPrint('No API/cache data found, loading from local asset...');
        await _loadFromZipLocalAsset();
      } else {
        debugPrint('No API/cache data found and zip fallback is disabled.');
      }
    }
  }

  /// Force refresh from API (with fallback to cache)
  Future<void> refresh() async {
    log('Refreshing products from API...');
    final bool syncSuccess = await _syncFromApi();
    _syncedFromApi = syncSuccess;

    if (syncSuccess) {
      await _loadFromCache();
      return;
    }

    // API failed - load from cache if available
    final bool loadedFromCache = await _loadFromCache();
    if (!loadedFromCache && loadFromZip) {
      // No cache exists - load from local asset
      await _loadFromZipLocalAsset();
    } else if (!loadedFromCache) {
      debugPrint('Refresh failed and zip fallback is disabled.');
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
        final ByteData data = await rootBundle.load(_productCacheZipAssetPath);
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

  /// Internal: Sync from API and save to local cache.
  /// Returns true when sync/write succeeded, false otherwise.
  Future<bool> _syncFromApi() async {
    try {
      final response = await networkClient.get<ProductCatalog>(
        api: FusionApiEndpoint.products,
        fromJson: (data) => ProductCatalog.fromJson(data),
      );

      if (!response.success) {
        FusionLogger.log(tag: LogTag.project, message: "Products sync failed: ${response.message}");
        throw Exception(response.message);
      }

      final catalog = response.data!;
      final Map<String, dynamic> incomingJson = catalog.toJson();
      final Map<String, dynamic>? cachedJson = await _readCacheJsonIfExists();

      // Preserve previously cached media fields when API payload is partial.
      final Map<String, dynamic> mergedJson = cachedJson == null ? incomingJson : _mergeCatalogPreservingMedia(incomingJson, cachedJson);

      // Ensure cache directory exists
      await _ensureCacheDir();

      // Save JSON to cache
      await _cacheFile.writeAsString(jsonEncode(mergedJson));
      final ProductCatalog mergedCatalog = ProductCatalog.fromJson(mergedJson);
      await _versionFile.writeAsString(mergedCatalog.version);
      _catalog = mergedCatalog;

      // Download and index all product images into local cache.
      await _cacheImagesAsync(mergedCatalog);

      // Build O(1) productId -> ProductCachedImage map using local image paths.
      _rebuildProductImageMapFromCatalogJson(mergedJson);
      return true;
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Products sync error: $e");
      return false;
    }
  }

  Future<void> _loadFromZipLocalAsset() async {
    try {
      if (localProductDirPath == null) await extractLocalProductsZip();

      if (localProductDirPath != null) {
        final String jsonFilePath = p.join(localProductDirPath!, 'product_cache/products.json');
        final File jsonFile = File(jsonFilePath);
        if (await jsonFile.exists()) {
          final jsonString = await jsonFile.readAsString();
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          debugPrint('Loading products from local asset at: $jsonFilePath');
          _catalog = ProductCatalog.fromJson(json);
          debugPrint('Loaded products from local asset at: $jsonFilePath');

          // Persist local asset payload into writable cache for future offline boots.
          await _ensureCacheDir();
          await _cacheFile.writeAsString(jsonEncode(json));
          await _versionFile.writeAsString(_catalog?.version ?? '');
          _rebuildProductImageMapFromCatalogJson(json);
          await _moveBundledImagesToCacheDir(_catalog);
        }
      }
    } catch (e) {
      // Loading from local asset failed
      FusionLogger.log(tag: LogTag.project, message: "Error loading products from local asset: $e");
    }
  }

  /// Internal: Load products from local cache
  Future<bool> _loadFromCache() async {
    if (!await _cacheFile.exists()) {
      FusionLogger.log(tag: LogTag.project, message: "Cache file does not exist at path: ${_cacheFile.path}");
      return false;
    } else {
      final jsonString = await _cacheFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _catalog = ProductCatalog.fromJson(json);
      _rebuildProductImageMapFromCatalogJson(json);
      return true;
    }
  }

  Future<Map<String, dynamic>?> _readCacheJsonIfExists() async {
    if (!await _cacheFile.exists()) return null;
    try {
      final String jsonString = await _cacheFile.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _mergeCatalogPreservingMedia(Map<String, dynamic> incoming, Map<String, dynamic> cached) {
    final Map<String, dynamic> merged = Map<String, dynamic>.from(incoming);

    const List<String> categoryKeys = <String>[
      'speakers',
      'amplifiers',
      'controllers',
      'dsps',
      'digital_signal_processors',
      'accessories',
      'additional_accessories',
      'io_endpoints',
      'i_o_endpoints',
    ];

    for (final String key in categoryKeys) {
      final dynamic incomingList = merged[key];
      final dynamic cachedList = cached[key];
      if (incomingList is! List || cachedList is! List) continue;

      final Map<dynamic, Map<String, dynamic>> cachedById = <dynamic, Map<String, dynamic>>{};
      for (final dynamic item in cachedList) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          cachedById[item['id']] = item;
        }
      }

      final List<dynamic> rebuilt = <dynamic>[];
      for (final dynamic item in incomingList) {
        if (item is! Map<String, dynamic>) {
          rebuilt.add(item);
          continue;
        }

        final Map<String, dynamic> updated = Map<String, dynamic>.from(item);
        final Map<String, dynamic>? old = cachedById[item['id']];
        if (old != null) {
          _preserveMediaFields(updated, old);
        }
        rebuilt.add(updated);
      }
      merged[key] = rebuilt;
    }

    return merged;
  }

  void _preserveMediaFields(Map<String, dynamic> target, Map<String, dynamic> source) {
    for (final MapEntry<String, dynamic> entry in source.entries) {
      final String field = entry.key;
      final dynamic sourceValue = entry.value;

      final bool isMediaField = field == 'images' || field == 'assets' || field.contains('image');
      if (!isMediaField) continue;

      final dynamic targetValue = target[field];
      if (_isValueEmpty(targetValue) && !_isValueEmpty(sourceValue)) {
        target[field] = sourceValue;
      }
    }
  }

  bool _isValueEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  /// Check if local cache exists
  Future<bool> hasCachedData() => _cacheFile.exists();

  /// Get cached version
  Future<String?> getCachedVersion() async {
    if (await _versionFile.exists()) return _versionFile.readAsString();
    return null;
  }

  /// Clear local cache
  Future<void> clearCache() async {
    final dir = Directory(cacheDir);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> _ensureCacheDir() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    if (!await _productsCacheDir.exists()) await _productsCacheDir.create(recursive: true);
    if (!await _imagesDir.exists()) await _imagesDir.create(recursive: true);
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
      await _moveBundledImagesToCacheDir(catalog);

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
      final fileName = _cacheFileNameFromUrl(uri);
      final file = File('${_imagesDir.path}/$fileName');

      if (await file.exists()) {
        _imagePathByUrl[url] = file.path;
        await _persistImageIndex();
        return;
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>(<int>[], (prev, element) => prev..addAll(element));
          await file.writeAsBytes(bytes);
          _imagePathByUrl[url] = file.path;
          await _persistImageIndex();
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // Silently skip failed downloads
    }
  }

  /// Sanitize filename for filesystem
  String _sanitizeFileName(String name) => name.replaceAll(RegExp(r'[^\w\-.]'), '_');

  /// Get local path for an image (returns cached path if available)
  String getImagePath(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      final String? indexedPath = _imagePathByUrl[imageUrl];
      if (indexedPath != null && File(indexedPath).existsSync()) {
        return indexedPath;
      }

      final Uri uri = Uri.parse(imageUrl);
      final String downloadedPath = '${_imagesDir.path}/${_cacheFileNameFromUrl(uri)}';
      if (File(downloadedPath).existsSync()) {
        _imagePathByUrl[imageUrl] = downloadedPath;
        _persistImageIndex();
        return downloadedPath;
      }

      final String fallbackFileName = _sanitizeFileName(uri.pathSegments.last);
      final String fallbackPath = p.join(localProductDirPath ?? '', 'product_cache/images/$fallbackFileName');
      if (File(fallbackPath).existsSync()) {
        final File targetFile = File(downloadedPath);
        if (!targetFile.existsSync()) {
          targetFile.parent.createSync(recursive: true);
          File(fallbackPath).copySync(targetFile.path);
        }
        _imagePathByUrl[imageUrl] = targetFile.path;
        _persistImageIndex();
        return targetFile.path;
      }
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
      final String resolvedPath = getImagePath(imageUrl);
      return resolvedPath != imageUrl && File(resolvedPath).existsSync();
    }
    return false;
  }

  Future<void> _loadImageIndex() async {
    try {
      if (!await _imageIndexFile.exists()) return;
      final String raw = await _imageIndexFile.readAsString();
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      _imagePathByUrl.clear();
      _imagePathByUrl.addAll(
        decoded.map(
          (dynamic key, dynamic value) => MapEntry(
            key as String,
            value as String,
          ),
        ),
      );
    } catch (_) {
      // Non-fatal; index is rebuilt opportunistically.
    }
  }

  Future<void> _persistImageIndex() async {
    try {
      await _ensureCacheDir();
      await _imageIndexFile.writeAsString(jsonEncode(_imagePathByUrl));
    } catch (_) {
      // Non-fatal; path can still be resolved by direct checks.
    }
  }

  Future<void> _moveBundledImagesToCacheDir(ProductCatalog? catalog) async {
    if (catalog == null || localProductDirPath == null) return;

    bool changed = false;

    void add(Iterable<String> urls) {
      for (final String url in urls.where((u) => u.startsWith('http'))) {
        try {
          final Uri uri = Uri.parse(url);
          final String bundledFileName = _sanitizeFileName(uri.pathSegments.last);
          final String bundledPath = p.join(localProductDirPath!, 'product_cache/images/$bundledFileName');
          final File bundledFile = File(bundledPath);
          if (!bundledFile.existsSync()) continue;

          final String cacheFilePath = '${_imagesDir.path}/${_cacheFileNameFromUrl(uri)}';
          final File cacheFile = File(cacheFilePath);
          if (!cacheFile.existsSync()) {
            cacheFile.parent.createSync(recursive: true);
            bundledFile.copySync(cacheFile.path);
          }

          if (_imagePathByUrl[url] != cacheFile.path) {
            _imagePathByUrl[url] = cacheFile.path;
            changed = true;
          }
        } catch (_) {
          // Ignore malformed URL
        }
      }
    }

    for (final s in catalog.speakers) {
      add(s.assets.allAssetUrls);
    }
    for (final a in catalog.amplifiers) {
      add(a.assets.allAssetUrls);
    }
    for (final c in catalog.controllers) {
      add(c.assets.allAssetUrls);
    }
    for (final d in catalog.dsps) {
      add(d.assets.allAssetUrls);
    }
    for (final a in catalog.accessories) {
      add(a.assets.allAssetUrls);
    }
    for (final e in catalog.ioEndpoints) {
      add(e.assets.allAssetUrls);
    }

    if (changed) {
      await _persistImageIndex();
    }
  }

  String _cacheFileNameFromUrl(Uri uri) {
    final String extension = p.extension(uri.path).isEmpty ? '.img' : p.extension(uri.path);
    final String encoded = base64Url.encode(utf8.encode(uri.toString())).replaceAll('=', '');
    return _sanitizeFileName('$encoded$extension');
  }

  ProductCachedImage? getProductImage(int productId) => _productImagesById[productId];

  List<String> getProductImageLocalPaths(int productId, {String color = 'black'}) {
    final ProductCachedImage? image = _productImagesById[productId];
    if (image == null) return const <String>[];
    if (color.toLowerCase() == 'black') return image.black;
    if (color.toLowerCase() == 'white') return image.white;
    return image.others[color.toLowerCase()] ?? const <String>[];
  }

  void _rebuildProductImageMapFromCatalogJson(Map<String, dynamic> catalogJson) {
    const List<String> categoryKeys = <String>[
      'speakers',
      'amplifiers',
      'controllers',
      'dsps',
      'digital_signal_processors',
      'accessories',
      'additional_accessories',
      'io_endpoints',
      'i_o_endpoints',
    ];

    final Map<int, ProductCachedImage> rebuilt = <int, ProductCachedImage>{};

    for (final String category in categoryKeys) {
      final dynamic list = catalogJson[category];
      if (list is! List) continue;

      for (final dynamic item in list) {
        if (item is! Map<String, dynamic>) continue;
        final dynamic idRaw = item['id'];
        if (idRaw is! num) continue;
        final int productId = idRaw.toInt();

        final Map<String, List<String>> colors = _extractColorImageUrls(item);
        final List<String> black = colors['black'] ?? const <String>[];
        final List<String> white = colors['white'] ?? const <String>[];

        final Map<String, List<String>> others = <String, List<String>>{};
        for (final MapEntry<String, List<String>> entry in colors.entries) {
          final String key = entry.key.toLowerCase();
          if (key == 'black' || key == 'white') continue;
          others[key] = entry.value;
        }

        rebuilt[productId] = ProductCachedImage(
          productId: productId,
          category: category,
          modelName: item['model_name'] as String? ?? '',
          black: black,
          white: white,
          others: others,
        );
      }
    }

    _productImagesById
      ..clear()
      ..addAll(rebuilt);
  }

  Map<String, List<String>> _extractColorImageUrls(Map<String, dynamic> productJson) {
    final Map<String, List<String>> output = <String, List<String>>{};
    final dynamic images = productJson['images'];
    if (images is! List) return output;

    for (final dynamic imageGroup in images) {
      if (imageGroup is! Map<String, dynamic>) continue;
      for (final MapEntry<String, dynamic> entry in imageGroup.entries) {
        final String color = entry.key.toLowerCase();
        final dynamic value = entry.value;
        if (value is! List) continue;

        final List<String> urls = value.whereType<String>().where((String u) => u.startsWith('http')).toList();
        if (urls.isEmpty) continue;

        final List<String> localPaths = urls.map(_preferredLocalPathForUrl).toList();
        output[color] = localPaths;
      }
    }
    return output;
  }

  String _preferredLocalPathForUrl(String url) {
    final String? indexedPath = _imagePathByUrl[url];
    if (indexedPath != null && File(indexedPath).existsSync()) {
      return indexedPath;
    }

    try {
      final Uri uri = Uri.parse(url);
      final String downloadedPath = '${_imagesDir.path}/${_cacheFileNameFromUrl(uri)}';
      if (File(downloadedPath).existsSync()) {
        return downloadedPath;
      }

      final String fallbackFileName = _sanitizeFileName(uri.pathSegments.last);
      final String fallbackPath = p.join(localProductDirPath ?? '', 'product_cache/images/$fallbackFileName');
      if (File(fallbackPath).existsSync()) {
        final File targetFile = File(downloadedPath);
        if (!targetFile.existsSync()) {
          targetFile.parent.createSync(recursive: true);
          File(fallbackPath).copySync(targetFile.path);
        }
        return targetFile.path;
      }

      // Return deterministic local cache path for future download.
      return downloadedPath;
    } catch (_) {
      return url;
    }
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

  SpeakerProduct? getSpeaker(int productId) => speakers.where((s) => s.productId == productId).firstOrNull;

  AmplifierProduct? getAmplifier(int productId) => amplifiers.where((a) => a.productId == productId).firstOrNull;

  ControllerProduct? getController(int productId) => controllers.where((c) => c.productId == productId).firstOrNull;

  DspProduct? getDsp(int productId) => dsps.where((d) => d.productId == productId).firstOrNull;

  AccessoryProduct? getAccessory(int productId) => accessories.where((a) => a.productId == productId).firstOrNull;

  IoEndpointProduct? getIoEndpoint(int productId) => ioEndpoints.where((e) => e.productId == productId).firstOrNull;
}

class ProductCachedImage {
  final int productId;
  final String category;
  final String modelName;
  final List<String> black;
  final List<String> white;
  final Map<String, List<String>> others;

  const ProductCachedImage({
    required this.productId,
    required this.category,
    required this.modelName,
    required this.black,
    required this.white,
    required this.others,
  });

  factory ProductCachedImage.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> parseOthers(dynamic raw) {
      if (raw is! Map<String, dynamic>) return <String, List<String>>{};
      final Map<String, List<String>> parsed = <String, List<String>>{};
      for (final MapEntry<String, dynamic> entry in raw.entries) {
        final dynamic list = entry.value;
        if (list is List) {
          parsed[entry.key] = list.whereType<String>().toList();
        }
      }
      return parsed;
    }

    return ProductCachedImage(
      productId: (json['product_id'] as num).toInt(),
      category: json['category'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      black: (json['black'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(),
      white: (json['white'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(),
      others: parseOthers(json['others']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'category': category,
      'model_name': modelName,
      'black': black,
      'white': white,
      'others': others,
    };
  }
}
