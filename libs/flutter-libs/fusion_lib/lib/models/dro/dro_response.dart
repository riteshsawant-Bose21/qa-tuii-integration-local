class DroResponseData {
  final String? requestId;
  final String? responseId;
  final String? error;
  final DroResultData? result;
  final int? statusCode;
  final String? statusMessage;
  final String? version;

  DroResponseData({
    this.requestId,
    this.responseId,
    this.error,
    this.result,
    this.statusCode,
    this.statusMessage,
    this.version,
  });

  //from json
  factory DroResponseData.fromJson(Map<String, dynamic> json) {
    return DroResponseData(
      requestId: json['request_id'],
      responseId: json['response_id'],
      error: json['error'] as String?,
      result: json['result'] != null ? DroResultData.fromJson(json['result'] as Map<String, dynamic>) : null,
      statusCode: json['status_code'],
      statusMessage: json['status_message'],
      version: json['version'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'response_id': responseId,
      'error': error,
      'result': result?.toJson(),
      'status_code': statusCode,
      'status_message': statusMessage,
      'version': version,
    };
  }

  //copy with
  DroResponseData copyWith({
    String? requestId,
    String? responseId,
    String? error,
    DroResultData? result,
    int? statusCode,
    String? statusMessage,
    String? version,
  }) {
    return DroResponseData(
      requestId: requestId ?? this.requestId,
      responseId: responseId ?? this.responseId,
      error: error ?? this.error,
      result: result ?? this.result,
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      version: version ?? this.version,
    );
  }
}

class DroResultData {
  final List<Map<String, dynamic>>? audioStreams;
  final List<Map<String, dynamic>>? deviceConnections;
  final List<Map<String, dynamic>>? devices;
  final String? imageInput;
  final String? imageOutput;
  final List<Map<String, dynamic>>? ioPorts;
  final List<Map<String, dynamic>>? latencies;
  final int? totalCost;

  DroResultData({
    this.audioStreams,
    this.devices,
    this.deviceConnections,
    this.imageInput,
    this.imageOutput,
    this.ioPorts,
    this.latencies,
    this.totalCost,
  });

  factory DroResultData.fromJson(Map<String, dynamic> json) {
    return DroResultData(
      audioStreams: (json['audio_streams'] as List<dynamic>?)?.map((dynamic e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList(),
      devices: (json['devices'] as List<dynamic>?)?.map((dynamic e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList(),
      deviceConnections: (json['device_connections'] as List<dynamic>?)?.map((dynamic e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList(),
      // imageInput: json['image_input'] as String?,
      // imageOutput: json['image_output'] as String?,
      ioPorts: (json['io_ports'] as List<dynamic>?)?.map((dynamic e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList(),
      // latencies: (json['latencies'] as List<dynamic>?)?.map((dynamic e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList(),
      totalCost: json['total_cost'] != null ? int.tryParse(json['total_cost'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_streams': audioStreams,
      'devices': devices,
      'image_input': imageInput,
      'image_output': imageOutput,
      'io_ports': ioPorts,
      'latencies': latencies,
      'total_cost': totalCost,
    };
  }

  //copy with
  DroResultData copyWith({
    List<Map<String, dynamic>>? audioStreams,
    List<Map<String, dynamic>>? devices,
    List<Map<String, dynamic>>? deviceConnections,
    String? imageInput,
    String? imageOutput,
    List<Map<String, dynamic>>? ioPorts,
    List<Map<String, dynamic>>? latencies,
    int? totalCost,
  }) {
    return DroResultData(
      audioStreams: audioStreams ?? this.audioStreams,
      devices: devices ?? this.devices,
      deviceConnections: deviceConnections ?? this.deviceConnections,
      imageInput: imageInput ?? this.imageInput,
      imageOutput: imageOutput ?? this.imageOutput,
      ioPorts: ioPorts ?? this.ioPorts,
      latencies: latencies ?? this.latencies,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}
