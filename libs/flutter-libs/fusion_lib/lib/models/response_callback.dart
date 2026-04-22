class ResponseCallback<T> {
  final bool success;
  final String message;
  final int? statusCode;
  final T? data;

  ResponseCallback({required this.success, required this.message, this.statusCode, this.data});

  factory ResponseCallback.fromJson(dynamic json, T Function(Map<String, dynamic>)? fromJsonT) {
    // Determine success flag, defaulting to true if absent but data structure is unwrapped
    final bool success = json is Map<String, dynamic> ? json['error'] == null : true;

    // Extract message (or default to empty string)
    final String message = json is Map<String, dynamic> ? json['error'] : '';

    // Unwrap payload: either the 'data' field or the whole json
    final dynamic payload = switch (json) {
      Map<String, dynamic> map when map.containsKey('data') => map['data'],
      Map<String, dynamic> map => map,
      _ => json,
    };

    // Apply transformer if provided, otherwise cast payload to T
    final T? data = fromJsonT != null ? ((payload != null && payload.isNotEmpty) ? fromJsonT(payload) : null) : payload as T;

    final int? statusCode = json is Map<String, dynamic> ? json['statusCode'] : null;

    return ResponseCallback<T>(success: success, message: message, statusCode: statusCode, data: data);
  }

  factory ResponseCallback.success(T? data, {String message = '', int? statusCode}) => ResponseCallback<T>(
    success: true,
    message: message,
    data: data,
    statusCode: statusCode,
  );

  factory ResponseCallback.failure(String message, {T? data, int? statusCode}) => ResponseCallback<T>(
    success: false,
    message: message,
    data: data,
    statusCode: statusCode,
  );
}
