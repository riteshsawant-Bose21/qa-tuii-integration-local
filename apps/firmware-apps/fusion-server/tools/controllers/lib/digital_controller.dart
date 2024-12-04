import 'dart:async';
import 'dart:io';
import 'dart:convert';

class DigitalController {
  Socket? _socket;
  final String host;
  final int port;
  final Function(String) onError;
  final Function() onConnected;
  final Map<String, List<Function(String)>> _subscribers = {};
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;

  DigitalController({
    required this.host,
    required this.port,
    required this.onError,
    required this.onConnected,
  });

  Future<void> connect() async {
    if (_isConnecting || !_shouldReconnect) return;
    _isConnecting = true;

    try {
      _socket = await Socket.connect(host, port);
      _socket!.listen(
        _handleData,
        onError: (error) {
          print('Socket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('Socket closed');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
      onConnected();

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_socket != null) {
          try {
            _socket!.add([0]);
          } catch (e) {
            _handleDisconnect();
          }
        }
      });
    } catch (e) {
      print('Connection error: $e');
      _handleDisconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleData(List<int> data) {
    final message = utf8.decode(data);
    final parts = message.split(':');
    if (parts.length >= 2) {
      final param = parts[0];
      final value = parts[1];
      _notifySubscribers(param, value);
    }
  }

  void _notifySubscribers(String param, String value) {
    if (_subscribers.containsKey(param)) {
      for (var callback in _subscribers[param]!) {
        callback(value);
      }
    }
  }

  void subscribe(String param, Function(String) callback) {
    _subscribers.putIfAbsent(param, () => []).add(callback);
  }

  void setParam(String deviceId, String param, String index, String value) {
    if (_socket == null) return;
    try {
      final message = '$deviceId:$param:$index:$value\n';
      _socket?.add(utf8.encode(message));
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _heartbeatTimer?.cancel();
    _socket?.destroy();
    _socket = null;

    if (mounted()) {
      onError('Server disconnected');
      if (_shouldReconnect) {
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 5), connect);
      }
    }
  }

  bool mounted() {
    try {
      return _shouldReconnect;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _subscribers.clear();
  }
}
