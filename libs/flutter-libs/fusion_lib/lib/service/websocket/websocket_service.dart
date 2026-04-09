import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

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

  void connect(String url) {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          _controller.add(message);
        },
        onDone: () {
          _isConnected = false;
          debugPrint("Disconnected from server.");
        },
        onError: (error) {
          _isConnected = false;
          debugPrint("WS Error: $error");
        },
      );
    } catch (e) {
      _isConnected = false;
      debugPrint("Connection failed: $e");
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
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
