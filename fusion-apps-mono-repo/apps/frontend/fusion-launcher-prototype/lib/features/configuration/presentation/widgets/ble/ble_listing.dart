import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../../core/ble/ble_connection_manager.dart';
import '../../../../../core/utils/fusion_utils.dart';

class BleDiscovery extends StatefulWidget {
  const BleDiscovery({super.key});

  @override
  State<BleDiscovery> createState() => _BleDiscoveryState();
}

class _BleDiscoveryState extends State<BleDiscovery> {
  bool scanning = true;

  bool connectForWink = false;

  List<ScanResult> bleDevices = <ScanResult>[];

  StreamSubscription<List<ScanResult>>? deviceSubscriptionListener;
  StreamSubscription<BleConnectionStatus>? connectionListener;

  Future<void>? stopScanTask;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();

    startScanning();
  }

  void startScanning() async {
    if (bleDevices.isNotEmpty) {
      await BleConnectionManager.stopScan();
      setState(() {
        bleDevices = <ScanResult>[];
      });
    }

    deviceSubscriptionListener = bleDeviceListController.stream.listen((List<ScanResult> data) {
      if (mounted) {
        setState(() {
          bleDevices = data;
        });
      }
    });

    print("Starting BLE scan...");
    await BleConnectionManager.listDevices();
    if (!scanning) {
      setState(() {
        scanning = true;
      });
    }
    Future<void>.delayed(const Duration(seconds: 15), () async {
      await BleConnectionManager.stopScan();
      if (mounted) {
        setState(() {
          scanning = false;
        });
      }
    });

    //The MOCK code for testing purposes
    // Future<void>.delayed(const Duration(seconds: 2), () async {
    //   // await BleConnectionManager.stopScan();
    //   if (mounted) {
    //     setState(() {
    //       bleDevices.add(
    //         ScanResult(
    //           device: BluetoothDevice(remoteId: const DeviceIdentifier("Fusion")),
    //           advertisementData: AdvertisementData(
    //             advName: "Fusion Mini",
    //             txPowerLevel: 1,
    //             appearance: 1,
    //             connectable: true,
    //             manufacturerData: <int, List<int>>{},
    //             serviceData: <Guid, List<int>>{},
    //             serviceUuids: <Guid>[Guid("0000180d-0000-1000-8000-00805f9b34fb")],
    //           ),
    //           rssi: 11,
    //           timeStamp: DateTime.now(),
    //         ),
    //       );
    //       scanning = false;
    //     });
    //   }
    // });
  }

  void establishConnection(BluetoothDevice device, BuildContext context) async {
    FusionUtils.showLoader(context);
    await BleConnectionManager.stopScan();
    connectionListener = bleConnectionController.stream.listen((BleConnectionStatus status) async {
      if (context.mounted) {
        if (status == BleConnectionStatus.connected) {
       final bool isListed =   await BleConnectionManager.listServices(device);
          if (connectForWink) {
            if (context.mounted) {
              blinkDsp(context);
              setState(() {
                connectForWink = false;
              });
            }
          } else {
            if (context.mounted) {
              FusionUtils.hideLoader(context);
              Navigator.pop(context, isListed);
            }
          }
        } else if (status == BleConnectionStatus.disconnected) {
          FusionUtils.hideLoader(context);
        }
      }
    });

    BleConnectionManager().initialize(device.remoteId.str);

    //Mock code for testing purposes

    // Future<void>.delayed(const Duration(seconds: 2), () async {
    //   if (context.mounted) {
    //     FusionUtils.hideLoader(context);
    //     await showSuccessPopup(context, () {
    //       Navigator.pushNamed(context, Routes.bleDeviceSetupPage, arguments: device.advName);
    //     });
    //   }
    // });
  }

  void blinkDsp(BuildContext context) async {
    // FusionUtils.showLoader(context);
    // final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionBleCommands>().blinkLed();
    // if (context.mounted) {
    //   FusionUtils.hideLoader(context);
    // }
    // if (responseCallback.success) {
    //   Fluttertoast.showToast(msg: "DSP is Blinking now!!");
    // } else {
    //   Fluttertoast.showToast(msg: "Unable to send blink command!!");
    // }

    FusionUtils.showLoader(context);
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      if (context.mounted) {
        FusionUtils.hideLoader(context);
        // FusionUtils.showToast(context: context, message: "DSP is Blinking now!!");
      }
    });
  }

  @override
  void dispose() {
    deviceSubscriptionListener?.cancel();
    connectionListener?.cancel();
    if(scanning){
      BleConnectionManager.stopScan();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: // Devices header
          Row(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.memory,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Devices',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bleDevices.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),
          InkWell(
            onTap: () {
              startScanning();
            },
            child: Icon(
              Icons.refresh,
              size: 25,
              color: colors.primary,
            ),
          ),
        ],
      ),
      content: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outline.withAlpha((0.2 * 255).toInt()),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),

              // Devices list
              if (bleDevices.isEmpty && !scanning)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.outline.withAlpha((0.2 * 255).toInt()),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No devices found',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (bleDevices.isNotEmpty)
                Column(
                  children:
                      bleDevices.map((ScanResult device) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              establishConnection(device.device, context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest.withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.outline.withAlpha((0.15 * 255).toInt()),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  // Bluetooth icon
                                  Icon(
                                    Icons.bluetooth,
                                    size: 25,
                                    color: colors.tertiary,
                                  ),

                                  const SizedBox(width: 12),

                                  // Device info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              device.device.advName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Mac: ${device.device.remoteId.str}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Arrow indicator
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                )
              else if (scanning)
                Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 2,
                  ),
                )
              else
                Container(),
            ],
          ),
        ),
      ),
    );
  }
}
