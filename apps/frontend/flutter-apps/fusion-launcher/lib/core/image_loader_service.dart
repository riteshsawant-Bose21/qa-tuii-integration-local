import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ImageLoaderService {
  final Map<String, ui.Image> _cache = <String, ui.Image>{};

  /// Loads an image from either assets or file system
  /// Automatically detects the source based on the path
  Future<ui.Image> loadImage(String imagePath) async {
    if (_cache.containsKey(imagePath)) {
      return _cache[imagePath]!;
    }

    ui.Image image;

    if (_isAssetPath(imagePath)) {
      image = await _loadAssetImage(imagePath);
    } else {
      image = await _loadFileImage(imagePath);
    }

    _cache[imagePath] = image;
    return image;
  }

  /// Loads an image specifically from assets
  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Loads an image from the file system
  Future<ui.Image> _loadFileImage(String filePath) async {
    final Directory dir = await FusionUtils.getFusionAppDirectory();
    final File file = File("${dir.path}/$filePath");

    if (!await file.exists()) {
      throw Exception('Image file not found: $filePath');
    }

    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<void> deleteImageFile(String imagePath) async {
    if (!_isAssetPath(imagePath)) {
      final Directory dir = await FusionUtils.getFusionAppDirectory();
      final File file = File("${dir.path}/$imagePath");

      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted image file: $imagePath');
      } else {
        debugPrint('Image file not found for deletion: $imagePath');
      }
    } else {
      debugPrint('Cannot delete asset images: $imagePath');
    }
  }

  /// Determines if a path is an asset path or file path
  static bool _isAssetPath(String path) {
    return path.startsWith('assets/') || path.startsWith('packages/');
  }

  /// Gets a cached image if available
  ui.Image? getCached(String imagePath) => _cache[imagePath];

  /// Preloads an image into the cache
  Future<void> preloadImage(String imagePath) async {
    if (!_cache.containsKey(imagePath)) {
      await loadImage(imagePath);
    }
  }

  /// Clears a specific image from cache
  void clearFromCache(String imagePath) {
    final ui.Image? image = _cache.remove(imagePath);
    image?.dispose();
  }

  /// Clears all cached images
  void clearCache() {
    for (final ui.Image image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  /// Gets the cache size (number of cached images)
  int get cacheSize => _cache.length;

  /// Checks if an image exists (for file paths)
  Future<bool> imageExists(String imagePath) async {
    if (_isAssetPath(imagePath)) {
      try {
        await rootBundle.load(imagePath);
        return true;
      } catch (e) {
        return false;
      }
    } else {
      return await File(imagePath).exists();
    }
  }

  /// Loads an image with error handling and fallback
  Future<ui.Image?> loadImageSafe(String imagePath, {String? fallbackAssetPath}) async {
    try {
      return await loadImage(imagePath);
    } catch (e) {
      debugPrint('Failed to load image: $imagePath, Error: $e');

      if (fallbackAssetPath != null) {
        try {
          return await loadImage(fallbackAssetPath);
        } catch (fallbackError) {
          debugPrint('Failed to load fallback image: $fallbackAssetPath, Error: $fallbackError');
        }
      }

      return null;
    }
  }

  /// Loads multiple images concurrently
  Future<List<ui.Image?>> loadMultipleImages(List<String> imagePaths) async {
    final List<Future<ui.Image?>> futures = imagePaths.map((String path) => loadImageSafe(path)).toList();

    return await Future.wait(futures);
  }

  /// Gets image dimensions without fully loading (for optimization)
  Future<Size?> getImageDimensions(String imagePath) async {
    try {
      Uint8List bytes;

      if (_isAssetPath(imagePath)) {
        final ByteData data = await rootBundle.load(imagePath);
        bytes = data.buffer.asUint8List();
      } else {
        final File file = File(imagePath);
        if (!await file.exists()) return null;
        bytes = await file.readAsBytes();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final Size size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();

      return size;
    } catch (e) {
      debugPrint('Failed to get image dimensions for: $imagePath, Error: $e');
      return null;
    }
  }
}
