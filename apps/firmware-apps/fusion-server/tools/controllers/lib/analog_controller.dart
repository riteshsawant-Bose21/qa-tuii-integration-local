import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

class AnalogController {
  Socket? _socket;
  final String host;
  final int port;
  final Function(String) onError;
  final Function() onConnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;

  AnalogController({
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
        (_) {},
        onError: (error) {
          developer.log('Socket error: $error'); // Add logging
          _handleDisconnect();
        },
        onDone: () {
          developer.log('Socket closed'); // Add logging
          _handleDisconnect();
        },
        cancelOnError:
            false, // Change to false to prevent unexpected termination
      );
      onConnected();

      // Add heartbeat timer
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
      developer.log('Connection error: $e');
      _handleDisconnect();
    } finally {
      _isConnecting = false;
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

  void sendAnalogValues(List<int> values) {
    if (_socket == null) return;

    try {
      final buffer = ByteData(20);
      for (var i = 0; i < 5; i++) {
        buffer.setUint32(i * 4, values[i], Endian.big);
      }
      _socket?.add(buffer.buffer.asUint8List());
    } catch (_) {
      _handleDisconnect();
    }
  }

  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _socket?.destroy();
    _socket = null;
  }
}
