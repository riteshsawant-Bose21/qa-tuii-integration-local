import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class WebSocketService {
  // Singleton pattern to ensure one instance across the app
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;



  String _host = '';
  String get host => _host;

  /// Calculates the correct WebSocket URL based on the platform.
  Uri get _url {
    return Uri.parse('ws://$_host:8080/ws');
  }


  // final _audioUpdateController =
  // StreamController<Map<String, dynamic>>.broadcast();
  // Stream<Map<String, dynamic>> get audioUpdateStream =>
  //     _audioUpdateController.stream;

  final StreamController _controller = StreamController.broadcast();
  Stream get stream => _controller.stream;


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



  Future<void> connect(String? host) async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _shouldReconnect = true;

    if (host != null) {
      _host = host;
    }

    try {
      print('Connecting to Fusion WebSocket: $host');
      _channel = WebSocketChannel.connect(_url);

      // Wait for the connection to be established
      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;

      _connectionStatusController.add(true);
      print('Connected to Fusion WebSocket: $host');

      _channel!.stream.listen(
            (message) {
          print("Fusion Web Service : Received");
          _controller.add(message);
        },
        onDone: () {
          _isConnected = false;

          _connectionStatusController.add(false);
          print('Fusion WebSocket connection closed');
          // Reconnection delay if intentional
          if (_shouldReconnect) {
            Future.delayed(const Duration(seconds: 5), () => connect(host!));
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
        Future.delayed(const Duration(seconds: 5), () => connect(host!));
      }
    }
  }


  void sendMessage(dynamic message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(message);
    } else {
      debugPrint("Cannot send message: Not connected.");
    }
  }
  void disconnect() {
    _shouldReconnect = false;
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    _connectionStatusController.add(false);
  }
  void dispose() {
    _channel?.sink.close();
    _controller.close();
    _connectionStatusController.close();
  }
}
