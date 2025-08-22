import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide LogLevel;
import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:mutex/mutex.dart';

import '../../../models/response_callback.dart';
import '../ble_charateristics.dart';
import '../ble_communication_error.dart';
import '../ble_connection_manager.dart';
import '../ble_helper.dart';
import 'ble_command_store.dart';
import 'ble_response_parser.dart';
import 'fusion_commands.dart';

class FusionBleCommandsImpl implements FusionBleCommands {
  Timer? timeoutTimer;

  static Completer<bool>? responseCompleter;

  static final Mutex _mutex = Mutex();

  static StreamSubscription<List<int>>? syncSubscription;

  void handleBleException(String exception, String remoteId) {
    FusionLogger.log(tag: LogTag.ble, message: "BLE Exception is $exception");
    if (exception.contains("service not found") || exception.contains("device is not connected")) {
      if (BleConnectionManager().getDevice() != null && BleConnectionManager().getDevice()!.isConnected) {
        FusionLogger.log(tag: LogTag.ble, message: "Device is connected, Calling list service !!");
        BleConnectionManager.listServices(BleConnectionManager().getDevice()!);
      } else {
        FusionLogger.log(tag: LogTag.ble, message: "Device is disconnected, Calling setUpBleConnection !!");
        BleConnectionManager().initialize(remoteId);
      }
    }
  }

  Future<String?> writeValueAndReturnResponseFromSensorControl({
    required Characteristics characterName,
    required List<int> command,
    required String remoteId,
    required Command commandName,
    bool waitForResponse = true,
  }) async {
    //_mutext ensures that since call is being made at a given time
    return await _mutex.protect(() async {
      final BluetoothDevice device = BluetoothDevice.fromId(remoteId);
      final Completer<String?> responseCompleter = Completer<String?>();
      FusionLogger.log(tag: LogTag.ble, message: "Entered for command: ${commandName.name} : $command");

      final BluetoothCharacteristic characteristic = BleCharacteristics.getCharacteristic(characteristicsName: characterName, remoteId: remoteId);

      if (syncSubscription != null) {
        await syncSubscription?.cancel();
      }

      syncSubscription = characteristic.onValueReceived.listen((List<int> value) async {
        final String bleResponse = String.fromCharCodes(value);
        FusionLogger.log(tag: LogTag.ble, message: "Response received for ${commandName.name} $command : $bleResponse ");
        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(bleResponse);
        } else {
          FusionLogger.log(tag: LogTag.ble, message: "Future already completed for ${commandName.name} $command : $bleResponse ");
        }
        if (syncSubscription != null) {
          await syncSubscription?.cancel();
        }
      });

      if (syncSubscription != null) {
        device.cancelWhenDisconnected(syncSubscription!);
      }

      await characteristic.setNotifyValue(true);

      await characteristic.write(command, withoutResponse: true, allowLongWrite: false, timeout: 15);
      String? bleResponse;
      try {
        if (waitForResponse) {
          bleResponse = await responseCompleter.future.timeout(const Duration(seconds: 15));
        } else {
          bleResponse = "command written!";
        }
      } on TimeoutException {
        bleResponse = null;
      }
      if (syncSubscription != null) {
        await syncSubscription?.cancel();
      }
      FusionLogger.log(tag: LogTag.ble, message: "Response is: ${commandName.name} : $bleResponse ");
      return bleResponse;
    });
  }

  // Configuration fusion_acoustic_calculation_engine
  static const int _maxChunkSize = 180;
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const Duration _chunkDelay = Duration(milliseconds: 10);

  bool _isListening = false;

  /// Dispose resources and cleanup
  Future<void> dispose() async {
    await _stopListening();
  }

  /// Sends a request and waits for response with improved error handling
  Future<Map<String, dynamic>> sendRequest(Uint8List command, {Duration? timeout}) async {
    final Duration requestTimeout = timeout ?? _requestTimeout;
    final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();

    final String remoteId = BleConnectionManager().getDeviceRemoteId()!;
    final BluetoothCharacteristic characteristic = BleCharacteristics.getCharacteristic(characteristicsName: Characteristics.fusionControl, remoteId: remoteId);
    try {
      // Start listening for responses
      await _startListening(completer, characteristic);

      // Send the request
      await _sendChunkedRequest(command, characteristic);

      // Wait for response with timeout
      return await completer.future.timeout(
        requestTimeout,
        onTimeout: () async {
          await _stopListening();
          throw TimeoutException('No response received within ${requestTimeout.inSeconds}s', requestTimeout);
        },
      );
    } catch (e) {
      await _stopListening();
      rethrow;
    }
  }

  /// Sends request data in chunks to handle BLE MTU limitations
  Future<void> _sendChunkedRequest(Uint8List requestData, BluetoothCharacteristic characteristic) async {
    FusionLogger.log(message: 'Sending request: ${utf8.decode(requestData)}', tag: LogTag.ble);

    // Send data in chunks
    for (int i = 0; i < requestData.length; i += _maxChunkSize) {
      final int end = (i + _maxChunkSize < requestData.length) ? i + _maxChunkSize : requestData.length;

      final Uint8List chunk = requestData.sublist(i, end);

      await characteristic.write(chunk, withoutResponse: true);

      // Small delay to prevent overwhelming the BLE stack
      if (i + _maxChunkSize < requestData.length) {
        await Future<void>.delayed(_chunkDelay);
      }
    }
  }

  /// Starts listening for BLE responses
  Future<void> _startListening(Completer<Map<String, dynamic>> completer, BluetoothCharacteristic characteristic) async {
    if (_isListening) {
      await _stopListening();
    }

    final _ResponseBuffer responseBuffer = _ResponseBuffer();

    syncSubscription = characteristic.onValueReceived.listen(
      (List<int> data) => _handleIncomingData(data, responseBuffer, completer),
      onError: (Object error, StackTrace stackTrace) {
        FusionLogger.log(message: 'BLE subscription error: $error - ${stackTrace.toString()}', tag: LogTag.ble);
        if (!completer.isCompleted) {
          completer.completeError(BLECommunicationException('BLE error: $error'));
        }
      },
      cancelOnError: true,
    );

    characteristic.setNotifyValue(true);

    _isListening = true;
  }

  /// Stops listening for BLE responses
  Future<void> _stopListening() async {
    await syncSubscription?.cancel();
    syncSubscription = null;
    _isListening = false;
  }

  /// Handles incoming BLE data and processes complete JSON objects
  void _handleIncomingData(List<int> data, _ResponseBuffer buffer, Completer<Map<String, dynamic>> completer) {
    if (data.isEmpty || completer.isCompleted) return;

    try {
      final String fragment = utf8.decode(data);
      buffer.addFragment(fragment);

      // Process all complete JSON objects in buffer
      while (buffer.hasCompleteJson()) {
        final String? jsonStr = buffer.extractNextJson();
        if (jsonStr != null) {
          _processJsonResponse(jsonStr, buffer, completer);
        }
      }
    } catch (e) {
      FusionLogger.log(message: 'Error processing incoming data: $e', tag: LogTag.ble, logLevel: LogLevel.error);
      // Continue processing - don't fail on single malformed packet
    }
  }

  /// Processes a complete JSON response
  void _processJsonResponse(String jsonStr, _ResponseBuffer buffer, Completer<Map<String, dynamic>> completer) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);

      if (decoded is! Map<String, dynamic>) {
        FusionLogger.log(message: 'Received non-object JSON: $decoded', tag: LogTag.ble, logLevel: LogLevel.warning);
        return;
      }

      // Handle chunked responses
      if (decoded.containsKey('data') && decoded.containsKey('last')) {
        final String chunkData = decoded['data'] as String;
        final bool isLast = decoded['last'] as bool;

        buffer.addChunk(chunkData);

        if (isLast) {
          final String completeResponseJson = buffer.getCompleteResponse();
          final Map<String, dynamic> completeResponse = jsonDecode(completeResponseJson);

          if (!completer.isCompleted) {
            completer.complete(completeResponse);
          }
        }
      } else {
        // Handle direct (non-chunked) responses
        if (!completer.isCompleted) {
          completer.complete(decoded);
        }
      }
    } catch (e) {
      FusionLogger.log(message: 'Error decoding JSON response: $e, JSON: $jsonStr', tag: LogTag.ble, logLevel: LogLevel.error);
      if (!completer.isCompleted) {
        completer.completeError(BLECommunicationException('JSON decode error: $e'));
      }
    }
  }

  void startTimeout(Duration timeoutDuration, Completer<bool> responseCompleter) {
    timeoutTimer = Timer(timeoutDuration, () async {});
  }

  void resetTimeout(Completer<bool> responseCompleter) {
    // Cancel the current timer and start a new one
    timeoutTimer?.cancel();
    startTimeout(const Duration(milliseconds: 2000), responseCompleter);
  }

  void stopListening() {
    // Clean up resources if needed
    // healthMetricSubscription?.cancel();
    timeoutTimer?.cancel();
  }

  @override
  Future<ResponseCallback<dynamic>> blinkLed() async {
    FusionLogger.log(tag: LogTag.ble, message: "blinkLed() ");

    final String remoteId = BleConnectionManager().getDeviceRemoteId()!;
    try {
      final List<int> command = BleCommandStore().getCommand(command: Command.blinkLed);
      throw UnimplementedError("Blink LED command is not implemented yet"); // Not implemented by fusion server side yet
    } catch (ex) {
      FusionLogger.log(tag: LogTag.ble, message: "Exception : Exception in blinkLED:  $ex");
      handleBleException(ex.toString(), remoteId);
      return ResponseCallback<dynamic>(success: false, message: "Unable to blinkLED $ex");
    }
  }

  @override
  Future<ResponseCallback<dynamic>> checkVipConfiguration() async {
    FusionLogger.log(tag: LogTag.ble, message: "checkVipConfiguration() called  ");

    final String remoteId = BleConnectionManager().getDeviceRemoteId()!;

    try {
      final Map<String, dynamic> param = <String, dynamic>{CommandParams.method: "GET", CommandParams.url: "${CommandParams.localHost}/devices/vip"};

      final Uint8List command = BleCommandStore().getCommand(command: Command.checkVip, param: param);

      final Map<String, dynamic> bleResponse = await sendRequest(command);

      FusionLogger.log(tag: LogTag.ble, message: "checkVipConfiguration() response is:  $bleResponse");
      return BleResponseParser().getResponse(command: Command.checkVip, params: bleResponse);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.ble, message: "Exception : Exception in checkVipConfiguration():  $ex");
      handleBleException(ex.toString(), remoteId);
      return ResponseCallback<dynamic>(success: false, message: "Unable to checkVipConfiguration() $ex");
    }
  }

  // @override
  // Future<ResponseCallback<List<FusionDeviceDetailsEntity>>> getAllFusionDevices() async {
  //   FusionLogger.log(tag: LogTag.ble, message: "getAllFusionDevices() called  ");
  //
  //   final String remoteId = BleConnectionManager().getDeviceRemoteId()!;
  //
  //   try {
  //     final Map<String, dynamic> param = <String, dynamic>{
  //       CommandParams.method: "GET",
  //       CommandParams.url: "${CommandParams.localHost}/devices",
  //     };
  //
  //     final Uint8List command = BleCommandStore().getCommand(command: Command.getFusionDevices, param: param);
  //
  //     final Map<String, dynamic> bleResponse = await sendRequest(command);
  //
  //     FusionLogger.log(tag: LogTag.ble, message: "getAllFusionDevices() response is:  $bleResponse");
  //
  //     final ResponseCallback<dynamic> deviceResponse = BleResponseParser().getResponse(command: Command.getFusionDevices, params: bleResponse);
  //
  //     if (deviceResponse.success) {
  //       return ResponseCallback<List<FusionDeviceDetailsEntity>>(
  //         success: true,
  //         message: deviceResponse.message,
  //         data: (deviceResponse.data as List<dynamic>).map((dynamic e) => FusionDeviceDetailsEntity.fromJson(e)).toList(),
  //       );
  //     } else {
  //       FusionLogger.log(tag: LogTag.ble, message: "Failed to get all devices: ${deviceResponse.message}");
  //       return ResponseCallback<List<FusionDeviceDetailsEntity>>(
  //         success: false,
  //         message: deviceResponse.message,
  //         data: <FusionDeviceDetailsEntity>[],
  //       );
  //     }
  //   } catch (ex) {
  //     FusionLogger.log(tag: LogTag.ble, message: "Exception : Exception in getAllFusionDevices():  $ex");
  //     handleBleException(ex.toString(), remoteId);
  //     return ResponseCallback<List<FusionDeviceDetailsEntity>>(
  //       success: false,
  //       message: "Unable to getAllFusionDevices() $ex",
  //       data: <FusionDeviceDetailsEntity>[],
  //     );
  //   }
  // }
  //
  // @override
  // Future<ResponseCallback<dynamic>> getFusionDeviceDetails(String deviceId) async {
  //   FusionLogger.log(tag: LogTag.ble, message: "getFusionDeviceDetails() called for deviceId: $deviceId");
  //
  //   final String remoteId = BleConnectionManager().getDeviceRemoteId()!;
  //
  //   try {
  //     final ResponseCallback<dynamic> allDevicesResponse = await getAllFusionDevices();
  //     if (!allDevicesResponse.success) {
  //       FusionLogger.log(tag: LogTag.ble, message: "Failed to get all devices: ${allDevicesResponse.message}");
  //       return allDevicesResponse;
  //     }
  //     if (allDevicesResponse.data == null || allDevicesResponse.data is! List) {
  //       FusionLogger.log(tag: LogTag.ble, message: "Invalid response data format: ${allDevicesResponse.data}");
  //       return ResponseCallback<dynamic>(success: false, message: "Invalid response data format");
  //     }
  //     final List<dynamic> devices = allDevicesResponse.data as List<dynamic>;
  //     final dynamic deviceDetails = devices.firstWhere(
  //       (dynamic device) => device['id'] == deviceId,
  //       orElse: () => null,
  //     );
  //
  //     if (deviceDetails == null) {
  //       FusionLogger.log(tag: LogTag.ble, message: "Device with ID $deviceId not found");
  //       return ResponseCallback<dynamic>(success: false, message: "Device with ID $deviceId not found");
  //     } else {
  //       FusionLogger.log(tag: LogTag.ble, message: "Device details found for ID $deviceId: $deviceDetails");
  //       return ResponseCallback<dynamic>(success: true, data: deviceDetails, message: "Device details found for ID $deviceId");
  //     }
  //   } catch (ex) {
  //     FusionLogger.log(tag: LogTag.ble, message: "Exception : Exception in getFusionDeviceDetails():  $ex");
  //     handleBleException(ex.toString(), remoteId);
  //     return ResponseCallback<dynamic>(success: false, message: "Unable to getFusionDeviceDetails() $ex");
  //   }
  // }

  @override
  Future<ResponseCallback<dynamic>> updateFusionVIP(String vip) async {
    FusionLogger.log(tag: LogTag.ble, message: "updateFusionVIP for $vip  ");

    final String remoteId = BleConnectionManager().getDeviceRemoteId()!;

    try {
      if (vip.isEmpty) {
        return ResponseCallback<dynamic>(success: false, message: "VIP cannot be empty");
      }

      final Map<String, dynamic> param = <String, dynamic>{CommandParams.method: "POST", CommandParams.url: "${CommandParams.localHost}/devices/vip/$vip"};

      final Uint8List command = BleCommandStore().getCommand(command: Command.setVip, param: param);

      final Map<String, dynamic> bleResponse = await sendRequest(command);

      FusionLogger.log(tag: LogTag.ble, message: "updateFusionVIP response is:  $bleResponse");
      return BleResponseParser().getResponse(command: Command.setVip, params: bleResponse);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.ble, message: "Exception : Exception in updateFusionVIP:  $ex");
      handleBleException(ex.toString(), remoteId);
      return ResponseCallback<dynamic>(success: false, message: "Unable to updateFusionVIP $ex");
    }
  }
}

/// Helper class to manage response buffering and JSON parsing
class _ResponseBuffer {
  String _buffer = '';
  String _responseChunks = '';

  void addFragment(String fragment) {
    _buffer += fragment;
  }

  void addChunk(String chunk) {
    _responseChunks += chunk;
  }

  String getCompleteResponse() => _responseChunks;

  bool hasCompleteJson() {
    final int startIndex = _buffer.indexOf('{');
    if (startIndex == -1) return false;

    final int endIndex = _findClosingBrace(_buffer, startIndex);
    return endIndex != -1;
  }

  String? extractNextJson() {
    final int startIndex = _buffer.indexOf('{');
    if (startIndex == -1) {
      _buffer = '';
      return null;
    }

    final int endIndex = _findClosingBrace(_buffer, startIndex);
    if (endIndex == -1) {
      return null; // Incomplete JSON
    }

    final String jsonStr = _buffer.substring(startIndex, endIndex + 1);
    _buffer = _buffer.substring(endIndex + 1);
    return jsonStr;
  }

  /// Finds the matching closing brace for JSON starting at [start]
  int _findClosingBrace(String s, int start) {
    int braceCount = 0;
    bool inString = false;
    bool escape = false;

    for (int i = start; i < s.length; i++) {
      final String char = s[i];

      if (inString) {
        if (escape) {
          escape = false;
        } else if (char == r'\') {
          escape = true;
        } else if (char == '"') {
          inString = false;
        }
      } else {
        switch (char) {
          case '"':
            inString = true;
            break;
          case '{':
            braceCount++;
            break;
          case '}':
            braceCount--;
            if (braceCount == 0) return i;
            break;
        }
      }
    }
    return -1; // No complete JSON object found
  }
}
