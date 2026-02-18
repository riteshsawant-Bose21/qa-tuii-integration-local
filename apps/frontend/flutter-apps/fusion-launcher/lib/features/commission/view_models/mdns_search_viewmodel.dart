// device_scan_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'mdns_search_state.dart';

// States

// Cubit
class MdnsScanViewModel extends Cubit<DeviceScanState> {
  final MdnsService _mdnsService;
  final List<MdnsDevice> _discoveredDevices = <MdnsDevice>[];

  MdnsScanViewModel(this._mdnsService) : super(DeviceScanInitial());

  void startScan() async {
    emit(DeviceScanLoading());
    _discoveredDevices.clear(); // Reset list on new scan

    try {
      // Listen to the stream from the service
      _mdnsService.startDiscovery().listen(
        (MdnsDevice device) {
          // Avoid duplicates based on IP
          if (!_discoveredDevices.any((MdnsDevice d) => d.ip == device.ip)) {
            _discoveredDevices.add(device);
            // Emit new state with updated list
            emit(DeviceScanLoaded(List<MdnsDevice>.from(_discoveredDevices)));
          }
        },
        onDone: () {
          // Optional: Handle stream completion
        },
        onError: (dynamic error) {
          print("Discovery Error: $error");
        },
      );
    } catch (e) {
      print("Error starting scan: $e");
    }
  }

  void stopScan() {
    _mdnsService.stopDiscovery();
  }
}
