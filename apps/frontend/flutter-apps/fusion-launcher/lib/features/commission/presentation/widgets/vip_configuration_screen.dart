import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/commission/view_models/mdns/mdns_search_state.dart';
import 'package:fusion_launcher/features/commission/view_models/mdns/mdns_search_viewmodel.dart';
import 'package:fusion_launcher/features/commission/view_models/vip_config/vip_config_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class VIPConfigurationScreen extends StatefulWidget {
  const VIPConfigurationScreen({
    super.key,
  });

  @override
  State<VIPConfigurationScreen> createState() => _VIPConfigurationScreenState();
}

class _VIPConfigurationScreenState extends State<VIPConfigurationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _vipController = TextEditingController();
  MdnsDevice? _selectedDevice;
  bool _isAutoSelect = true;

  @override
  void initState() {
    super.initState();
    _vipController.text = '192.168.0.100';
    _syncSelectionFromCubit();
  }

  /// Reads the current cubit state and auto-selects the first device if
  /// available. Called once on init; subsequent updates arrive via
  /// [BlocBuilder].
  void _syncSelectionFromCubit() {
    final List<MdnsDevice> devices = _devicesFromState(
      context.read<MdnsScanViewModel>().state,
    );
    if (devices.isNotEmpty && _selectedDevice == null) {
      _selectedDevice = devices.first;
    }
  }

  @override
  void dispose() {
    _vipController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extracts the device list from any [DeviceScanState] variant.
  List<MdnsDevice> _devicesFromState(DeviceScanState state) {
    return switch (state) {
      DeviceScanFound(:final List<MdnsDevice> devices) => devices,
      _ => const <MdnsDevice>[],
    };
  }

  /// Whether the scan is still actively running.
  bool _isScanningFromState(DeviceScanState state) {
    return switch (state) {
      DeviceScanFound(:final bool isScanning) => isScanning,
      DeviceScanSearching() => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MdnsScanViewModel, DeviceScanState>(
      listener: (BuildContext context, DeviceScanState state) {
        final List<MdnsDevice> devices = _devicesFromState(state);
        // Auto-select the first device when one arrives and nothing is
        // selected yet.
        if (devices.isNotEmpty && _selectedDevice == null) {
          setState(() => _selectedDevice = devices.first);
        }
        // If the previously selected device is no longer in the list,
        // reset selection.
        if (_selectedDevice != null && !devices.any((MdnsDevice d) => d.stableId == _selectedDevice!.stableId)) {
          setState(() => _selectedDevice = devices.isNotEmpty ? devices.first : null);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 48.0,
          horizontal: 0.09 * MediaQuery.of(context).size.width,
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double maxWidth = constraints.maxWidth;
                  final double formCenterWidth = maxWidth < 500 ? maxWidth : 500.0;
                  final double splitSideWidth = ((maxWidth - 56) / 2).clamp(0.0, double.infinity);

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _isAutoSelect ? 0.0 : 1.0,
                      end: _isAutoSelect ? 0.0 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastLinearToSlowEaseIn,
                    builder: (BuildContext context, double value, Widget? formChild) {
                      final double currentLeftX = (maxWidth > 500 ? (maxWidth - formCenterWidth) / 2 : 0.0) * (1 - value);
                      final double currentLeftWidth = formCenterWidth + (splitSideWidth - formCenterWidth) * value;

                      return Stack(
                        children: <Widget>[
                          // Left Form
                          Positioned(
                            left: currentLeftX,
                            top: 0,
                            bottom: 0,
                            width: currentLeftWidth,
                            child: Align(
                              alignment: Alignment(0, -value),
                              child: SizedBox(
                                width: double.infinity,
                                child: formChild!,
                              ),
                            ),
                          ),
                          // Divider
                          if (value > 0.01)
                            Positioned(
                              left: currentLeftX + currentLeftWidth + 20,
                              top: 0,
                              bottom: 0,
                              width: 16,
                              child: Opacity(
                                opacity: value,
                                child: VerticalDivider(
                                  thickness: 1,
                                  color: context.colorScheme.strokeLight,
                                ),
                              ),
                            ),
                          // Right — Device list (reactive)
                          if (value > 0.01)
                            Positioned(
                              left: currentLeftX + currentLeftWidth + 56,
                              top: 0,
                              bottom: 0,
                              width: splitSideWidth,
                              child: Opacity(
                                opacity: value,
                                child: FractionalTranslation(
                                  translation: Offset(0.05 * (1 - value), 0),
                                  child: _buildDeviceListSection(),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    child: _buildFormSection(),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 300,
                child: FusionNeumorphicButton(
                  semanticId: 'verify_and_proceed_button',
                  text: 'Verify and proceed',
                  onTap: _verify,
                  height: 35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Set a VIP address for Fusion hardware.',
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              FusionCheckbox(
                semanticId: 'vip_configuration_auto_select',
                value: _isAutoSelect,
                onChanged: () {
                  final bool newValue = !_isAutoSelect;
                  setState(() {
                    _isAutoSelect = newValue;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Select device automatically',
                style: TextStyle(
                  color: context.colorScheme.textBody,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Virtual IP address',
            style: TextStyle(
              color: context.colorScheme.textLabel,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _vipController,
            validator: VipConfigViewModel.validateIp,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: '192.168.0.100',
              hintStyle: TextStyle(
                color: context.colorScheme.textPlaceholder,
                fontSize: 14,
              ),
              filled: true,
              fillColor: context.colorScheme.elevation2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.colorScheme.strokeLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.colorScheme.strokeLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.colorScheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 2,
                ),
              ),
              errorStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Device list (reactive via BlocBuilder)
  // ---------------------------------------------------------------------------

  Widget _buildDeviceListSection() {
    return BlocBuilder<MdnsScanViewModel, DeviceScanState>(
      builder: (BuildContext context, DeviceScanState state) {
        final List<MdnsDevice> devices = _devicesFromState(state);
        final bool isStillScanning = _isScanningFromState(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'List of the devices on the Fusion network',
                    style: TextStyle(
                      color: context.colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isStillScanning)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colorScheme.primaryColor,
                      ),
                    ),
                  ),
                if (!isStillScanning)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => context.read<MdnsScanViewModel>().retryScan(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.refresh,
                              size: 14,
                              color: context.colorScheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Retry',
                              style: TextStyle(
                                color: context.colorScheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (devices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Text(
                    isStillScanning ? 'Searching for devices…' : 'No devices found',
                    style: TextStyle(
                      color: context.colorScheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MdnsDevice device = devices[index];
                    final bool isSelected = _selectedDevice != null && _selectedDevice!.stableId == device.stableId;
                    return _buildDeviceItem(device, isSelected);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceItem(MdnsDevice device, bool isSelected) {
    final String addressLabel = '${device.ip}:${device.port}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap:
                  _isAutoSelect
                      ? null
                      : () {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
              child: Opacity(
                opacity: _isAutoSelect ? 0.5 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? context.colorScheme.green : context.colorScheme.strokeLight,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Device info column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Device name
                            Text(
                              device.name,
                              style: TextStyle(
                                color: context.colorScheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Hostname
                            if (device.hostname.isNotEmpty)
                              _buildInfoRow(
                                Icons.dns_outlined,
                                device.hostname,
                              ),
                            // IP:Port
                            _buildInfoRow(
                              Icons.lan_outlined,
                              addressLabel,
                            ),
                            // Attributes
                            if (device.attributes.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children:
                                    device.attributes.entries
                                        .map(
                                          (MapEntry<String, String> entry) => _buildAttributeChip(entry.key, entry.value),
                                        )
                                        .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Selection indicator
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? context.colorScheme.green : context.colorScheme.strokeDark,
                              width: 1.5,
                            ),
                            color: isSelected ? context.colorScheme.green : Colors.transparent,
                          ),
                          child:
                              isSelected
                                  ? Icon(
                                    Icons.check,
                                    size: 14,
                                    color: context.colorScheme.iconWhite,
                                  )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Identify button
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colorScheme.strokeLight,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: context.colorScheme.primaryWhite,
                ),
                onPressed: () {
                  // Identify logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a compact icon + text row for device metadata.
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 13,
            color: context.colorScheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.colorScheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a small chip displaying a key-value attribute pair.
  Widget _buildAttributeChip(String key, String value) {
    final String label = value.isNotEmpty ? '$key: $value' : key;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.colorScheme.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Verify
  // ---------------------------------------------------------------------------

  void _verify() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String vip = _vipController.text.trim();

    // Resolve which device IP to target.
    final MdnsDevice? targetDevice = _isAutoSelect ? _devicesFromState(context.read<MdnsScanViewModel>().state).firstOrNull : _selectedDevice;

    if (targetDevice == null) {
      FusionToast.error(context, message: 'No device available. Please wait or retry the scan.');
      return;
    }

    context.read<VipConfigViewModel>().setVip(
      vip: vip,
      deviceIp: targetDevice.ip,
    );
  }
}
