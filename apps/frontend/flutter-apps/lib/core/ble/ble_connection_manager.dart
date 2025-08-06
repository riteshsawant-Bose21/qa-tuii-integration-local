import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../logger/logger.dart';
import 'ble_helper.dart';

StreamController<BleConnectionStatus> bleConnectionController = StreamController<BleConnectionStatus>.broadcast();
StreamController<BluetoothStatus> bluetoothStatusController = StreamController<BluetoothStatus>.broadcast();
StreamController<List<ScanResult>> bleDeviceListController = StreamController<List<ScanResult>>.broadcast();

enum BleConnectionStatus {
  initial,
  connected,
  disconnected,
}

enum BluetoothStatus {
  initial,
  on,
  off,
}

class BleConnectionManager {
  static String? deviceId;
  BluetoothDevice? _device;
  int _retryCount = 0;
  Timer? _reconnectTimer;
  DateTime? _lastDisconnectTime;
  static const int maxRetryDelay = 15; // max delay in seconds
  static const int resetThresholdHours = 1; // threshold to reset backoff

  static int listServiceRetryCount = 0;
  static BleConnectionStatus bleConnectionStatus = BleConnectionStatus.initial;

  static StreamSubscription<List<ScanResult>>? scanSubscription;
  static StreamSubscription<BluetoothConnectionState>? deviceConnectionSubscription;

  // Singleton instance
  static final BleConnectionManager _instance = BleConnectionManager._internal();

  // Private constructor
  BleConnectionManager._internal();

  // Factory constructor
  factory BleConnectionManager() {
    return _instance;
  }

  String? getDeviceRemoteId() {
    // fetch saved device id
    if (_device != null) {
      return _device?.remoteId.str;
    }
    return null;
  }

  static Future<void> listDevices() async {
    // listen to scan results
    // Note: `onScanResults` only returns live scan results, i.e. during scanning. Use
    //  `scanResults` if you want live scan results *or* the results from a previous scan.
    final StreamSubscription<List<ScanResult>> subscription = FlutterBluePlus.onScanResults.listen(
      (List<ScanResult> results) {
        debugPrint('Scan results: ${results.length} devices found');
        debugPrint('Scan results: ${results.map((ScanResult r) => r.device.remoteId.str).join(', ')}');
        if (results.isNotEmpty) {
          final ScanResult r = results.last; // the most recently found device
          debugPrint('${r.device.remoteId}: "${r.advertisementData.advName}" found!');

          bleDeviceListController.add(results);
        }
      },
      onError: (dynamic e) => <void>{debugPrint(e)},
    );

    final bool isBTOn = await isBluetoothOn();

    if (!isBTOn) {
      print("Bluetooth is OFF, Scan not started");
    } else {
      // cleanup: cancel subscription when scanning stops
      print("Bluetooth is ON, Scan started");
      await FlutterBluePlus.startScan(
        withServices: <Guid>[ServiceUUIDs.getUUID(Services.fusion)],
      );
      FlutterBluePlus.cancelWhenScanComplete(subscription);
    }
  }

  static Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  /// Returns true if Bluetooth is ON.
  static Future<bool> isBluetoothOn() async {
    // 1️⃣ Asynchronous: wait for the first non‑unknown state
    final BluetoothAdapterState state = await FlutterBluePlus.adapterState.where((BluetoothAdapterState s) => s != BluetoothAdapterState.unknown).first;

    return state == BluetoothAdapterState.on;
  }

  static Future<bool> listServices(BluetoothDevice connectedDevice) async {
    // Note: You must call discoverServices after every re-connection!
    FusionLogger.log(tag: LogTag.ble, message: "List services Called");
    try {
      final List<BluetoothService> services = await connectedDevice.discoverServices();
      for (BluetoothService service in services) {
        FusionLogger.log(
          tag: LogTag.ble,
          message: "ServiceId: ${service.serviceUuid}  ",
        );
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          FusionLogger.log(tag: LogTag.ble, message: "Characteristics: ${characteristic.characteristicUuid}");
          FusionLogger.log(tag: LogTag.ble, message: "properties: ${characteristic.properties}");
        }
      }
      return true;
    } catch (ex) {
      FusionLogger.log(tag: LogTag.ble, message: "Exception occurred while listing services $ex");

      if (ex.toString().contains("device is disconnected")) {
        return false;
      } else {
        if (listServiceRetryCount == 0) {
          listServiceRetryCount++;
          return await listServices(connectedDevice);
        }
      }
      return false;
    }
  }

  Future<void> initialize(String? tempRemoteId) async {
    deviceId = tempRemoteId ?? getDeviceRemoteId();

    if (deviceConnectionSubscription != null && tempRemoteId != null) {
      await deviceConnectionSubscription!.cancel();
      deviceConnectionSubscription = null;
    }

    FusionLogger.log(
      tag: LogTag.ble,
      message: "Ble connection: initialize() called Device id $deviceId",
    );

    if (deviceId != null) {
      // BluetoothDevice device = BluetoothDevice(
      //     remoteId: DeviceIdentifier(remoteId ?? tempRemoteId!));
      if (_device != null && tempRemoteId != null) {
        //if from pairing flow
        if (_device!.isConnected) {
          await _device?.disconnect();
        }
        _device = null;
      }
      _device ??= BluetoothDevice.fromId(deviceId!);

      if (_device!.isDisconnected) {
        debugPrint("Connecting with device..");
        //disable auto connect for temporary connection in paring flow  (until user association connection is considered as temporary)
        FusionLogger.log(tag: LogTag.ble, message: "Ble connection: calling _connect() form initialize()  $deviceId");
        _connect();
      } else {
        final bool isListed = await listServices(_device!);
        if (isListed) {
          FusionLogger.log(tag: LogTag.ble, message: "Ble connection: emitting Connected form initialize()  $deviceId");
          bleConnectionController.add(BleConnectionStatus.connected);
        } else {
          if (deviceConnectionSubscription != null) {
            await deviceConnectionSubscription!.cancel();
            deviceConnectionSubscription = null;
          }

          FusionLogger.log(tag: LogTag.ble, message: "Ble connection: emitting disconnected form initialize()  $deviceId");
          bleConnectionController.add(BleConnectionStatus.disconnected);
          handleBleConnectionEdgeCase();
        }
      }
    }
  }

  void handleBleConnectionEdgeCase() async {
    try {
      try {
        await _device!.connect(autoConnect: false);
      } catch (ex) {
        FusionLogger.log(tag: LogTag.ble, message: "handleBleConnectionEdgeCase() Exception $ex");
      }
      final bool isListed = await listServices(_device!);
      if (isListed) {
        FusionLogger.log(tag: LogTag.ble, message: "handleBleConnectionEdgeCase() Services Listed Successfully!!!");
        try {
          listenToConnectedDeviceState();
        } catch (ex) {
          FusionLogger.log(tag: LogTag.ble, message: "handleBleConnectionEdgeCase()  called listenToConnectedDeviceState()!!!");
        }
        _connect();
      } else {
        await _device!.disconnect();
        handleBleConnectionEdgeCase();
      }
    } catch (ex) {
      FusionLogger.log(tag: LogTag.ble, message: "Attempting connection again ${DateTime.now()}");
      handleBleConnectionEdgeCase();
    }
  }

  Future<void> scanAndConnectToDevice() async {
    FusionLogger.log(tag: LogTag.ble, message: "Ble connection: connectToDevice() called  $deviceId");
    if (deviceId == null) {
      return;
    }

    if (_device != null && _device!.isConnected) {
      FusionLogger.log(tag: LogTag.ble, message: "Ble connection: connectToDevice()  returning back device is already connected!!");
      return;
    }

    FusionLogger.log(tag: LogTag.ble, message: "Ble connection: connectToDevice()  starting Ble Scan!!");

    if (scanSubscription != null) {
      await scanSubscription?.cancel();
      scanSubscription = null;
    }

    // Start scanning for the device
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15), withRemoteIds: <String>[deviceId!]);

    // Listen to scan results
    scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.remoteId.str == deviceId) {
          FusionLogger.log(
            tag: LogTag.ble,
            message: "Ble connection: connectToDevice()  device found!! ${result.device.advName}  - ${result.device.remoteId.str}",
          );
          if (_device == null || _device!.isDisconnected) {
            FusionLogger.log(
              tag: LogTag.ble,
              message: "Ble connection: connectToDevice()  stopping scan and connecting with Device ${result.device.advName}  - ${result.device.remoteId.str}!",
            );
            FlutterBluePlus.stopScan();
            _device = result.device;
            _connect();
          }
          break;
        }
      }
    });
  }

  Future<void> _connect() async {
    FusionLogger.log(tag: LogTag.ble, message: "Ble connection: _connect()  called for $deviceId!  , is Device null : ${_device == null}");

    if (_device == null) return;

    if (_device!.isConnected) {
      FusionLogger.log(tag: LogTag.ble, message: "Ble connection: _connect()  returning back device already connected!!");
      return;
    }

    FusionLogger.log(tag: LogTag.ble, message: "Ble connection: _connect()  attempting ble connection!!");
    // Attempt to connect with high priority
    try {
      await _device!.connect(
        autoConnect: false,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.ble, message: "Ble connection: _connect()  ERROR: connection attempt failed $ex!!");
      _handleDisconnect();
    }

    if (_device!.isConnected) {
      FusionLogger.log(tag: LogTag.ble, message: "Ble connection: _connect()  device connected, adding request priority to High!!");

      // Reset retry count and last disconnect time on successful connection
      _retryCount = 0;
      _lastDisconnectTime = null;
    }

    listenToConnectedDeviceState();

    if (_device!.isDisconnected) {
      _handleDisconnect();
    }
  }

  void listenToConnectedDeviceState() {
    deviceConnectionSubscription ??= _device!.connectionState.listen((BluetoothConnectionState state) async {
      FusionLogger.log(tag: LogTag.ble, message: "Ble connection: connectionState Received  state is ${state.name}");
      if (state == BluetoothConnectionState.disconnected) {
        // 1. typically, start a periodic timer that tries to
        //    reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!
        // currentBannerStatus = BannerStatus.disconnected;
        FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  previous state is $bleConnectionStatus");

        _handleDisconnect();

        final bool isFromAppOpen = bleConnectionStatus == BleConnectionStatus.initial;

        if (bleConnectionStatus != BleConnectionStatus.disconnected) {
          if (!isFromAppOpen) {
            //wait for connection attempt to emit disconnect signal
            bleConnectionStatus = BleConnectionStatus.disconnected;
          }
          // cancelOldSubscriptions();
          FusionLogger.log(tag: LogTag.ble, message: "Ble connection: Device Disconnected: RemoteId : $deviceId ${_device!.disconnectReason}");

          final String? remoteId = getDeviceRemoteId();
          if (remoteId != null) {
            if (_device!.isDisconnected) {
              FusionLogger.log(tag: LogTag.ble, message: "Ble connection: Emitting device disconnected");
              bleConnectionController.add(BleConnectionStatus.disconnected);
            }
          }
        }

        if (!isFromAppOpen || getDeviceRemoteId() == null) {
          //wait for connection attempt to emit disconnect signal
          FusionLogger.log(tag: LogTag.ble, message: "Ble connection: Emitting device disconnected !!");
          bleConnectionController.add(BleConnectionStatus.disconnected);
        }
      } else if (state == BluetoothConnectionState.connected) {
        FusionLogger.log(tag: LogTag.ble, message: "Ble connection: Device Connected: RemoteId : $deviceId ${_device!.advName}");

        FusionLogger.log(tag: LogTag.ble, message: "Ble connection: previous state is $bleConnectionStatus!!");

        listServiceRetryCount = 0;
        // if (bleConnectionStatus != BleConnectionStatus.connected) {
          FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  inside the onConnected Block!!");

          bleConnectionStatus = BleConnectionStatus.connected;
          debugPrint("On connected-----");

          // await _device?.createBond();

          FusionLogger.log(tag: LogTag.ble, message: "Ble connection:   Emitted device connected!!");

          bleConnectionController.add(BleConnectionStatus.connected);
        // }
      }
    });
  }

  void _handleDisconnect() {
    // if (getDeviceRemoteId() != null) {
    //   FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  inside _handleDisconnect() !");
    //
    //   // Track the last disconnect time
    //   _lastDisconnectTime = DateTime.now();
    //
    //   // Calculate delay based on retry count
    //   final int delayInSeconds = _calculateReconnectDelay();
    //   FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  _handleDisconnect() delay in seconds $delayInSeconds!");
    //   // Schedule reconnection attempt with calculated delay
    //   _reconnectTimer?.cancel();
    //   _reconnectTimer = Timer(Duration(seconds: delayInSeconds), () {
    //     FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  calling  _connect() from future Timer!");
    //     _connect();
    //   });
    // }
  }

  int _calculateReconnectDelay() {
    // Check if we should reset the backoff
    if (_lastDisconnectTime != null) {
      final Duration elapsed = DateTime.now().difference(_lastDisconnectTime!);
      if (elapsed.inHours >= resetThresholdHours) {
        _retryCount = 0; // reset backoff after prolonged disconnection
      }
      if (elapsed.inSeconds > 15) {
        FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  _calculateReconnectDelay()  calling connectToDevice because dealy is greater than 20 sec");
        scanAndConnectToDevice();
      }
    }

    // Calculate delay with a cap on max delay
    final int delayInSeconds = (_retryCount < 5) ? 2 * (_retryCount + 1) : maxRetryDelay;
    _retryCount++;
    return delayInSeconds;
  }

  Future<void> disconnect() async {
    FusionLogger.log(tag: LogTag.ble, message: "Ble connection:  disconnect()  called");

    _reconnectTimer?.cancel();
    _retryCount = 0;
    await _device?.disconnect();

    // if (getDeviceRemoteId() != null) {
    //   _handleDisconnect();
    // } else {
    //   _device = null;
    // }
  }

  BluetoothDevice? getDevice() {
    return _device;
  }
}
