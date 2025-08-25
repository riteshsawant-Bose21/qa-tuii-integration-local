// dart: dartzmq_stub.dart
import 'dart:typed_data';

class ZContext {
  ZContext();
  ZSocket createSocket(SocketType type) => throw UnsupportedError('ZeroMQ is not supported on the web.');
}

class ZSocket {
  void connect(String url) => throw UnsupportedError('ZeroMQ is not supported on the web.');
  void subscribe(String topic) => throw UnsupportedError('ZeroMQ is not supported on the web.');
  Stream<ZFrame> get frames async* {
    // Empty stream for web stub
  }
  void close() => throw UnsupportedError('ZeroMQ is not supported on the web.');
}

class ZFrame {
  final Uint8List payload;
  ZFrame(this.payload);
}

enum SocketType { sub, pub }
