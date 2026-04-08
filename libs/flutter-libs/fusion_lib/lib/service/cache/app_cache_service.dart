import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// App-wide persistent cache service.
///
/// ### Folder structure
/// ```
/// <appSupport>/
///   app_cache/
///     products/
///       products_catalog.json
///     sessions/
///       session_token.json
///     …
/// ```
///
/// ### Usage
/// ```dart
/// // Singleton root — call once at startup (e.g. in your DI setup).
/// final cache = await AppCacheService.root();
///
/// // Scoped sub-cache — auto-creates the folder, zero boilerplate.
/// final productsCache = await cache.scope('products');
/// final sessionsCache = await cache.scope('sessions');
///
/// // Use exactly as before.
/// await productsCache.setJson('catalog', data);
/// final data = await productsCache.getJson('catalog', decoder);
/// ```
class AppCacheService {
  static const int _schemaVersion = 1;
  static const String _binaryTypeTag = '__binary_base64__';

  /// The directory this instance reads/writes from.
  final Directory _dir;
  final Mutex _mutex = Mutex();
  final Map<String, Future<dynamic>> _inFlightFetches = {};

  AppCacheService._(this._dir);

  // ── factories ─────────────────────────────────────────────────────────────

  /// Creates (or opens) the root `app_cache/` directory inside the app
  /// support directory. Call this once in your DI/service-locator setup
  /// and register the result as a singleton.
  ///
  /// ```dart
  /// final cache = await AppCacheService.root();
  /// GetIt.I.registerSingleton<AppCacheService>(cache);
  /// ```
  static Future<AppCacheService> root() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, 'app_cache'));
    await dir.create(recursive: true);
    return AppCacheService._(dir);
  }

  /// Returns a child [AppCacheService] scoped to `<current>/<name>/`.
  /// The folder is created automatically if it does not exist.
  ///
  /// [name] must be a simple folder name (no slashes).
  /// Nesting is supported:
  /// ```dart
  /// final deep = await cache.scope('products').then((c) => c.scope('images'));
  /// // resolves to: app_cache/products/images/
  /// ```
  Future<AppCacheService> scope(String name) async {
    assert(
      !name.contains('/') && !name.contains('\\'),
      'scope name must be a single folder name, not a path. Got: "$name"',
    );
    final child = Directory(p.join(_dir.path, name));
    await child.create(recursive: true);
    return AppCacheService._(child);
  }

  /// The absolute path of this cache scope's directory.
  /// Expose this so [Products] (or any consumer) can use it for
  /// raw file storage (e.g. binary image files) under the same root.
  String get directoryPath => _dir.path;

  // ── write ─────────────────────────────────────────────────────────────────

  /// Stores any JSON-serializable value under [key].
  Future<void> setJson(String key, Object? value, {Duration? ttl}) async {
    await _withLock(() async {
      final now = DateTime.now().toUtc();
      final expiresAt = ttl == null ? null : now.add(ttl);
      final createdAt = (await _readCreatedAtIfAny(key)) ?? now;

      final envelope = <String, dynamic>{
        'schemaVersion': _schemaVersion,
        'key': key,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'data': value,
      };

      await _writeAtomically(key, envelope);
    });
  }

  /// Convenience: store a plain string.
  Future<void> setString(String key, String value, {Duration? ttl}) => setJson(key, value, ttl: ttl);

  /// Stores binary data as base64 inside the JSON envelope.
  Future<void> setBytes(String key, Uint8List value, {Duration? ttl}) => setJson(
    key,
    {'type': _binaryTypeTag, 'value': base64Encode(value)},
    ttl: ttl,
  );

  // ── read ──────────────────────────────────────────────────────────────────

  /// Reads a cached value by [key].
  ///
  /// [decoder] converts the raw JSON payload to [T].
  /// Pass `allowExpired: true` to serve stale data as a fallback.
  Future<T?> getJson<T>(
    String key,
    T? Function(Object? json)? decoder, {
    bool allowExpired = false,
  }) => _withLock<T?>(() async {
    final envelope = await _readEnvelope(key);
    if (envelope == null) return null;

    if (!allowExpired && _isExpired(envelope)) {
      await _deleteIfExists(_fileForKey(key));
      return null;
    }

    final data = envelope['data'];
    return decoder == null ? data as T? : decoder(data);
  });

  /// Convenience: read a plain string.
  Future<String?> getString(String key, {bool allowExpired = false}) => getJson<String>(
    key,
    (json) => json as String?,
    allowExpired: allowExpired,
  );

  /// Reads binary data previously stored with [setBytes].
  Future<Uint8List?> getBytes(String key, {bool allowExpired = false}) => getJson<Uint8List>(
    key,
    (json) {
      if (json is! Map<String, dynamic>) return null;
      if (json['type'] != _binaryTypeTag) return null;
      final encoded = json['value'] as String?;
      if (encoded == null || encoded.isEmpty) return null;
      return base64Decode(encoded);
    },
    allowExpired: allowExpired,
  );

  // ── read-through ──────────────────────────────────────────────────────────

  /// Returns cached value when fresh; otherwise fetches, stores, and returns.
  /// Concurrent calls for the same [key] share a single in-flight fetch.
  Future<T> getOrSet<T>({
    required String key,
    required Future<T> Function() fetch,
    required Object? Function(T value) encoder,
    required T Function(Object? json) decoder,
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await getJson<T>(key, decoder);
      if (cached != null) return cached;
    }

    final inFlight =
        (_inFlightFetches[key] as Future<T>?) ??
        () async {
          final fresh = await fetch();
          await setJson(key, encoder(fresh), ttl: ttl);
          return fresh;
        }();

    _inFlightFetches[key] = inFlight;
    try {
      return await inFlight;
    } finally {
      _inFlightFetches.remove(key);
    }
  }

  // ── introspection ─────────────────────────────────────────────────────────

  /// True when a non-expired entry exists for [key].
  Future<bool> containsKey(String key) => _withLock<bool>(() async {
    final envelope = await _readEnvelope(key);
    if (envelope == null) return false;
    if (_isExpired(envelope)) {
      await _deleteIfExists(_fileForKey(key));
      return false;
    }
    return true;
  });

  /// Returns metadata for [key] without decoding the payload.
  Future<CacheEntryMetadata?> getMetadata(String key) => _withLock<CacheEntryMetadata?>(() async {
    final envelope = await _readEnvelope(key);
    if (envelope == null) return null;
    return CacheEntryMetadata(
      key: envelope['key'] as String? ?? key,
      createdAt: _parseDate(envelope['createdAt']),
      updatedAt: _parseDate(envelope['updatedAt']),
      expiresAt: _parseDate(envelope['expiresAt']),
    );
  });

  /// Refreshes timestamps without replacing the payload (sliding expiry).
  Future<void> touch(String key, {Duration? ttl}) => _withLock(() async {
    final envelope = await _readEnvelope(key);
    if (envelope == null) return;
    final now = DateTime.now().toUtc();
    envelope['updatedAt'] = now.toIso8601String();
    envelope['expiresAt'] = ttl == null ? null : now.add(ttl).toIso8601String();
    await _writeAtomically(key, envelope);
  });

  // ── deletion ──────────────────────────────────────────────────────────────

  /// Deletes one entry.
  Future<void> remove(String key) => _withLock(() => _deleteIfExists(_fileForKey(key)));

  /// Deletes all entries in this scope (leaves the directory itself intact).
  Future<void> clearAll() => _withLock(() async {
    await for (final e in _dir.list()) {
      if (e is File) await e.delete();
    }
  });

  /// Deletes all entries whose sanitised key starts with [prefix].
  Future<void> clearByPrefix(String prefix) => _withLock(() async {
    final safePrefix = _sanitise(prefix);
    await for (final e in _dir.list()) {
      if (e is File && p.basenameWithoutExtension(e.path).startsWith(safePrefix)) {
        await e.delete();
      }
    }
  });

  /// Scans and removes expired or corrupted entries.
  /// Returns the number of deleted files.
  Future<int> evictExpired() => _withLock<int>(() async {
    int removed = 0;
    await for (final e in _dir.list()) {
      if (e is! File || p.extension(e.path) != '.json') continue;
      try {
        final parsed = jsonDecode(await e.readAsString());
        if (parsed is! Map<String, dynamic> || _isExpired(parsed)) {
          await e.delete();
          removed++;
        }
      } catch (_) {
        await e.delete();
        removed++;
      }
    }
    return removed;
  });

  // ── private helpers ───────────────────────────────────────────────────────

  File _fileForKey(String key) => File(p.join(_dir.path, '${_sanitise(key)}.json'));

  String _sanitise(String key) => key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_').replaceAll(RegExp(r'_+'), '_');

  Future<Map<String, dynamic>?> _readEnvelope(String key) async {
    final file = _fileForKey(key);
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        await _deleteIfExists(file);
        return null;
      }
      return decoded;
    } catch (e, st) {
      debugPrint('AppCacheService: read failed for "$key": $e\n$st');
      await _deleteIfExists(file);
      return null;
    }
  }

  bool _isExpired(Map<String, dynamic> envelope) {
    final expiresAt = _parseDate(envelope['expiresAt']);
    return expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt);
  }

  Future<void> _writeAtomically(String key, Map<String, dynamic> envelope) async {
    final file = _fileForKey(key);
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(envelope), flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }

  Future<DateTime?> _readCreatedAtIfAny(String key) async {
    final envelope = await _readEnvelope(key);
    return envelope == null ? null : _parseDate(envelope['createdAt']);
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  Future<T> _withLock<T>(Future<T> Function() task) async {
    await _mutex.acquire();
    try {
      return await task();
    } finally {
      _mutex.release();
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}

/// Metadata for a cache entry (no payload).
class CacheEntryMetadata {
  final String key;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const CacheEntryMetadata({
    required this.key,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!);
  }
}
