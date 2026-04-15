import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;

import 'data_sources/product_catalog.dart';
import 'models/models.dart';

const _kCatalogCacheKey = 'products_catalog';

/// Holds cached local file paths for a product's images, keyed by color.
class ProductImageCache {
  final int productId;
  final String modelName;
  final String category;
  final List<String> black;
  final List<String> white;
  final Map<String, List<String>> others;

  const ProductImageCache({
    required this.productId,
    required this.modelName,
    required this.category,
    required this.black,
    required this.white,
    required this.others,
  });

  /// Returns paths for [color] (case-insensitive). Falls back to black.
  List<String> pathsForColor(String color) {
    final key = color.toLowerCase();
    if (key == 'black') return black;
    if (key == 'white') return white;
    return others[key] ?? black;
  }

  /// First available path across all colors, or null.
  String? get firstPath {
    if (black.isNotEmpty) return black.first;
    if (white.isNotEmpty) return white.first;
    for (final paths in others.values) {
      if (paths.isNotEmpty) return paths.first;
    }
    return null;
  }
}

/// Products API — offline-first product data access.
///
/// ### Folder layout (always under getApplicationSupportDirectory)
/// ```
/// <appSupport>/
///   app_cache/
///     products/               ← _imagesRootDir
///       assets/               ← downloaded / extracted images
///         <base64hash>.jpg
///         <base64hash>.png
/// ```
///
/// ### Priority order
/// ```
/// 1. API   → save JSON via AppCacheService + download images to assets/
/// 2. Cache → load JSON from AppCacheService + resolve images from assets/
/// 3. ZIP   → extract ZIP into products/ folder (only when loadFromZip=true)
/// 4. Empty → isLoaded = false
/// ```
class Products {
  Products({
    required this.baseUrl,
    required this.networkClient,
    required this.cacheService,
    this.fusionOnly = false,
    this.loadFromZip = false,
    this.productCacheZipAssetPath = 'assets/zip/product_cache.zip',
  });

  final String baseUrl;
  final FusionNetworkClient networkClient;

  /// Scoped cache service for this feature (app_cache/products/).
  /// Pass `await rootCache.scope('products')` from your DI setup.
  final AppCacheService cacheService;

  final bool fusionOnly;
  final bool loadFromZip;
  final String productCacheZipAssetPath;

  // ── internal state ────────────────────────────────────────────────────────

  ProductCatalog? _catalog;
  bool _syncedFromApi = false;

  /// url → absolute local image path (only entries confirmed to exist on disk).
  final Map<String, String> _urlToAbsPath = {};

  /// productId → ProductImageCache
  final Map<int, ProductImageCache> _imageByProductId = {};

  /// Resolved once in [_ensureRootDir]. Always uses getApplicationSupportDirectory.
  String? _imagesRootDir;

  // ── public: lifecycle ─────────────────────────────────────────────────────

  Future<void> initialize() => _load();
  Future<void> refresh() => _load();

  // ── public: status ────────────────────────────────────────────────────────

  bool get isLoaded => _catalog != null;
  bool get wasSyncedFromApi => _syncedFromApi;
  String get version => _catalog?.version ?? '';

  // ── public: product lists ─────────────────────────────────────────────────

  List<SpeakerProduct> get speakers => _filter(_catalog?.speakers, (s) => s.isFusionCompatible);
  List<AmplifierProduct> get amplifiers => _filter(_catalog?.amplifiers, (a) => a.isFusionCompatible);
  List<ControllerProduct> get controllers => _filter(_catalog?.controllers, (c) => c.isFusionCompatible);
  List<DspProduct> get dsps => _filter(_catalog?.dsps, (d) => d.isFusionCompatible);
  List<AccessoryProduct> get accessories => _filter(_catalog?.accessories, (a) => a.isFusionCompatible);
  List<IoEndpointProduct> get ioEndpoints => _filter(_catalog?.ioEndpoints, (e) => e.isFusionCompatible);

  // ── public: individual lookups ────────────────────────────────────────────

  SpeakerProduct? getSpeaker(int id) => _findById(speakers, (s) => s.productId == id);
  AmplifierProduct? getAmplifier(int id) => _findById(amplifiers, (a) => a.productId == id);
  ControllerProduct? getController(int id) => _findById(controllers, (c) => c.productId == id);
  DspProduct? getDsp(int id) => _findById(dsps, (d) => d.productId == id);
  AccessoryProduct? getAccessory(int id) => _findById(accessories, (a) => a.productId == id);
  IoEndpointProduct? getIoEndpoint(int id) => _findById(ioEndpoints, (e) => e.productId == id);

  // ── public: image access ──────────────────────────────────────────────────

  ProductImageCache? imageFor({required int productId}) => _imageByProductId[productId];

  List<String> imagePathsFor({required int productId, String color = 'black'}) => _imageByProductId[productId]?.pathsForColor(color) ?? const [];

  String? firstImagePathFor({required int productId}) => _imageByProductId[productId]?.firstPath;

  // ── public: cache management ──────────────────────────────────────────────

  Future<bool> hasCachedData() => cacheService.containsKey(_kCatalogCacheKey);

  Future<void> clearCache() async {
    await cacheService.remove(_kCatalogCacheKey);
    await _ensureRootDir();
    final assetsDir = Directory(_assetsDir);
    if (await assetsDir.exists()) {
      await assetsDir.delete(recursive: true);
    }
    _reset();
  }

  // ── core load pipeline ────────────────────────────────────────────────────

  Future<void> _load() async {
    await _ensureRootDir();

    _log('Starting load. imagesRootDir=$_imagesRootDir');

    if (await _syncFromApi()) {
      _syncedFromApi = true;
      return;
    }
    _syncedFromApi = false;

    if (await _loadFromCache()) return;

    if (loadFromZip && await _loadFromZip()) return;

    _reset();
    _log('All load strategies exhausted — no data available.');
  }

  // ── strategy 1: API ───────────────────────────────────────────────────────

  Future<bool> _syncFromApi() async {
    try {
      final response = await networkClient.get<Map<String, dynamic>>(
        api: FusionApiEndpoint.products,
        fromJson: (dynamic data) => data as Map<String, dynamic>,
      );

      if (!response.success || response.data == null) {
        _log('API returned failure — ${response.message}');
        return false;
      }

      final json = response.data!;
      _catalog = ProductCatalog.fromJson(json);

      await cacheService.setJson(_kCatalogCacheKey, json);
      await _downloadImages(json);
      _rebuildImageMap(json);

      _log(
        'Synced from API. version=${_catalog?.version} '
        'images=${_urlToAbsPath.length}',
      );
      return true;
    } catch (e, st) {
      _log('API sync error — $e\n$st');
      return false;
    }
  }

  // ── strategy 2: cache ─────────────────────────────────────────────────────

  Future<bool> _loadFromCache() async {
    try {
      final json = await cacheService.getJson<Map<String, dynamic>>(
        _kCatalogCacheKey,
        (raw) => raw is Map<String, dynamic> ? raw : null,
      );

      if (json == null) {
        _log('No cached catalog found.');
        return false;
      }

      _catalog = ProductCatalog.fromJson(json);
      _resolveImagesFromDisk(json);
      _rebuildImageMap(json);

      _log(
        'Loaded from cache. version=${_catalog?.version} '
        'images=${_urlToAbsPath.length}',
      );
      return true;
    } catch (e) {
      _log('Cache load failed — $e');
      return false;
    }
  }

  // ── strategy 3: ZIP ───────────────────────────────────────────────────────

  Future<bool> _loadFromZip() async {
    try {
      _log('Extracting bundled ZIP…');
      await _extractZip();

      // products.json is extracted directly into _imagesRootDir
      final jsonFile = File(p.join(_imagesRootDir!, 'products.json'));
      if (!await jsonFile.exists()) {
        _log('products.json not found after ZIP extraction at ${jsonFile.path}');
        return false;
      }

      final raw = await jsonFile.readAsString();
      final json = _parseJsonMap(raw);
      if (json == null) {
        _log('products.json is not valid JSON after ZIP extraction.');
        return false;
      }

      _catalog = ProductCatalog.fromJson(json);

      // Promote to AppCacheService so next launch uses strategy 2.
      await cacheService.setJson(_kCatalogCacheKey, json);

      _resolveImagesFromDisk(json);
      _rebuildImageMap(json);

      _log(
        'Loaded from ZIP. version=${_catalog?.version} '
        'images=${_urlToAbsPath.length}',
      );
      return true;
    } catch (e, st) {
      _log('ZIP load failed — $e\n$st');
      return false;
    }
  }

  // ── ZIP extraction ────────────────────────────────────────────────────────

  /// Extracts ZIP into [_imagesRootDir].
  ///
  /// Expected ZIP layout (from generate_product_cache_zip.py):
  /// ```
  /// products.json
  /// assets/
  ///   <base64url>.jpg
  ///   <base64url>.png
  /// ```
  /// After extraction the folder looks like:
  /// ```
  /// <appSupport>/app_cache/products/
  ///   products.json
  ///   assets/
  ///     <base64url>.jpg
  /// ```
  Future<void> _extractZip() async {
    final data = await rootBundle.load(productCacheZipAssetPath);
    final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());

    int extracted = 0;
    for (final entry in archive) {
      final normalized = p.normalize(entry.name);

      // Guard against path-traversal attacks.
      if (normalized.startsWith('..') || p.isAbsolute(normalized)) {
        _log('Skipping unsafe ZIP entry: ${entry.name}');
        continue;
      }

      final outPath = p.join(_imagesRootDir!, normalized);

      if (!entry.isFile) {
        await Directory(outPath).create(recursive: true);
        continue;
      }

      final content = entry.content;

      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(content, flush: true);
      extracted++;
    }

    _log('ZIP extraction complete. $extracted files written to $_imagesRootDir');
  }

  // ── image downloading ─────────────────────────────────────────────────────

  Future<void> _downloadImages(Map<String, dynamic> json) async {
    final urls = _collectImageUrls(json);
    if (urls.isEmpty) return;

    _log('Downloading ${urls.length} images…');
    int downloaded = 0;
    int skipped = 0;

    const batchSize = 6;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);
      final results = await Future.wait(batch.map(_downloadIfNeeded));
      for (final wasNew in results) {
        if (wasNew)
          downloaded++;
        else
          skipped++;
      }
    }

    _log('Images: $downloaded downloaded, $skipped already cached.');
  }

  /// Returns true if the image was newly downloaded, false if already cached.
  Future<bool> _downloadIfNeeded(String url) async {
    if (!url.startsWith('http')) return false;

    final destPath = _absPathForUrl(url);
    final destFile = File(destPath);

    if (await destFile.exists()) {
      _urlToAbsPath[url] = destPath;
      return false;
    }

    try {
      final uri = Uri.parse(url);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          _log('HTTP ${response.statusCode} for $url');
          return false;
        }
        await destFile.parent.create(recursive: true);
        final sink = destFile.openWrite();
        await response.pipe(sink);
        await sink.close();
        _urlToAbsPath[url] = destPath;
        return true;
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      _log('Failed to download $url — $e');
      return false;
    }
  }

  // ── image resolution (no network) ────────────────────────────────────────

  /// Maps URLs to on-disk paths without any network access.
  /// Only URLs whose derived path actually exists on disk are registered.
  void _resolveImagesFromDisk(Map<String, dynamic> json) {
    _urlToAbsPath.clear();
    int found = 0;
    int missing = 0;

    for (final url in _collectImageUrls(json)) {
      if (!url.startsWith('http')) continue;
      final absPath = _absPathForUrl(url);
      if (File(absPath).existsSync()) {
        _urlToAbsPath[url] = absPath;
        found++;
      } else {
        missing++;
      }
    }

    _log('Image resolution: $found found on disk, $missing missing.');
  }

  // ── image map rebuild ─────────────────────────────────────────────────────

  void _rebuildImageMap(Map<String, dynamic> json) {
    _imageByProductId.clear();

    for (final entry in json.entries) {
      final category = entry.key;
      final products = entry.value;
      if (products is! List) continue;

      for (final product in products) {
        if (product is! Map<String, dynamic>) continue;

        final idRaw = product['product_id'];
        if (idRaw is! num) continue;
        final productId = idRaw.toInt();

        final colorMap = _extractColorPaths(product);
        final black = colorMap.remove('black') ?? const [];
        final white = colorMap.remove('white') ?? const [];

        _imageByProductId[productId] = ProductImageCache(
          productId: productId,
          modelName: product['model_name'] as String? ?? '',
          category: category,
          black: black,
          white: white,
          others: Map.unmodifiable(colorMap),
        );
      }
    }

    _log('Image map built for ${_imageByProductId.length} products.');
  }

  Map<String, List<String>> _extractColorPaths(Map<String, dynamic> product) {
    final result = <String, List<String>>{};
    final assetsRaw = product['assets'];
    if (assetsRaw is! List) return result;

    for (final group in assetsRaw) {
      if (group is! Map<String, dynamic>) continue;
      for (final colorEntry in group.entries) {
        final color = colorEntry.key.toLowerCase();
        final urlsRaw = colorEntry.value;
        if (urlsRaw is! List) continue;

        final paths = <String>[];
        for (final raw in urlsRaw.whereType<String>()) {
          final url = raw.trim();
          if (url.isEmpty) continue;
          if (url.startsWith('http')) {
            final local = _urlToAbsPath[url];
            if (local != null) paths.add(local);
          } else if (File(url).existsSync()) {
            paths.add(url);
          }
        }
        if (paths.isNotEmpty) result[color] = paths;
      }
    }
    return result;
  }

  // ── URL → deterministic local path ───────────────────────────────────────
  /// Derives a stable absolute path under `<_imagesRootDir>/assets/`.
  /// Filename = base64url(url) + original extension.
  ///
  /// Must stay in sync with Python script's url_to_zip_entry_name().
  String _absPathForUrl(String url) {
    final uri = Uri.parse(url);
    final ext = p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.img';
    final encoded = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
    return p.join(_assetsDir, '$encoded$ext');
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Set<String> _collectImageUrls(Map<String, dynamic> json) {
    final urls = <String>{};
    for (final products in json.values) {
      if (products is! List) continue;
      for (final product in products) {
        if (product is! Map<String, dynamic>) continue;
        final assetsRaw = product['assets'];
        if (assetsRaw is! List) continue;
        for (final group in assetsRaw) {
          if (group is! Map<String, dynamic>) continue;
          for (final urlsRaw in group.values) {
            if (urlsRaw is! List) continue;
            for (final url in urlsRaw.whereType<String>()) {
              final trimmed = url.trim();
              if (trimmed.startsWith('http')) urls.add(trimmed);
            }
          }
        }
      }
    }
    return urls;
  }

  Map<String, dynamic>? _parseJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ── directory management ──────────────────────────────────────────────────

  /// Always uses getApplicationSupportDirectory — sandboxed, persistent,
  /// correct on macOS/iOS/Android/Windows.
  ///
  /// macOS debug:   ~/Library/Containers/{bundle}/Data/Library/Application Support/
  /// macOS release: ~/Library/Containers/{bundle}/Data/Library/Application Support/
  /// iOS:           {app}/Library/Application Support/
  /// Android:       /data/data/{package}/files/
  Future<void> _ensureRootDir() async {
    if (_imagesRootDir != null) return;

    // Use cacheService.directoryPath — it's already scoped to app_cache/products/
    // so images land at: app_cache/products/assets/
    _imagesRootDir = cacheService.directoryPath;

    await Directory(_assetsDir).create(recursive: true);

    _log('imagesRootDir resolved to: $_imagesRootDir');
    _log('assetsDir: $_assetsDir');
  }

  String get _assetsDir => p.join(_imagesRootDir!, 'assets');

  void _reset() {
    _catalog = null;
    _syncedFromApi = false;
    _urlToAbsPath.clear();
    _imageByProductId.clear();
  }

  void _log(String message) => FusionLogger.log(tag: LogTag.project, message: 'Products: $message');

  List<T> _filter<T>(List<T>? source, bool Function(T) predicate) {
    if (source == null) return const [];
    if (!fusionOnly) return source;
    return source.where(predicate).toList();
  }

  T? _findById<T>(Iterable<T> items, bool Function(T) predicate) {
    for (final item in items) {
      if (predicate(item)) return item;
    }
    return null;
  }
}
