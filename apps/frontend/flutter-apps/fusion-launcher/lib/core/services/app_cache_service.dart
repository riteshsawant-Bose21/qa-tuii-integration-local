import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// App-wide persistent cache service.
///
/// Why this exists:
/// - centralizes disk cache behavior in one place,
/// - gives TTL-based expiration,
/// - prevents duplicate concurrent fetches,
/// - and keeps cache IO safe with a mutex + atomic writes.
class AppCacheService {
  static const int _schemaVersion = 1;
  static const String _binaryTypeTag = '__binary_base64__';

  final Directory _cacheRootDirectory;
  final Mutex _mutex = Mutex();
  final Map<String, Future<dynamic>> _inFlightFetches = <String, Future<dynamic>>{};

  /// Private constructor to force initialization through [create].
  AppCacheService._(this._cacheRootDirectory);

  /// Creates a cache service rooted inside app support directory.
  ///
  /// Why this exists:
  /// - ensures the cache location is OS-safe and persistent,
  /// - avoids ad-hoc cache paths across features.
  static Future<AppCacheService> create({String namespace = 'app_cache'}) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory cacheDir = Directory(p.join(appSupportDir.path, namespace));
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return AppCacheService._(cacheDir);
  }

  /// Stores any JSON-serializable value under [key].
  ///
  /// Why this exists:
  /// - records metadata (timestamps, schema version),
  /// - supports optional TTL expiration,
  /// - writes atomically to avoid partial files.
  Future<void> setJson(String key, Object? value, {Duration? ttl}) async {
    await _withLock(() async {
      final DateTime now = DateTime.now().toUtc();
      final DateTime? expiresAt = ttl == null ? null : now.add(ttl);

      final DateTime createdAt = (await _readCreatedAtIfAny(key)) ?? now;
      final Map<String, dynamic> envelope = <String, dynamic>{
        'schemaVersion': _schemaVersion,
        'key': key,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'data': value,
      };

      await _writeEnvelopeAtomically(key, envelope);
    });
  }

  /// Reads a cached JSON value by [key].
  ///
  /// Why this exists:
  /// - supports typed decoding via [decoder],
  /// - auto-evicts expired entries,
  /// - optionally allows reading expired entries for fallback flows.
  Future<T?> getJson<T>(
    String key,
    T? Function(Object? json)? decoder, {
    bool allowExpired = false,
  }) async {
    return _withLock<T?>(() async {
      final Map<String, dynamic>? envelope = await _readEnvelope(key);
      if (envelope == null) return null;

      if (!allowExpired && _isExpired(envelope)) {
        await _deleteFileIfExists(_fileForKey(key));
        return null;
      }

      final Object? data = envelope['data'];
      return decoder == null ? data as T? : decoder(data);
    });
  }

  /// Returns cached value when available; otherwise fetches, stores, and returns.
  ///
  /// Why this exists:
  /// - provides read-through cache behavior,
  /// - avoids thundering-herd calls using in-flight dedupe per key.
  Future<T> getOrSet<T>({
    required String key,
    required Future<T> Function() fetch,
    required Object? Function(T value) encoder,
    required T Function(Object? json) decoder,
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final T? cached = await getJson<T>(key, decoder);
      if (cached != null) return cached;
    }

    final Future<T> inFlight =
        _inFlightFetches[key] as Future<T>? ??
        (() async {
          final T fresh = await fetch();
          await setJson(key, encoder(fresh), ttl: ttl);
          return fresh;
        })();

    _inFlightFetches[key] = inFlight;
    try {
      return await inFlight;
    } finally {
      _inFlightFetches.remove(key);
    }
  }

  /// Convenience wrapper for storing a string value.
  Future<void> setString(String key, String value, {Duration? ttl}) => setJson(key, value, ttl: ttl);

  /// Convenience wrapper for reading a string value.
  Future<String?> getString(String key, {bool allowExpired = false}) => getJson<String>(key, (Object? json) => json as String?, allowExpired: allowExpired);

  /// Stores binary data as base64 in JSON envelope.
  ///
  /// Why this exists:
  /// - keeps a single storage format (JSON files),
  /// - still supports image/blob-like payloads.
  Future<void> setBytes(String key, Uint8List value, {Duration? ttl}) {
    return setJson(
      key,
      <String, dynamic>{
        'type': _binaryTypeTag,
        'value': base64Encode(value),
      },
      ttl: ttl,
    );
  }

  /// Reads binary data previously stored via [setBytes].
  Future<Uint8List?> getBytes(String key, {bool allowExpired = false}) {
    return getJson<Uint8List>(
      key,
      (Object? json) {
        if (json is! Map<String, dynamic>) return null;
        if (json['type'] != _binaryTypeTag) return null;
        final String? encoded = json['value'] as String?;
        if (encoded == null || encoded.isEmpty) return null;
        return base64Decode(encoded);
      },
      allowExpired: allowExpired,
    );
  }

  /// Checks whether a non-expired cache entry exists for [key].
  Future<bool> containsKey(String key) async {
    return _withLock<bool>(() async {
      final Map<String, dynamic>? envelope = await _readEnvelope(key);
      if (envelope == null) return false;
      if (_isExpired(envelope)) {
        await _deleteFileIfExists(_fileForKey(key));
        return false;
      }
      return true;
    });
  }

  /// Returns cache metadata without decoding data payload.
  ///
  /// Why this exists:
  /// - useful for diagnostics, stale checks, and observability.
  Future<CacheEntryMetadata?> getMetadata(String key) async {
    return _withLock<CacheEntryMetadata?>(() async {
      final Map<String, dynamic>? envelope = await _readEnvelope(key);
      if (envelope == null) return null;
      return CacheEntryMetadata(
        key: envelope['key'] as String? ?? key,
        createdAt: _parseIsoDate(envelope['createdAt']),
        updatedAt: _parseIsoDate(envelope['updatedAt']),
        expiresAt: _parseIsoDate(envelope['expiresAt']),
      );
    });
  }

  /// Updates metadata timestamps/TTL without replacing payload.
  ///
  /// Why this exists:
  /// - supports sliding-expiration style scenarios.
  Future<void> touch(String key, {Duration? ttl}) async {
    await _withLock(() async {
      final Map<String, dynamic>? envelope = await _readEnvelope(key);
      if (envelope == null) return;
      final DateTime now = DateTime.now().toUtc();
      envelope['updatedAt'] = now.toIso8601String();
      envelope['expiresAt'] = ttl == null ? null : now.add(ttl).toIso8601String();
      await _writeEnvelopeAtomically(key, envelope);
    });
  }

  /// Deletes one cache key if present.
  Future<void> remove(String key) async {
    await _withLock(() async {
      await _deleteFileIfExists(_fileForKey(key));
    });
  }

  /// Deletes all cached entries for this namespace.
  Future<void> clearAll() async {
    await _withLock(() async {
      if (await _cacheRootDirectory.exists()) {
        await _cacheRootDirectory.delete(recursive: true);
      }
      await _cacheRootDirectory.create(recursive: true);
    });
  }

  /// Deletes cached entries whose sanitized key starts with [prefix].
  ///
  /// Why this exists:
  /// - enables group invalidation (for example, `products_` keys).
  Future<void> clearByPrefix(String prefix) async {
    await _withLock(() async {
      if (!await _cacheRootDirectory.exists()) return;
      final String safePrefix = _safeKeyFor(prefix);

      await for (final FileSystemEntity entity in _cacheRootDirectory.list()) {
        if (entity is! File) continue;
        if (p.basenameWithoutExtension(entity.path).startsWith(safePrefix)) {
          await entity.delete();
        }
      }
    });
  }

  /// Scans cache folder and removes expired/corrupted entries.
  /// Returns number of deleted files.
  Future<int> evictExpired() async {
    return _withLock<int>(() async {
      if (!await _cacheRootDirectory.exists()) return 0;
      int removed = 0;

      await for (final FileSystemEntity entity in _cacheRootDirectory.list()) {
        if (entity is! File || p.extension(entity.path) != '.json') continue;
        try {
          final String raw = await entity.readAsString();
          final dynamic parsed = jsonDecode(raw);
          if (parsed is! Map<String, dynamic>) {
            await entity.delete();
            removed++;
            continue;
          }
          if (_isExpired(parsed)) {
            await entity.delete();
            removed++;
          }
        } catch (_) {
          await entity.delete();
          removed++;
        }
      }
      return removed;
    });
  }

  /// Maps a logical cache key to a file path.
  File _fileForKey(String key) {
    final String safeKey = _safeKeyFor(key);
    return File(p.join(_cacheRootDirectory.path, '$safeKey.json'));
  }

  /// Sanitizes key so it is always filesystem-safe.
  String _safeKeyFor(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  /// Reads and parses an envelope for a key.
  ///
  /// Why this exists:
  /// - isolates corruption handling,
  /// - auto-cleans invalid entries.
  Future<Map<String, dynamic>?> _readEnvelope(String key) async {
    final File file = _fileForKey(key);
    if (!await file.exists()) return null;

    try {
      final String contents = await file.readAsString();
      final dynamic decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) {
        await _deleteFileIfExists(file);
        return null;
      }
      return decoded;
    } catch (error, stackTrace) {
      debugPrint('AppCacheService read failed for key "$key": $error\n$stackTrace');
      await _deleteFileIfExists(file);
      return null;
    }
  }

  /// Returns true if envelope has expired based on [expiresAt].
  bool _isExpired(Map<String, dynamic> envelope) {
    final DateTime? expiresAt = _parseIsoDate(envelope['expiresAt']);
    return expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt);
  }

  /// Writes envelope through temp file + rename for atomicity.
  ///
  /// Why this exists:
  /// - avoids partially written JSON on app crash/kill.
  Future<void> _writeEnvelopeAtomically(String key, Map<String, dynamic> envelope) async {
    final File file = _fileForKey(key);
    await file.parent.create(recursive: true);

    final File tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(envelope), flush: true);

    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  /// Reads original creation timestamp if key already exists.
  ///
  /// Why this exists:
  /// - preserves first-seen timestamp across updates.
  Future<DateTime?> _readCreatedAtIfAny(String key) async {
    final Map<String, dynamic>? envelope = await _readEnvelope(key);
    return envelope == null ? null : _parseIsoDate(envelope['createdAt']);
  }

  /// Deletes file only when it exists.
  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Executes cache IO under a mutex to avoid race conditions.
  Future<T> _withLock<T>(Future<T> Function() task) async {
    await _mutex.acquire();
    try {
      return await task();
    } finally {
      _mutex.release();
    }
  }

  /// Parses ISO datetime safely, returns null for invalid values.
  DateTime? _parseIsoDate(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}

/// Metadata exposed for each cache entry.
///
/// Why this exists:
/// - lets callers inspect freshness/aging without reading full payload.
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

  /// Whether this entry is currently past its expiry timestamp.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!);
  }
}
