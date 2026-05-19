import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;

import 'data_sources/product_catalog.dart';
import 'models/models.dart';
import 'models/output_product.dart';

const _kCatalogCacheKey = 'products_catalog';

enum ProductCategory {
  speaker('speaker'),
  amplifier('amplifier'),
  controller('controller'),
  dsp('dsp'),
  accessory('accessory'),
  ioEndpoint('io_endpoint'),
  source('source'),
  output('output');

  const ProductCategory(this.apiKey);

  final String apiKey;

  String get folderName {
    switch (this) {
      case ProductCategory.speaker:
        return 'speakers';
      case ProductCategory.amplifier:
        return 'amplifiers';
      case ProductCategory.controller:
        return 'controllers';
      case ProductCategory.dsp:
        return 'dsps';
      case ProductCategory.accessory:
        return 'accessories';
      case ProductCategory.ioEndpoint:
        return 'io_endpoints';
      case ProductCategory.source:
        return 'sources';
      case ProductCategory.output:
        return 'outputs';
    }
  }

  static ProductCategory? fromApiKey(String value) {
    final normalized = value.trim().toLowerCase();
    for (final category in ProductCategory.values) {
      if (category.apiKey == normalized) return category;
    }
    return null;
  }
}

/// Holds cached local file paths for a product's images, keyed by color.
class ProductImageCache {
  /// Stable ID value from payload (for example: product_id, source_id, id).
  final String entityId;

  /// Numeric representation of [entityId] when available.
  final int? productId;
  final String modelName;
  final ProductCategory category;
  final List<String> black;
  final List<String> white;
  final Map<String, List<String>> others;

  const ProductImageCache({
    required this.entityId,
    required this.productId,
    required this.modelName,
    required this.category,
    required this.black,
    required this.white,
    required this.others,
  });

  List<String> pathsForColor(String color) {
    final key = color.toLowerCase();
    if (key == 'black') return black;
    if (key == 'white') return white;
    return others[key] ?? black;
  }

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
/// ### Image file naming
/// Images are saved using their **original filename from the URL**.
/// e.g. `https://.../original/DM8S_Right-Facing.jpeg`
///      → `<assetsDir>/DM8S_Right-Facing.jpeg`
///
/// A small index file (`assets/_index.json`) maps each URL to its filename
/// so lookups are O(1) without touching the filesystem per image.
///
/// ### Priority order
/// ```
/// 1. API   → save JSON via AppCacheService + download images to assets/
/// 2. Cache → load JSON from AppCacheService + resolve images from assets/
/// 3. ZIP   → extract bundled ZIP (only when loadFromZip = true)
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
  final AppCacheService cacheService;
  final bool fusionOnly;
  final bool loadFromZip;
  final String productCacheZipAssetPath;

  // ── internal state ────────────────────────────────────────────────────────

  ProductCatalog? _catalog;
  bool _syncedFromApi = false;

  /// url → absolute local image path (only entries confirmed on disk).
  /// Persisted to `assets/_index.json` between launches.
  final Map<String, String> _urlToAbsPath = {};

  /// category::entityId → ProductImageCache
  final Map<String, ProductImageCache> _imageByEntityKey = {};

  /// `<AppCache>/products/` — set once in [_ensureRootDir].
  String? _rootDir;

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
  List<SourceProduct> get sources => _filter(_catalog?.sources, (s) => s.isFusionCompatible);
  List<OutputProduct> get outputs => _filter(_catalog?.outputs, (o) => true);

  // ── public: individual lookups ────────────────────────────────────────────

  SpeakerProduct? getSpeaker(int id) => _findById(speakers, (s) => s.productId == id);
  AmplifierProduct? getAmplifier(int id) => _findById(amplifiers, (a) => a.productId == id);
  ControllerProduct? getController(int id) => _findById(controllers, (c) => c.productId == id);
  DspProduct? getDsp(int id) => _findById(dsps, (d) => d.productId == id);
  AccessoryProduct? getAccessory(int id) => _findById(accessories, (a) => a.productId == id);
  IoEndpointProduct? getIoEndpoint(int id) => _findById(ioEndpoints, (e) => e.productId == id);
  SourceProduct? getSource(int id) => _findById(sources, (s) => s.sourceId == id);
  OutputProduct? getOutput(int id) => _findById(outputs, (o) => o.outputId == id);

  // ── public: image access ──────────────────────────────────────────────────

  /// Single source-of-truth image lookup.
  ///
  /// Always provide both category and entityId to avoid collisions.
  ProductImageCache? imageForEntity({required ProductCategory category, required String entityId}) => _imageByEntityKey[_imageKey(category, entityId)];

  List<String> imagePathsForEntity({required ProductCategory category, required String entityId, String color = 'black'}) {
    return imageForEntity(category: category, entityId: entityId)?.pathsForColor(color) ?? const [];
  }

  String? firstImagePathForEntity({required ProductCategory category, required String entityId}) =>
      imageForEntity(category: category, entityId: entityId)?.firstPath;

  // ── public: cache management ──────────────────────────────────────────────

  Future<bool> hasCachedData() => cacheService.containsKey(_kCatalogCacheKey);

  Future<void> clearCache() async {
    await cacheService.remove(_kCatalogCacheKey);
    await _ensureRootDir();
    final assetsDir = Directory(_assetsDir);
    if (await assetsDir.exists()) await assetsDir.delete(recursive: true);
    _reset();
  }

  // ── core load pipeline ────────────────────────────────────────────────────

  Future<void> _load() async {
    await _ensureRootDir();

    // 1. API
    if (await _syncFromApi()) {
      _syncedFromApi = true;
      return;
    }
    _syncedFromApi = false;

    // 2. Cache
    if (await _loadFromCache()) return;

    // 3. ZIP
    if (loadFromZip && await _loadFromZip()) return;

    _reset();
    _log('All load strategies exhausted.');
  }

  // ── strategy 1: API ───────────────────────────────────────────────────────

  Future<bool> _syncFromApi() async {
    try {
      final response = await networkClient.get<Map<String, dynamic>>(
        api: FusionApiEndpoint.products,
        fromJson: (dynamic data) => data as Map<String, dynamic>,
      );

      if (!response.success || response.data == null) {
        _log('API failure — ${response.message}');
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
      await _loadImageIndex(); // restore url→path map from index file
      _resolveImagesFromDisk(json); // verify files still exist
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

      // products.json is extracted into _rootDir
      final jsonFile = File(p.join(_rootDir!, 'products.json'));
      if (!await jsonFile.exists()) {
        _log('products.json not found after ZIP extraction.');
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

      // ZIP images are already in assets/ with original filenames.
      // Build index from what's on disk.
      _resolveImagesFromDisk(json);
      await _persistImageIndex();
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

  /// Expected ZIP layout (produced by generate_product_cache_zip.py):
  /// ```
  /// products.json
  /// assets/
  ///   DM8S_Right-Facing.jpeg        ← original filename, NOT hashed
  ///   DM8C_Flush_Group.jpeg
  ///   …
  /// ```
  /// After extraction the folder looks like:
  /// ```
  /// <appSupport>/AppCache/products/
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
      if (normalized.startsWith('..') || p.isAbsolute(normalized)) continue;

      final outPath = p.join(_rootDir!, normalized);

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

    _log('ZIP extracted $extracted files to $_rootDir');
  }

  // ── image downloading ─────────────────────────────────────────────────────

  Future<void> _downloadImages(Map<String, dynamic> json) async {
    final urlToCategory = _collectImageUrlsByCategory(json);
    if (urlToCategory.isEmpty) return;
    final entries = urlToCategory.entries.toList(growable: false);

    _log('Downloading ${entries.length} images…');
    int downloaded = 0;
    int skipped = 0;

    const batchSize = 6;
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = entries.skip(i).take(batchSize);
      final results = await Future.wait(
        batch.map((entry) => _downloadIfNeeded(entry.key, entry.value)),
      );
      for (final wasNew in results) {
        wasNew ? downloaded++ : skipped++;
      }
    }

    // Persist the url→filename index after all downloads complete.
    await _persistImageIndex();
    _log('Images: $downloaded downloaded, $skipped already cached.');
  }

  /// Returns true if newly downloaded, false if already on disk.
  Future<bool> _downloadIfNeeded(String url, ProductCategory category) async {
    if (!url.startsWith('http')) return false;

    final indexedPath = _urlToAbsPath[url];
    if (indexedPath != null && await File(indexedPath).exists()) return false;

    final destPath = _absPathForUrl(url, category);
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

  // ── image index (url → filename) ─────────────────────────────────────────

  /// Loads the persisted `assets/_index.json` into [_urlToAbsPath].
  Future<void> _loadImageIndex() async {
    _urlToAbsPath.clear();
    final indexFile = File(_imageIndexPath);
    if (!await indexFile.exists()) return;

    try {
      final decoded = jsonDecode(await indexFile.readAsString());
      if (decoded is! Map<String, dynamic>) return;

      decoded.forEach((url, path) {
        if (path is String) {
          _urlToAbsPath[url] = path;
        }
      });
    } catch (_) {
      _urlToAbsPath.clear();
    }
  }

  /// Saves [_urlToAbsPath] to `assets/_index.json`.
  Future<void> _persistImageIndex() async {
    try {
      await File(_imageIndexPath).writeAsString(jsonEncode(_urlToAbsPath), flush: true);
    } catch (e) {
      _log('Failed to persist image index — $e');
    }
  }

  // ── image resolution (no network) ────────────────────────────────────────

  /// Verifies that every URL in [_urlToAbsPath] (and in the JSON) still has
  /// its file on disk. Removes stale entries. Adds new ones if the file exists
  /// at the expected path even without an index entry.
  void _resolveImagesFromDisk(Map<String, dynamic> json) {
    int found = 0;
    int missing = 0;

    final urlToCategory = _collectImageUrlsByCategory(json);

    for (final entry in urlToCategory.entries) {
      final url = entry.key;
      final category = entry.value;
      if (!url.startsWith('http')) continue;

      final expected = _absPathForUrl(url, category);

      // Check existing index entry first.
      final indexed = _urlToAbsPath[url];
      if (indexed != null && File(indexed).existsSync()) {
        found++;
        continue;
      }

      // Fall back to computed path (covers ZIP case where index doesn't exist yet).
      if (File(expected).existsSync()) {
        _urlToAbsPath[url] = expected;
        found++;
      } else {
        _urlToAbsPath.remove(url);
        missing++;
      }
    }

    _log('Disk resolution: $found found, $missing missing.');
  }

  // ── image map rebuild ─────────────────────────────────────────────────────

  void _rebuildImageMap(Map<String, dynamic> json) {
    _imageByEntityKey.clear();

    for (final entry in json.entries) {
      final category = ProductCategory.fromApiKey(entry.key);
      if (category == null) continue;
      final products = entry.value;
      if (products is! List) continue;

      for (final product in products) {
        if (product is! Map<String, dynamic>) continue;

        final entityId = _extractEntityId(product);
        if (entityId == null) continue;

        final colorMap = _extractColorPaths(product);
        final black = colorMap.remove('black') ?? const [];
        final white = colorMap.remove('white') ?? const [];

        final image = ProductImageCache(
          entityId: entityId,
          productId: int.tryParse(entityId),
          modelName: product['model_name'] as String? ?? '',
          category: category,
          black: black,
          white: white,
          others: Map.unmodifiable(colorMap),
        );

        _imageByEntityKey[_imageKey(category, entityId)] = image;
      }
    }

    _log('Image map built for ${_imageByEntityKey.length} entries.');
  }

  String _imageKey(ProductCategory category, String entityId) => '${category.apiKey}::${entityId.trim()}';

  String? _extractEntityId(Map<String, dynamic> product) {
    final directId = _coerceEntityId(product['product_id']) ?? _coerceEntityId(product['source_id']) ?? _coerceEntityId(product['id']);
    if (directId != null) return directId;

    for (final entry in product.entries) {
      if (!entry.key.toLowerCase().endsWith('_id')) continue;
      final candidate = _coerceEntityId(entry.value);
      if (candidate != null) return candidate;
    }
    return null;
  }

  String? _coerceEntityId(dynamic value) {
    if (value is num) return value.toInt().toString();
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
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

  // ── URL → local path (original filename) ─────────────────────────────────

  /// Keeps the original filename from the URL.
  ///
  /// `https://.../original/DM8S_Right-Facing_1200x1022.jpeg`
  ///  → `<assetsDir>/DM8S_Right-Facing_1200x1022.jpeg`
  ///
  /// If two different URLs share the same filename (rare but possible),
  /// the second one gets a numeric suffix: `filename_2.jpeg`.
  String _absPathForUrl(String url, ProductCategory category) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final rawName = segments.isNotEmpty ? Uri.decodeComponent(segments.last) : 'image_${url.hashCode.abs()}';

    final candidate = p.join(_assetsDir, category.folderName, rawName);

    // Check if another URL already owns this filename.
    final existing = _urlToAbsPath.entries.where((e) => e.value == candidate && e.key != url).firstOrNull;

    if (existing == null) return candidate;

    // Conflict — append a suffix based on URL hash.
    final ext = p.extension(rawName);
    final base = p.basenameWithoutExtension(rawName);
    final suffix = url.hashCode.abs() % 9999;
    return p.join(_assetsDir, '${base}_$suffix$ext');
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Map<String, ProductCategory> _collectImageUrlsByCategory(
    Map<String, dynamic> json,
  ) {
    final urlToCategory = <String, ProductCategory>{};
    for (final entry in json.entries) {
      final category = ProductCategory.fromApiKey(entry.key);
      if (category == null) continue;

      final products = entry.value;
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
              if (trimmed.startsWith('http')) {
                urlToCategory.putIfAbsent(trimmed, () => category);
              }
            }
          }
        }
      }
    }
    return urlToCategory;
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

  Future<void> _ensureRootDir() async {
    if (_rootDir != null) return;

    // Use the scoped cache service directory — already points to
    // AppCache/products/ inside getApplicationSupportDirectory().
    _rootDir = cacheService.directoryPath;

    await Directory(_assetsDir).create(recursive: true);
    _log('Cached Root Directory=$_rootDir');
  }

  /// `<rootDir>/assets/` — where all image files live.
  String get _assetsDir => p.join(_rootDir!, 'assets');

  /// `<rootDir>/assets/_index.json` — url → absolute path map.
  String get _imageIndexPath => p.join(_assetsDir, '_index.json');

  void _reset() {
    _catalog = null;
    _syncedFromApi = false;
    _urlToAbsPath.clear();
    _imageByEntityKey.clear();
  }

  void _log(String message) => log(message);

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
