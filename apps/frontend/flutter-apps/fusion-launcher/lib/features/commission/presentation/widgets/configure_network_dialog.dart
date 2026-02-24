import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/device_mapping_dialog.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../user_account_setup/presentation/widgets/account_creation_success_popup.dart';
import 'bluetooth_devices_screen.dart';
import 'bluetooth_retry_screen.dart';
import 'bluetooth_search_screen.dart';
import 'initial_screen.dart';
import 'mdns_retry_screen.dart';
import 'mdns_search_screen.dart';
import 'network_config_state.dart';
import 'vip_configuration_screen.dart';
import 'vip_success_screen.dart';

/// Main configure network dialog that manages all states and flows
class ConfigureNetworkDialog extends StatefulWidget {
  final bool bluetoothOnly;

  const ConfigureNetworkDialog({
    super.key,
    this.bluetoothOnly = false,
  });

  @override
  State<ConfigureNetworkDialog> createState() => _ConfigureNetworkDialogState();

  /// Static method to show the dialog
  static Future<void> show(BuildContext context, {bool bluetoothOnly = false}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => ConfigureNetworkDialog(
            bluetoothOnly: bluetoothOnly,
          ),
    );
  }
}

class _ConfigureNetworkDialogState extends State<ConfigureNetworkDialog> {
  NetworkConfigState _state = NetworkConfigState.initial;
  List<BluetoothDevice> _bluetoothDevices = <BluetoothDevice>[];
  List<MdnsDevice> _mdnsDevices = <MdnsDevice>[];
  WiFiCredentials? _wifiCredentials;
  Timer? mockTimer;

  @override
  void initState() {
    if (widget.bluetoothOnly) {
      _state = NetworkConfigState.bluetoothSearching;
      _startBluetoothSearch();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.elevation1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'CONFIGURE NETWORK',
            style: TextStyle(
              color: Theme.of(context).colorScheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.iconDefault,
            ),
            onPressed: () {
              _showCloseDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showCloseDialog() {
    if (widget.bluetoothOnly || serviceLocator<ProjectViewModel>().virtualIP != null) {
      Navigator.of(context).pop(); // Close the network configuration dialog
      return;
    }
    //show confirmation dialog before closing
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text('If you close this you will be switched back to Design Mode!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop(); // Close the network configuration dialog
                serviceLocator<ProjectViewModel>().toggleControlMode();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_state) {
      case NetworkConfigState.initial:
        return InitialScreen(
          onConfigureNetwork: () => _startMDNSSearch(),
        );

      case NetworkConfigState.mdnsSearching:
        return MDNSSearchScreen(
          onConfigureWireless: () => _startBluetoothSearch(),
        );

      case NetworkConfigState.mdnsRetry:
        return MDNSRetryScreen(
          onRetry: () => _startMDNSSearch(),
          onConfigureWireless: () => _startBluetoothSearch(),
        );

      case NetworkConfigState.bluetoothSearching:
        return BluetoothSearchScreen(
          onGoBack: () {
            if (widget.bluetoothOnly) {
              Navigator.of(context).pop();
              return;
            } else {
              _goBackToMDNS();
            }
          },
        );

      case NetworkConfigState.bluetoothRetry:
        return BluetoothRetryScreen(
          onRetry: () => _startBluetoothSearch(),
        );

      case NetworkConfigState.bluetoothDevicesFound:
        return BluetoothDevicesScreen(
          devices: _bluetoothDevices,
          onSendCredentials: (WiFiCredentials credentials, List<BluetoothDevice> selectedDevices) {
            _sendWiFiCredentials(credentials, selectedDevices);
          },
          onRetry: () => _startBluetoothSearch(),
          onGoBack: () {
            if (widget.bluetoothOnly) {
              Navigator.of(context).pop();
              return;
            } else {
              _goBackToMDNS();
            }
          },
        );

      case NetworkConfigState.vipConfiguration:
        return VIPConfigurationScreen(
          devices: _mdnsDevices,
          onVerify: (String vipAddress) => _verifyVIP(vipAddress),
        );

      case NetworkConfigState.success:
        return VipSuccessScreen(
          onFinish: () {
            Navigator.of(context).pop();
            DeviceMappingDialog.show(context);
          },
        );
    }
  }

  // State transition methods
  void _startMDNSSearch() {
    mockTimer?.cancel();
    setState(() {
      _state = NetworkConfigState.mdnsSearching;
    });

    mockTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        if (true) {
          setState(() {
            _mdnsDevices = <MdnsDevice>[
              MdnsDevice(
                name: 'Fusion Mini FM6Y',
                ip: '192.168.1.10', // Mock IP
                port: 8080,
              ),
              MdnsDevice(
                name: 'Fusion Mini FM8Y',
                ip: '192.168.1.11',
                port: 8080,
              ),
            ];
            _state = NetworkConfigState.vipConfiguration;
          });
        }
        // else {
        //   setState(() {
        //     _state = NetworkConfigState.mdnsRetry;
        //   });
        // }
      }
    });
  }

  void _startBluetoothSearch() {
    mockTimer?.cancel();
    setState(() {
      _state = NetworkConfigState.bluetoothSearching;
    });

    mockTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        if (true) {
          setState(() {
            _bluetoothDevices = <BluetoothDevice>[
              BluetoothDevice(id: '1', name: 'Fusion Mini FM6'),
              BluetoothDevice(id: '2', name: 'Fusion Mini FM6'),
              BluetoothDevice(id: '3', name: 'Power Smart 8300'),
              BluetoothDevice(id: '4', name: 'Power Smart 8300'),
            ];
            _state = NetworkConfigState.bluetoothDevicesFound;
          });
        }
        // else {
        //   setState(() {
        //     _state = NetworkConfigState.bluetoothRetry;
        //   });
        // }
      }
    });
  }

  void _sendWiFiCredentials(
    WiFiCredentials credentials,
    List<BluetoothDevice> selectedDevices,
  ) async {
    _wifiCredentials = credentials;

    FusionUiUtils.showLoader(context);

    // Simulate sending credentials to devices one by one
    for (final BluetoothDevice device in selectedDevices) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // Mock sending to device
      debugPrint('Sending credentials to ${device.name}');
    }

    // After wireless configuration, go back to MDNS search
    if (mounted) {
      FusionUiUtils.hideLoader(context);
      showSuccessPopup(
        context,
        () async {
          if (widget.bluetoothOnly) {
            Navigator.of(context).pop();
            return;
          } else {
            _startMDNSSearch();
          }
        },
        durationInMils: 2500,
      );
    }
  }

  void _verifyVIP(String vipAddress) async {
    FusionUiUtils.showLoader(context);
    // Simulate VIP verification
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      serviceLocator<ProjectViewModel>().setVirtualIP(ip: vipAddress);
      FusionUiUtils.hideLoader(context);
      showSuccessPopup(
        context,
        () async {
          // Mock: VIP configuration successful
          setState(() {
            _state = NetworkConfigState.success;
          });
        },
        durationInMils: 2500,
      );
    }
  }

  void _goBackToMDNS() {
    mockTimer?.cancel();
    setState(() {
      _state = NetworkConfigState.mdnsSearching;
    });
  }
}
