import 'package:dio/dio.dart';

import 'product_catalog.dart';

/// Result of a remote fetch operation
class RemoteFetchResult {
  /// True if data was modified (200 OK), false if not modified (304)
  final bool isModified;

  /// The catalog data (null if not modified)
  final ProductCatalog? catalog;

  const RemoteFetchResult({
    required this.isModified,
    this.catalog,
  });

  /// Creates a result for unchanged data
  factory RemoteFetchResult.notModified() =>
      const RemoteFetchResult(isModified: false);

  /// Creates a result with new data
  factory RemoteFetchResult.modified(ProductCatalog catalog) =>
      RemoteFetchResult(isModified: true, catalog: catalog);
}

/// Remote data source for product data
///
/// Handles communication with the product catalog API.
/// Supports version-based synchronization to minimize network usage.
class ProductRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  ProductRemoteDataSource({
    required String baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  /// Fetch products from the API
  ///
  /// If [currentVersion] is provided, the server may return 304 Not Modified
  /// if the data hasn't changed.
  ///
  /// Returns [RemoteFetchResult] with:
  /// - isModified: true if new data available, false if cache is still valid
  /// - catalog: the product catalog (null if not modified)
  Future<RemoteFetchResult> fetchProducts({String? currentVersion}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/v1/products',
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (currentVersion != null) 'If-None-Match': currentVersion,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        return RemoteFetchResult.notModified();
      }

      // Handle successful response
      if (response.statusCode == 200 && response.data != null) {
        final catalog = ProductCatalog.fromJson(response.data!);
        return RemoteFetchResult.modified(catalog);
      }

      // Handle other status codes
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected status code: ${response.statusCode}',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '$_baseUrl/api/v1/products'),
        message: 'Failed to parse response: $e',
      );
    }
  }

  /// Check if the API is reachable
  Future<bool> isReachable() async {
    try {
      final response = await _dio.get<dynamic>(
        '$_baseUrl/api/v1/products',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200 || response.statusCode == 304;
    } catch (e) {
      return false;
    }
  }
}
