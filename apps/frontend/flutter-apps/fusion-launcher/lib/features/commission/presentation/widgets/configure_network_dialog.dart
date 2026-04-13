import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/features/commission/view_models/mdns/mdns_search_state.dart';
import 'package:fusion_launcher/features/commission/view_models/mdns/mdns_search_viewmodel.dart';
import 'package:fusion_launcher/features/commission/view_models/vip_config/vip_config_view_model.dart';
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

/// Main configure network dialog that manages all states and flows.
///
/// Creates a scoped [MdnsScanViewModel] via [BlocProvider] so every child
/// widget can access the same cubit without manual wiring.
class ConfigureNetworkDialog extends StatefulWidget {
  final bool bluetoothOnly;

  const ConfigureNetworkDialog({
    super.key,
    this.bluetoothOnly = false,
  });

  @override
  State<ConfigureNetworkDialog> createState() => _ConfigureNetworkDialogState();

  /// Static method to show the dialog.
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
  WiFiCredentials? _wifiCredentials;
  Timer? _bluetoothMockTimer;

  @override
  void initState() {
    super.initState();
    if (widget.bluetoothOnly) {
      _state = NetworkConfigState.bluetoothSearching;
      _startBluetoothSearch();
    }
  }

  @override
  void dispose() {
    _bluetoothMockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<MdnsScanViewModel>(
          create: (_) => MdnsScanViewModel(serviceLocator<MdnsService>()),
        ),
        BlocProvider<VipConfigViewModel>(
          create: (_) => VipConfigViewModel(),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          return MultiBlocListener(
            listeners: <BlocListener<dynamic, dynamic>>[
              BlocListener<MdnsScanViewModel, DeviceScanState>(
                listener: _onMdnsScanStateChanged,
              ),
              BlocListener<VipConfigViewModel, VipConfigViewModelState>(
                listener: _onVipConfigStateChanged,
              ),
            ],
            child: _buildDialog(context),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MDNS BlocListener callback
  // ---------------------------------------------------------------------------

  void _onMdnsScanStateChanged(BuildContext context, DeviceScanState scanState) {
    switch (scanState) {
      case DeviceScanSearching():
        if (_state != NetworkConfigState.mdnsSearching) {
          setState(() => _state = NetworkConfigState.mdnsSearching);
        }
      case DeviceScanFound():
        // Redirect to VIP config as soon as the first device arrives.
        // Stay on that screen for subsequent device emissions.
        if (_state != NetworkConfigState.vipConfiguration) {
          setState(() => _state = NetworkConfigState.vipConfiguration);
        }
      case DeviceScanTimeout():
        setState(() => _state = NetworkConfigState.mdnsRetry);
      case DeviceScanError():
        setState(() => _state = NetworkConfigState.mdnsRetry);
      case DeviceScanInitial():
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Dialog chrome
  // ---------------------------------------------------------------------------

  Widget _buildDialog(BuildContext context) {
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
          border: Border.all(
            color: Theme.of(context).colorScheme.strokeLight,
            width: 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          InkWell(
            onTap: _showCloseDialog,
            child: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.iconDefault,
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseDialog() {
    if (widget.bluetoothOnly || serviceLocator<ProjectViewModel>().virtualIP != null) {
      Navigator.of(context).pop();
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text('If you close this you will be switched back to Design Mode!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
                serviceLocator<ProjectViewModel>().toggleControlMode();
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Content (state machine)
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context) {
    switch (_state) {
      case NetworkConfigState.initial:
        return InitialScreen(
          onConfigureNetwork: () => _startMDNSSearch(context),
        );

      case NetworkConfigState.mdnsSearching:
        return MDNSSearchScreen(
          onConfigureWireless: _startBluetoothSearch,
        );

      case NetworkConfigState.mdnsRetry:
        return MDNSRetryScreen(
          onRetry: () => _startMDNSSearch(context),
          onConfigureWireless: _startBluetoothSearch,
        );

      case NetworkConfigState.bluetoothSearching:
        return BluetoothSearchScreen(
          onGoBack: () {
            if (widget.bluetoothOnly) {
              Navigator.of(context).pop();
            } else {
              _goBackToMDNS(context);
            }
          },
        );

      case NetworkConfigState.bluetoothRetry:
        return BluetoothRetryScreen(
          onRetry: _startBluetoothSearch,
        );

      case NetworkConfigState.bluetoothDevicesFound:
        return BluetoothDevicesScreen(
          devices: _bluetoothDevices,
          onSendCredentials: (WiFiCredentials credentials, List<BluetoothDevice> selectedDevices) {
            _sendWiFiCredentials(credentials, selectedDevices, context);
          },
          onRetry: _startBluetoothSearch,
          onGoBack: () {
            if (widget.bluetoothOnly) {
              Navigator.of(context).pop();
            } else {
              _goBackToMDNS(context);
            }
          },
        );

      case NetworkConfigState.vipConfiguration:
        return const VIPConfigurationScreen();

      case NetworkConfigState.success:
        return VipSuccessScreen(
          onFinish: () {
            Navigator.of(context).pop();
            DeviceMappingDialog.show(context);
          },
        );
    }
  }

  // ---------------------------------------------------------------------------
  // MDNS scan actions
  // ---------------------------------------------------------------------------

  void _startMDNSSearch(BuildContext context) {
    context.read<MdnsScanViewModel>().startScan();
  }

  void _goBackToMDNS(BuildContext context) {
    context.read<MdnsScanViewModel>().stopScan();
    setState(() => _state = NetworkConfigState.mdnsSearching);
    context.read<MdnsScanViewModel>().startScan();
  }

  // ---------------------------------------------------------------------------
  // Bluetooth (unchanged — still mock/placeholder)
  // ---------------------------------------------------------------------------

  void _startBluetoothSearch() {
    _bluetoothMockTimer?.cancel();
    setState(() => _state = NetworkConfigState.bluetoothSearching);

    _bluetoothMockTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
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
    });
  }

  void _sendWiFiCredentials(
    WiFiCredentials credentials,
    List<BluetoothDevice> selectedDevices,
    BuildContext context,
  ) async {
    _wifiCredentials = credentials;

    FusionUiUtils.showLoader(context);

    for (final BluetoothDevice device in selectedDevices) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint('Sending credentials to ${device.name}');
    }

    if (mounted) {
      FusionUiUtils.hideLoader(context);
      showSuccessPopup(
        context,
        () async {
          if (widget.bluetoothOnly) {
            Navigator.of(context).pop();
          } else {
            _startMDNSSearch(context);
          }
        },
        durationInMils: 2500,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // VIP config BlocListener callback
  // ---------------------------------------------------------------------------

  void _onVipConfigStateChanged(BuildContext context, VipConfigViewModelState vipState) {
    switch (vipState) {
      case VipConfigVerifying():
        FusionUiUtils.showLoader(context);
      case VipConfigSuccess(:final String vip):
        FusionUiUtils.hideLoader(context);
        serviceLocator<ProjectViewModel>().setVirtualIP(ip: vip);
        showSuccessPopup(
          context,
          () async {
            if (mounted) {
              Navigator.of(context).pop();
              DeviceMappingDialog.show(context);
            }
          },
          durationInMils: 2500,
        );
      case VipConfigError(:final String message):
        FusionUiUtils.hideLoader(context);
        FusionToast.error(context, message: message);
        // Reset so the user can try again from the same screen.
        context.read<VipConfigViewModel>().reset();
      case VipConfigInitial():
        break;
    }
  }
}
