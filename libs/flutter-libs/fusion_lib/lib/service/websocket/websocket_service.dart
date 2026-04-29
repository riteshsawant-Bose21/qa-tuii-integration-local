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

  bool _shouldReconnect = true;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 2);
  Timer? _reconnectTimer;
  String? _lastUrl;

  Future<void> connect(String url) async {
    if (_isConnected) return;

    _lastUrl = url;
    _shouldReconnect = true;

    await _doConnect(url);
  }

  Future<void> _doConnect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      // Waits for the WebSocket handshake to complete.
      // Throws a WebSocketChannelException if the connection fails.
      await _channel!.ready;
      _isConnected = true;
      _retryCount = 0;

      _channel!.stream.listen(
        (message) {
          _controller.add(message);
        },
        onDone: () {
          _isConnected = false;
          debugPrint("Disconnected from server.");
          _scheduleReconnect(url);
        },
        onError: (error) {
          _isConnected = false;
          debugPrint("WS Error: $error");
          _scheduleReconnect(url);
        },
      );
    } catch (e) {
      _isConnected = false;
      debugPrint("Connection failed: $e");
      _scheduleReconnect(url);
    }
  }

  void _scheduleReconnect(String url) {
    if (!_shouldReconnect) return;

    if (_retryCount >= _maxRetries) {
      debugPrint("Max reconnect attempts ($_maxRetries) reached. Giving up.");
      return;
    }

    _retryCount++;
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = _baseDelay * (1 << (_retryCount - 1));
    debugPrint("Reconnecting in ${delay.inSeconds}s (attempt $_retryCount/$_maxRetries)...");

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect) {
        _doConnect(url);
      }
    });
  }

  void subscribe(String key) {
    _channel!.sink.add(jsonEncode({"id": key, "version": 1, "type": "config"}));
  }

  void sendMessage(dynamic message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(message);
    } else {
      debugPrint("Cannot send message: Not connected.");
    }
  }

  /// Resets the retry counter and reconnects immediately (useful after regaining network).
  Future<void> reconnect() async {
    _retryCount = 0;
    _reconnectTimer?.cancel();
    if (_lastUrl != null) {
      await _doConnect(_lastUrl!);
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close(status.normalClosure);
    _isConnected = false;
    _retryCount = 0;
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
