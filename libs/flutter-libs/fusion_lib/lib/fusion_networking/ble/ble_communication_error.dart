/// Custom exception for BLE communication errors
class BLECommunicationException implements Exception {
  final String message;

  BLECommunicationException(this.message);

  @override
  String toString() => 'BLECommunicationException: $message';
}
