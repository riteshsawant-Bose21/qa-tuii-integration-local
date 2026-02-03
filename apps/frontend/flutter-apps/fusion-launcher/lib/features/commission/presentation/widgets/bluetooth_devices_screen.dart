import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'network_config_state.dart';

class BluetoothDevicesScreen extends StatefulWidget {
  final List<BluetoothDevice> devices;
  final Function(WiFiCredentials, List<BluetoothDevice>) onSendCredentials;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;

  const BluetoothDevicesScreen({
    super.key,
    required this.devices,
    required this.onRetry,
    required this.onSendCredentials,
    required this.onGoBack,
  });

  @override
  State<BluetoothDevicesScreen> createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _securityType = 'WPA2/WPA3 Personal';
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _ssidController.text = 'Namith Gym';

    // Add listeners to trigger rebuilds when text changes (for button validation)
    _ssidController.addListener(_updateFormState);
    _passwordController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _ssidController.removeListener(_updateFormState);
    _passwordController.removeListener(_updateFormState);
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    setState(() {});
  }

  // Getter to check if the form is valid
  bool get _isFormValid {
    final bool hasText = _ssidController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    final bool hasDevice = widget.devices.any((BluetoothDevice d) => d.isSelected);
    return hasText && hasDevice;
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Left side - WiFi credentials
                Expanded(
                  flex: 1,
                  child: _buildWiFiCredentialsForm(),
                ),
                const SizedBox(width: 48),
                // Divider
                Container(
                  width: 1,
                  color: context.colorScheme.strokeLight,
                ),
                const SizedBox(width: 48),
                // Right side - Bluetooth devices
                Expanded(
                  flex: 1,
                  child: _buildBluetoothDevicesList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FusionSecondaryButton(
                text: 'Go back',
                onPressed: widget.onGoBack,
                height: 35,
              ),
              const SizedBox(width: 24),
              // Bottom Button
              Opacity(
                // Visually dim the button if disabled
                opacity: _isFormValid ? 1.0 : 0.5,
                child: SizedBox(
                  width: 300,
                  child: FusionNeumorphicButton(
                    text: 'Send Wifi credentials',
                    // Disable tap if form is invalid
                    onTap: _isFormValid ? _sendCredentials : () {},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWiFiCredentialsForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Enter Wifi Credentials',
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.colorScheme.iconDefault,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter the credentials of the wifi network you want to connect your devices.',
                  style: TextStyle(
                    color: context.colorScheme.textBody,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Network name (SSID/Username) *',
            style: TextStyle(
              color: context.colorScheme.textLabel,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _ssidController,
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter network name',
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
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Security',
            style: TextStyle(
              color: context.colorScheme.textLabel,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _securityType,
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 14,
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: context.colorScheme.iconDefault),
            decoration: InputDecoration(
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
            ),
            dropdownColor: context.colorScheme.elevation2,
            items:
                <String>[
                  'WPA2/WPA3 Personal',
                  'WPA2 Personal',
                  'WPA Personal',
                  'WEP',
                  'None',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _securityType = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Password',
            style: TextStyle(
              color: context.colorScheme.textLabel,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter password',
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
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: context.colorScheme.iconDefault,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothDevicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Bluetooth Devices',
              style: TextStyle(
                color: context.colorScheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.colorScheme.strokeLight),
              ),
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: context.colorScheme.iconDefault,
                ),
                onPressed: widget.onRetry,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'List of the available Bluetooth devices',
          style: TextStyle(
            color: context.colorScheme.textBody,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: widget.devices.length,
            itemBuilder: (BuildContext context, int index) {
              final BluetoothDevice device = widget.devices[index];
              return _buildDeviceItem(device);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(BluetoothDevice device) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          // Container 1: Device Name & Selection (Takes available space)
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  device.isSelected = !device.isSelected;
                });
              },
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
                    // Selection Circle (Radio style)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: device.isSelected ? context.colorScheme.primaryColor : context.colorScheme.strokeDark,
                          width: 1.5,
                        ),
                        // Transparent center unless you want it filled
                        color: Colors.transparent,
                      ),
                      // Optional: Add check icon or fill if selected
                      child:
                          device.isSelected
                              ? Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.colorScheme.primaryColor,
                                  ),
                                ),
                              )
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Container 2: Identify Button (Separate Container)
          Container(
            height: 40, // Approx matching height of the left container (14font + 16top + 16bottom + borders)
            width: 40,
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
                // Identify device action
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendCredentials() async {
    final List<BluetoothDevice> selectedDevices = widget.devices.where((BluetoothDevice? d) => d?.isSelected ?? false).toList();

    // Safety check (redundant if button is disabled properly, but good practice)
    if (selectedDevices.isEmpty || _ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    final WiFiCredentials credentials = WiFiCredentials(
      ssid: _ssidController.text,
      password: _passwordController.text,
      securityType: _securityType,
    );

    widget.onSendCredentials(credentials, selectedDevices);
  }
}
