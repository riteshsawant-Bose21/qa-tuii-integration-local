import 'dart:io';

import 'package:dio/dio.dart';

import '../data_sources/local_data_source.dart';

/// Service for caching product images locally
///
/// Downloads images from URLs and stores them locally for offline access.
/// Provides local file paths that can be used instead of remote URLs.
class ProductImageCacheService {
  final Dio _dio;
  final ProductLocalDataSource _localDataSource;

  ProductImageCacheService({
    required ProductLocalDataSource localDataSource,
    Dio? dio,
  })  : _localDataSource = localDataSource,
        _dio = dio ?? Dio();

  /// Get the local file path for a cached image
  ///
  /// Returns null if the image is not cached.
  Future<String?> getLocalImagePath(String imageUrl) async {
    try {
      final fileName = _getFileNameFromUrl(imageUrl);
      final imagesDir = await _localDataSource.getImagesCacheDir();
      final file = File('${imagesDir.path}/$fileName');

      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download and cache an image from URL
  ///
  /// Returns the local file path if successful, null otherwise.
  Future<String?> cacheImage(String imageUrl) async {
    try {
      final fileName = _getFileNameFromUrl(imageUrl);
      final imagesDir = await _localDataSource.getImagesCacheDir();
      final filePath = '${imagesDir.path}/$fileName';
      final file = File(filePath);

      // Skip if already cached
      if (await file.exists()) {
        return filePath;
      }

      // Download the image
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data != null) {
        await file.writeAsBytes(response.data!);
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache multiple images
  ///
  /// Returns a map of original URL to local file path.
  /// Failed downloads are not included in the result.
  Future<Map<String, String>> cacheImages(List<String> imageUrls) async {
    final results = <String, String>{};

    for (final url in imageUrls) {
      final localPath = await cacheImage(url);
      if (localPath != null) {
        results[url] = localPath;
      }
    }

    return results;
  }

  /// Check if an image is cached
  Future<bool> isImageCached(String imageUrl) async {
    final localPath = await getLocalImagePath(imageUrl);
    return localPath != null;
  }

  /// Clear all cached images
  Future<void> clearImageCache() async {
    try {
      final imagesDir = await _localDataSource.getImagesCacheDir();
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        await imagesDir.create(); // Recreate empty directory
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Get file name from URL
  String _getFileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    // Fallback: hash the URL
    return '${url.hashCode}.jpg';
  }

  /// Get the image path - returns local if cached, otherwise remote URL
  Future<String> getImagePath(String imageUrl) async {
    final localPath = await getLocalImagePath(imageUrl);
    return localPath ?? imageUrl;
  }
}
