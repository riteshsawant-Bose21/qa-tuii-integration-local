import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // Singleton pattern to ensure one instance across the app
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;

  // Broadcaster to allow multiple listeners
  final StreamController _controller = StreamController.broadcast();
  Stream get stream => _controller.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect(String url) async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          _controller.add(message);
        },
        onDone: () {
          _isConnected = false;
          debugPrint("Disconnected from server.");
          connect(url);
        },
        onError: (error) {
          _isConnected = false;
          _controller.addError(error);
          debugPrint("WS Error: $error");
        },
      );
    } catch (e) {
      _isConnected = false;
      _controller.addError(e);
      debugPrint("Connection failed: $e");
      rethrow;
    }
  }

  void subscribe(String key){
    _channel!.sink.add(jsonEncode({
      "id": key,
      "version": 1,
      "type": "config"
    }
    ));
  }


  void sendMessage(dynamic message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(message);
    } else {
      debugPrint("Cannot send message: Not connected.");
    }
  }

  void disconnect() {
    _channel?.sink.close(status.normalClosure);
    _isConnected = false;
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
