import 'package:fusion_lib/fusion_lib.dart';

/// Base state for MDNS device scanning.
sealed class DeviceScanState {
  const DeviceScanState();
}

/// No scan has been initiated yet.
class DeviceScanInitial extends DeviceScanState {
  const DeviceScanInitial();
}

/// Scan is in progress but no devices have been found yet.
class DeviceScanSearching extends DeviceScanState {
  const DeviceScanSearching();
}

/// At least one device has been discovered.
///
/// [isScanning] is `true` while the scan is still running (more devices may
/// arrive). Once the 30-second window elapses or the stream completes it
/// becomes `false` — the UI should then show a "Retry" option.
class DeviceScanFound extends DeviceScanState {
  final List<MdnsDevice> devices;
  final bool isScanning;
  const DeviceScanFound(this.devices, {this.isScanning = true});
}

/// 30-second scan window elapsed and zero devices were found.
class DeviceScanTimeout extends DeviceScanState {
  const DeviceScanTimeout();
}

/// Scan encountered an unrecoverable error.
class DeviceScanError extends DeviceScanState {
  final String message;
  const DeviceScanError(this.message);
}
