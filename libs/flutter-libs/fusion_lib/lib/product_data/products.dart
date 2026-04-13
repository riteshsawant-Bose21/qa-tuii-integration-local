import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;

import 'data_sources/product_catalog.dart';
import 'models/models.dart';

// Cache key used with AppCacheService for the products JSON catalog.
const _kCatalogCacheKey = 'products_catalog';

/// Holds cached local file paths for a product's images, keyed by color.
///
/// All paths are absolute on-disk paths inside the app's cache directory.
/// An empty list means no images are cached for that color.
class ProductImageCache {
  final int productId;
  final String modelName;
  final String category;

  /// Absolute local paths for black-finish images (may be empty).
  final List<String> black;

  /// Absolute local paths for white-finish images (may be empty).
  final List<String> white;

  /// Absolute local paths for any other finish, keyed by lowercase color name.
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
    final String key = color.toLowerCase();
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
/// ### Priority order
/// ```
/// 1. API   → save JSON via AppCacheService + download images to disk
/// 2. Cache → load JSON from AppCacheService + resolve already-downloaded images
/// 3. ZIP   → extract bundled ZIP (only when loadFromZip = true)
/// 4. Empty → isLoaded = false
/// ```
///
/// ### Usage
/// ```dart
/// final products = Products(
///   baseUrl: 'http://localhost:8080',
///   networkClient: client,
///   cacheService: await AppCacheService.create(namespace: 'products'),
/// );
/// await products.initialize();
///
/// final paths = products.imagePathsFor(productId: 801332);
/// ```
class Products {
  Products({
    required this.baseUrl,
    required this.networkClient,
    required this.cacheService,
    this.cacheDir,
    this.fusionOnly = false,
    this.loadFromZip = false,
    this.productCacheZipAssetPath = 'assets/zip/product_cache.zip',
  });

  final String baseUrl;
  final FusionNetworkClient networkClient;

  /// Injected cache service — used exclusively for the JSON catalog.
  final AppCacheService cacheService;

  /// Override the images root directory (useful in tests).
  /// When null, uses `<appSupportDir>/products/`.
  final String? cacheDir;

  /// When true, list getters filter to Fusion-compatible products only.
  final bool fusionOnly;

  /// When true, fall back to the bundled ZIP if API and cache both miss.
  final bool loadFromZip;

  /// Flutter asset path of the bundled ZIP.
  final String productCacheZipAssetPath;

  // ── internal state ────────────────────────────────────────────────────────

  ProductCatalog? _catalog;
  bool _syncedFromApi = false;

  /// url → absolute local image path (only entries that exist on disk).
  final Map<String, String> _urlToAbsPath = {};

  /// productId → ProductImageCache
  final Map<int, ProductImageCache> _imageByProductId = {};

  /// Lazily resolved: `<appSupportDir>/products/`
  String? _imagesRootDir;

  // ── public: status ────────────────────────────────────────────────────────

  bool get isLoaded => _catalog != null;
  bool get wasSyncedFromApi => _syncedFromApi;
  String get version => _catalog?.version ?? '';

  int get totalCount =>
      fusionOnly ? speakers.length + amplifiers.length + controllers.length + dsps.length + accessories.length + ioEndpoints.length : _catalog?.totalCount ?? 0;

  // ── public: product lists ─────────────────────────────────────────────────

  List<SpeakerProduct> get speakers => _filter(_catalog?.speakers, (s) => s.isFusionCompatible);

  List<AmplifierProduct> get amplifiers => _filter(_catalog?.amplifiers, (a) => a.isFusionCompatible);

  List<ControllerProduct> get controllers => _filter(_catalog?.controllers, (c) => c.isFusionCompatible);

  List<DspProduct> get dsps => _filter(_catalog?.dsps, (d) => d.isFusionCompatible);

  List<AccessoryProduct> get accessories => _filter(_catalog?.accessories, (a) => a.isFusionCompatible);

  List<IoEndpointProduct> get ioEndpoints => _filter(_catalog?.ioEndpoints, (e) => e.isFusionCompatible);

  // ── public: individual product lookups ────────────────────────────────────

  SpeakerProduct? getSpeaker(int id) => _findById(speakers, (s) => s.productId == id);

  AmplifierProduct? getAmplifier(int id) => _findById(amplifiers, (a) => a.productId == id);

  ControllerProduct? getController(int id) => _findById(controllers, (c) => c.productId == id);

  DspProduct? getDsp(int id) => _findById(dsps, (d) => d.productId == id);

  AccessoryProduct? getAccessory(int id) => _findById(accessories, (a) => a.productId == id);

  IoEndpointProduct? getIoEndpoint(int id) => _findById(ioEndpoints, (e) => e.productId == id);

  // ── public: image access ──────────────────────────────────────────────────

  /// Full [ProductImageCache] for [productId], or null if unknown.
  ProductImageCache? imageFor({required int productId}) => _imageByProductId[productId];

  /// Cached absolute local paths for [productId].
  /// [color] is case-insensitive; defaults to `'black'`.
  List<String> imagePathsFor({required int productId, String color = 'black'}) => _imageByProductId[productId]?.pathsForColor(color) ?? const [];

  /// First available image path for [productId], or null.
  String? firstImagePathFor({required int productId}) => _imageByProductId[productId]?.firstPath;

  // ── public: lifecycle ─────────────────────────────────────────────────────

  /// Must be called once before accessing any data.
  Future<void> initialize() => _load();

  /// Forces a fresh sync — re-calls the API and re-downloads everything.
  Future<void> refresh() => _load();

  // ── public: cache management ──────────────────────────────────────────────

  /// True if a cached catalog exists (may be expired).
  Future<bool> hasCachedData() => cacheService.containsKey(_kCatalogCacheKey);

  /// Clears the JSON catalog from AppCacheService and all image files.
  Future<void> clearCache() async {
    await cacheService.remove(_kCatalogCacheKey);
    await _ensureImagesRootDir();
    final dir = Directory(_imagesRootDir!);
    if (await dir.exists()) await dir.delete(recursive: true);
    _catalog = null;
    _syncedFromApi = false;
    _urlToAbsPath.clear();
    _imageByProductId.clear();
  }

  // ── core load pipeline ────────────────────────────────────────────────────

  Future<void> _load() async {
    await _ensureImagesRootDir();

    // 1. Try API
    if (await _syncFromApi()) {
      _syncedFromApi = true;
      return;
    }
    _syncedFromApi = false;

    // 2. Try local cache (AppCacheService JSON + already-downloaded images)
    if (await _loadFromCache()) return;

    // 3. Try bundled ZIP (optional — for demos / offline testing)
    if (loadFromZip && await _loadFromZip()) return;

    // Nothing worked
    _catalog = null;
    _imageByProductId.clear();
    FusionLogger.log(
      tag: LogTag.project,
      message: 'Products: all load strategies exhausted — no data available.',
    );
  }

  // ── strategy 1: API ───────────────────────────────────────────────────────

  Future<bool> _syncFromApi() async {
    try {
      final response = await networkClient.get<Map<String, dynamic>>(
        api: FusionApiEndpoint.products,
        fromJson: (dynamic data) => data as Map<String, dynamic>,
      );

      if (!response.success || response.data == null) {
        FusionLogger.log(
          tag: LogTag.project,
          message: 'Products: API returned failure — ${response.message}',
        );
        return false;
      }

      final json = response.data!;

      // Parse catalog first — if this throws the JSON is malformed.
      _catalog = ProductCatalog.fromJson(json);

      // Persist JSON via AppCacheService (no TTL = lives until explicitly cleared).
      await cacheService.setJson(
        _kCatalogCacheKey,
        json,
        // Optional: set a TTL if you want the catalog to auto-expire, e.g.:
        // ttl: const Duration(days: 7),
      );

      // Download images (network available).
      await _downloadImages(json);

      // Build productId → image map now that all files are on disk.
      _rebuildImageMap(json);

      FusionLogger.log(
        tag: LogTag.project,
        message:
            'Products: synced from API. '
            'Catalog version: ${_catalog?.version}',
      );
      return true;
    } catch (e, st) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Products: API sync error — $e\n$st',
      );
      return false;
    }
  }

  // ── strategy 2: AppCacheService (JSON) + disk (images) ───────────────────

  Future<bool> _loadFromCache() async {
    try {
      // AppCacheService handles corruption, expiry, and missing keys.
      final json = await cacheService.getJson<Map<String, dynamic>>(
        _kCatalogCacheKey,
        (raw) => raw is Map<String, dynamic> ? raw : null,
        // Pass allowExpired: true if you want the cache to serve stale data
        // rather than falling through to ZIP when TTL has elapsed.
        // allowExpired: true,
      );

      if (json == null) return false;

      _catalog = ProductCatalog.fromJson(json);

      // Resolve only images already on disk — no network calls.
      _resolveImagesFromDisk(json);
      _rebuildImageMap(json);

      FusionLogger.log(
        tag: LogTag.project,
        message:
            'Products: loaded from cache. '
            'Catalog version: ${_catalog?.version}',
      );
      return true;
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Products: cache load failed — $e',
      );
      return false;
    }
  }

  // ── strategy 3: bundled ZIP ───────────────────────────────────────────────

  Future<bool> _loadFromZip() async {
    try {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Products: extracting bundled ZIP…',
      );

      await _extractZip();

      // After extraction, products.json sits at the images-root alongside
      // the assets/ folder. Read it directly (not via AppCacheService —
      // the ZIP is a read-only bundle, not a user cache).
      final jsonFile = File(_zipJsonPath);
      if (!await jsonFile.exists()) {
        FusionLogger.log(
          tag: LogTag.project,
          message: 'Products: products.json not found after ZIP extraction.',
        );
        return false;
      }

      final raw = await jsonFile.readAsString();
      final json = _parseJsonMap(raw);
      if (json == null) return false;

      _catalog = ProductCatalog.fromJson(json);

      // Also push to AppCacheService so strategy 2 works on next launch.
      await cacheService.setJson(_kCatalogCacheKey, json);

      _resolveImagesFromDisk(json);
      _rebuildImageMap(json);

      FusionLogger.log(
        tag: LogTag.project,
        message:
            'Products: loaded from bundled ZIP. '
            'Catalog version: ${_catalog?.version}',
      );
      return true;
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Products: ZIP load failed — $e',
      );
      return false;
    }
  }

  // ── ZIP extraction ────────────────────────────────────────────────────────

  /// Extracts [productCacheZipAssetPath] into [_imagesRootDir].
  ///
  /// Expected ZIP layout (produced by generate_product_cache_zip.py):
  /// ```
  /// products.json
  /// version.txt        (optional)
  /// assets/
  ///   <base64url>.jpg
  ///   <base64url>.png
  /// ```
  Future<void> _extractZip() async {
    final data = await rootBundle.load(productCacheZipAssetPath);
    final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());

    for (final entry in archive) {
      final normalized = p.normalize(entry.name);
      // Guard against path-traversal.
      if (normalized.startsWith('..') || p.isAbsolute(normalized)) continue;

      final outPath = p.join(_imagesRootDir!, normalized);

      if (!entry.isFile) {
        await Directory(outPath).create(recursive: true);
        continue;
      }

      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      final content = entry.content;
      await outFile.writeAsBytes(content, flush: true);
    }
  }

  // ── image downloading ─────────────────────────────────────────────────────

  Future<void> _downloadImages(Map<String, dynamic> json) async {
    final urls = _collectImageUrls(json);
    if (urls.isEmpty) return;

    const batchSize = 6;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);
      await Future.wait(batch.map(_downloadIfNeeded));
    }
  }

  Future<void> _downloadIfNeeded(String url) async {
    if (!url.startsWith('http')) return;

    final destPath = _absPathForUrl(url);
    final destFile = File(destPath);

    // Already cached — just register the mapping.
    if (await destFile.exists()) {
      _urlToAbsPath[url] = destPath;
      return;
    }

    try {
      final uri = Uri.parse(url);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) return;

        await destFile.parent.create(recursive: true);
        final sink = destFile.openWrite();
        await response.pipe(sink);
        await sink.close();

        _urlToAbsPath[url] = destPath;
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      // Non-fatal: image simply won't be available.
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Products: failed to download image $url — $e',
      );
    }
  }

  // ── image path resolution (cache / ZIP strategies) ────────────────────────

  /// Scans JSON for image URLs and maps each to its on-disk path
  /// without any network access. Only existing files are registered.
  void _resolveImagesFromDisk(Map<String, dynamic> json) {
    _urlToAbsPath.clear();
    for (final url in _collectImageUrls(json)) {
      if (!url.startsWith('http')) continue;
      final absPath = _absPathForUrl(url);
      if (File(absPath).existsSync()) {
        _urlToAbsPath[url] = absPath;
      }
    }
  }

  // ── image map rebuild ─────────────────────────────────────────────────────

  /// Rebuilds [_imageByProductId] from [json] using [_urlToAbsPath].
  /// Call this AFTER all image caching/resolution is complete.
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

    FusionLogger.log(
      tag: LogTag.project,
      message:
          'Products: image map ready — '
          '${_imageByProductId.length} products.',
    );
  }

  /// Returns `{ color → [absLocalPath, …] }` for a single product JSON object.
  /// URLs without a local cached file are omitted.
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

  /// Derives a stable, unique absolute path under `<imagesRootDir>/assets/`
  /// for [url]. The filename is a base64url hash of the URL, preserving
  /// the original extension.
  ///
  /// This must stay in sync with the Python script's `url_to_zip_entry_name()`.
  String _absPathForUrl(String url) {
    final uri = Uri.parse(url);
    final ext = p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.img';
    final encoded = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
    return p.join(_imagesRootDir!, 'assets', '$encoded$ext');
  }

  // ── JSON helpers ──────────────────────────────────────────────────────────

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

  Future<void> _ensureImagesRootDir() async {
    if (_imagesRootDir != null) return;

    if (cacheDir != null && cacheDir!.trim().isNotEmpty) {
      _imagesRootDir = p.join(cacheDir!, 'products');
    } else {
      final appDir = await FusionUtils.getFusionAppDirectory();
      _imagesRootDir = p.join(appDir.path, 'products');
    }

    await Directory(_imagesRootDir!).create(recursive: true);
    await Directory(p.join(_imagesRootDir!, 'assets')).create(recursive: true);
  }

  /// Where products.json lands after ZIP extraction.
  String get _zipJsonPath => p.join(_imagesRootDir!, 'products.json');

  // ── utilities ─────────────────────────────────────────────────────────────

  List<T> _filter<T>(List<T>? source, bool Function(T) fusionPredicate) {
    if (source == null) return const [];
    if (!fusionOnly) return source;
    return source.where(fusionPredicate).toList();
  }

  T? _findById<T>(Iterable<T> items, bool Function(T) predicate) {
    for (final item in items) {
      if (predicate(item)) return item;
    }
    return null;
  }
}
