import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'mdns_search_state.dart';

/// Cubit that manages MDNS device discovery lifecycle.
///
/// Flow:
///  1. [startScan] emits [DeviceScanSearching].
///  2. As each device is discovered it emits [DeviceScanFound] with
///     `isScanning: true` so the UI can show a live-updating list.
///  3. After [scanDuration] (default 30 s) the scan stops automatically and
///     emits either [DeviceScanFound] with `isScanning: false` (if devices
///     were found) or [DeviceScanTimeout] (if none were found).
///  4. [retryScan] can be called at any time to restart.
class MdnsScanViewModel extends Cubit<DeviceScanState> {
  final MdnsService _mdnsService;
  final Duration scanDuration;

  final List<MdnsDevice> _discoveredDevices = <MdnsDevice>[];
  StreamSubscription<MdnsDevice>? _scanSubscription;
  Timer? _scanTimer;

  MdnsScanViewModel(
    this._mdnsService, {
    this.scanDuration = const Duration(seconds: 30),
  }) : super(const DeviceScanInitial());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Begin a new scan. Any in-flight scan is cancelled first.
  void startScan() {
    _cancelScan();
    _discoveredDevices.clear();
    _safeEmit(const DeviceScanSearching());

    try {
      _scanSubscription = _mdnsService.startDiscovery().listen(
        _onDeviceFound,
        onDone: _onStreamDone,
        onError: _onStreamError,
        cancelOnError: false,
      );

      // Hard-stop after scanDuration regardless of stream state.
      _scanTimer = Timer(scanDuration, _onScanDurationElapsed);
    } catch (e, stackTrace) {
      debugPrint('MdnsScanViewModel: Failed to start scan — $e\n$stackTrace');
      _safeEmit(DeviceScanError(e.toString()));
    }
  }

  /// Stop the current scan without changing the emitted state.
  void stopScan() {
    _cancelScan();
  }

  /// Convenience wrapper — stops any existing scan then starts fresh.
  void retryScan() {
    startScan();
  }

  /// Read-only snapshot of the discovered devices.
  List<MdnsDevice> get discoveredDevices => List<MdnsDevice>.unmodifiable(_discoveredDevices);

  // ---------------------------------------------------------------------------
  // Stream callbacks
  // ---------------------------------------------------------------------------

  void _onDeviceFound(MdnsDevice device) {
    // De-duplicate by stableId (falls back to IP if ids match).
    final bool isDuplicate = _discoveredDevices.any(
      (MdnsDevice d) => d.stableId == device.stableId,
    );
    if (isDuplicate) return;

    _discoveredDevices.add(device);
    _safeEmit(
      DeviceScanFound(
        List<MdnsDevice>.from(_discoveredDevices),
        isScanning: true,
      ),
    );
  }

  void _onStreamDone() {
    // The mDNS stream completed on its own (before the 30-s timer).
    _scanTimer?.cancel();
    _scanTimer = null;
    _emitFinalState();
  }

  void _onStreamError(dynamic error, StackTrace stackTrace) {
    debugPrint('MdnsScanViewModel: Discovery error — $error\n$stackTrace');
    // Surface partial results if we have any; otherwise emit error.
    if (_discoveredDevices.isNotEmpty) {
      _cancelScan();
      _safeEmit(
        DeviceScanFound(
          List<MdnsDevice>.from(_discoveredDevices),
          isScanning: false,
        ),
      );
    } else {
      _cancelScan();
      _safeEmit(DeviceScanError(error.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Timer callback
  // ---------------------------------------------------------------------------

  void _onScanDurationElapsed() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _mdnsService.stopDiscovery();
    _scanTimer = null;
    _emitFinalState();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emitFinalState() {
    if (_discoveredDevices.isNotEmpty) {
      _safeEmit(
        DeviceScanFound(
          List<MdnsDevice>.from(_discoveredDevices),
          isScanning: false,
        ),
      );
    } else {
      _safeEmit(const DeviceScanTimeout());
    }
  }

  void _cancelScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _mdnsService.stopDiscovery();
  }

  /// Emit only when the cubit is still open (prevents post-dispose crashes).
  void _safeEmit(DeviceScanState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  @override
  Future<void> close() {
    _cancelScan();
    return super.close();
  }
}
