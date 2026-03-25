import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_catalog.dart';

/// Local data source for product data
///
/// Handles caching of product data to local storage and manages
/// version information using SharedPreferences.
class ProductLocalDataSource {
  static const String _versionKey = 'product_catalog_version';
  static const String _cacheFileName = 'products.json';
  static const String _cacheDirName = 'product_cache';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> _ensurePrefsInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the cache directory path
  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDirName');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Get the cache file
  Future<File> _getCacheFile() async {
    final cacheDir = await _getCacheDir();
    return File('${cacheDir.path}/$_cacheFileName');
  }

  /// Get the currently stored version
  Future<String?> getVersion() async {
    await _ensurePrefsInitialized();
    return _prefs!.getString(_versionKey);
  }

  /// Save the version string
  Future<void> saveVersion(String version) async {
    await _ensurePrefsInitialized();
    await _prefs!.setString(_versionKey, version);
  }

  /// Load cached product catalog from local storage
  Future<ProductCatalog?> loadCachedCatalog() async {
    try {
      final file = await _getCacheFile();

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProductCatalog.fromJson(json);
    } catch (e) {
      // If parsing fails, return null so we fetch fresh data
      return null;
    }
  }

  /// Save product catalog to local storage
  Future<void> saveCatalog(ProductCatalog catalog) async {
    try {
      final file = await _getCacheFile();
      final jsonString = jsonEncode(catalog.toJson());
      await file.writeAsString(jsonString);
      await saveVersion(catalog.version);
    } catch (e) {
      // Silently fail - caching is optional
      rethrow;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        await file.delete();
      }

      await _ensurePrefsInitialized();
      await _prefs!.remove(_versionKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if cache exists
  Future<bool> hasCachedData() async {
    final file = await _getCacheFile();
    return file.exists();
  }

  /// Get the images cache directory
  Future<Directory> getImagesCacheDir() async {
    final cacheDir = await _getCacheDir();
    final imagesDir = Directory('${cacheDir.path}/images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }
}
