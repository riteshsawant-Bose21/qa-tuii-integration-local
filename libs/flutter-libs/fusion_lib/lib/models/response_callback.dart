class ResponseCallback<T> {
  final bool success;
  final String message;
  final T? data;

  ResponseCallback({required this.success, required this.message, this.data});

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

    return ResponseCallback<T>(success: success, message: message, data: data);
  }

  factory ResponseCallback.success(T? data, {String message = ''}) => ResponseCallback<T>(success: true, message: message, data: data);
  factory ResponseCallback.failure(String message, {T? data}) => ResponseCallback<T>(success: false, message: message, data: data);
}
