import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class VIPConfigurationScreen extends StatefulWidget {
  final List<MdnsDevice> devices;
  final Function(String) onVerify;

  const VIPConfigurationScreen({
    super.key,
    required this.devices,
    required this.onVerify,
  });

  @override
  State<VIPConfigurationScreen> createState() => _VIPConfigurationScreenState();
}

class _VIPConfigurationScreenState extends State<VIPConfigurationScreen> {
  final TextEditingController _vipController = TextEditingController();
  MdnsDevice? _selectedDevice;
  bool _isAutoSelect = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _vipController.text = '192.168.0.100'; // Default value
    if (widget.devices.isNotEmpty) {
      _selectedDevice = widget.devices.first;
    }
  }

  @override
  void dispose() {
    _vipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                // 56 is the total width of the middle gap: 20 + 16(VerticalDivider) + 20
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
                            alignment: Alignment(0, -value), // Animate from center vertically to top
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
                        // Right Devices
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
          // Bottom Button
          Center(
            child: SizedBox(
              width: 300,
              child: FusionNeumorphicButton(
                text: 'Verify and proceed',
                onTap: _verify,
                height: 35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
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
        TextField(
          controller: _vipController,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'List of the devices on the Fusion network',
          style: TextStyle(
            color: context.colorScheme.textPrimary,
            fontSize: 16, // Slightly smaller than main title? Or match 20? Design looks same font size maybe slightly smaller
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: widget.devices.length,
            itemBuilder: (BuildContext context, int index) {
              final MdnsDevice device = widget.devices[index];
              final bool isSelected = _selectedDevice == device;
              // If auto-select is on, maybe we disable selection or show auto-selected behavior?
              // For now, allow selection but maybe ignore if auto-select is true during verify?
              // UI wise, let's keep it interactive unless _isAutoSelect disables it.
              return _buildDeviceItem(device, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(MdnsDevice device, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colorScheme.strokeLight,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          device.name,
                          style: TextStyle(
                            color: context.colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Selection circle
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? context.colorScheme.green : context.colorScheme.strokeDark, // Use green for selected based on screenshot
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 42, // Match height roughly
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
        ],
      ),
    );
  }

  void _verify() {
    if (_vipController.text.isEmpty) {
      FusionToast.error(context, message: "Please enter a VIP address.");
      return;
    }

    if (!_isAutoSelect && _selectedDevice == null) {
      FusionToast.error(context, message: "Please select a device.");
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    widget.onVerify(_vipController.text);
  }
}
