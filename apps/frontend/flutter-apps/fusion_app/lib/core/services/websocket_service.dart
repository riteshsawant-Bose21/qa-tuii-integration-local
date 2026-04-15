import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/audio_utils.dart';

class FusionWebSocketService {

  FusionWebSocketService._internal();

  static final FusionWebSocketService _instance = FusionWebSocketService._internal();

  factory FusionWebSocketService() => _instance;



  String _host = '';
  String get host => _host;

  /// Calculates the correct WebSocket URL based on the platform.
  Uri get _url {
    return Uri.parse('ws://$_host:8080/ws');
  }

  WebSocketChannel? _channel;

  final _audioUpdateController =
  StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get audioUpdateStream =>
      _audioUpdateController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  bool _isConnecting = false;
  bool _shouldReconnect = true;

  void subscribe(String key){
    _channel!.sink.add(jsonEncode({
      "id": key,
      "version": 1,
      "type": "config"
    }
    ));
  }


  Future<void> connect({String? host}) async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _shouldReconnect = true;

    if (host != null) {
      _host = host;
    }

    try {
      print('Connecting to Fusion WebSocket: $_url');
      _channel = WebSocketChannel.connect(_url);

      // Wait for the connection to be established
      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;

      _connectionStatusController.add(true);
      print('Connected to Fusion WebSocket: $_url');

      _channel!.stream.listen(
            (message) {
              print("Fusion Web Service : Received");

          _handleMessage(message);
        },
        onDone: () {
          _isConnected = false;

          _connectionStatusController.add(false);
          print('Fusion WebSocket connection closed');
          // Reconnection delay if intentional
          if (_shouldReconnect) {
            Future.delayed(const Duration(seconds: 5), () => connect());
          }
        },
        onError: (error) {
          _isConnected = false;
          _connectionStatusController.add(false);
          print('Fusion WebSocket error: $error');
          // Reconnection is handled by onDone usually, but sometimes onError
          // fires without onDone.
        },
      );
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatusController.add(false);
      print('Failed to connect to Fusion WebSocket: $e');
      // Retry after delay if initial connection fails
      if (_shouldReconnect) {
        Future.delayed(const Duration(seconds: 5), () => connect());
      }
    }
  }

  /// Closes the connection and stops automatic reconnection.
  void disconnect() {
    _shouldReconnect = false;
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    _connectionStatusController.add(false);
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      log(data['type'].toString());
      if(data['type']=="error"){
       log(data.toString());
      }

    //  log(data['data']!['settings']!['audio'].toString());

      // Handle config_update (Full state sync)
      if (data['type'] == 'config_update') {
        final audioSettings =
        data['data']?['settings']?['audio'];
        if (audioSettings != null) {
          _audioUpdateController.add(audioSettings);
        }
      }

      // Handle patch_success (Optional confirmation)
      if (data['type'] == 'patch_success') {
        print('Server Patch Successful');
      }
    } catch (e) {
      print('Error parsing message from Fusion server: $e');
    }
  }

  /// Sends a gain update to the server.
  /// [gainID] is the key from the zone's gain configuration.
  /// [uiVolume] is expected to be 0.0 - 100.0 (UI scale).
  void sendGainPatch(String id,String gainID, double uiVolume) {
    final dbGain = AudioUtils.volumeToDbGain(uiVolume / 100.0);
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final patch = {
      "id": id,
      "version": 1,
      "type": "patch_config",
      "data": {
        "settings": {
          "audio": {
            gainID: {"gain": dbGain,"mute": false,"timestamp":timestamp}
          }
        }
      }
    };

    _send(patch);
  }

  /// Sends a mute update to the server.
  void sendMutePatch(String gainID, bool isMuted) {
    final patch = {
      "type": "patch",
      "data": {
        "settings": {
          "audio": {
            gainID: {"mute": isMuted}
          }
        }
      }
    };

    _send(patch);
  }

  /// Sends a source selector update to the server.
  void sendSourceSelectorPatch(int selectorID, int sourceIndex) {
    final patch = {
      "type": "patch",
      "data": {
        "settings": {
          "audio": {
            selectorID.toString(): {"sourceSelector": sourceIndex}
          }
        }
      }
    };

    _send(patch);
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      print('Send Message: WebSocket Message Sent');
      _channel!.sink.add(jsonEncode(data));
    } else {
      print('Send Message: WebSocket not connected');
    }
  }

  // No longer needed, moved to AudioUtils

  void dispose() {
    _channel?.sink.close();
    _audioUpdateController.close();
    _connectionStatusController.close();
  }
}