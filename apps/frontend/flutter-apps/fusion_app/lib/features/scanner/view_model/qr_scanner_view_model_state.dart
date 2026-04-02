part of 'qr_scanner_view_model.dart';

@immutable
sealed class QrScannerState {}

final class QrInitial extends QrScannerState {}

final class QrScanning extends QrScannerState {}

final class QrParsed extends QrScannerState {
  final String vip;
  final String controllerId;

   QrParsed({
    required this.vip,
    required this.controllerId,
  });
}

final class QrConnecting extends QrScannerState {}

final class QrConnected extends QrScannerState {
  final SchemaModel data;
  QrConnected(this.data);
}

final class QrError extends QrScannerState {
  final String message;

  QrError(this.message);
}