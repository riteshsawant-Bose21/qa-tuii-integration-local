import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

// Assuming you have the Ripple Widget from the previous step
// If not, replace with a standard Loading Indicator or Icon
import '../widgets/ripple_animation.dart';

enum BluetoothSetupState {
  wifiInput,
  scanning,
  noDevices, // Edge case
  deviceList, // Success case
}

class BluetoothSetupPage extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const BluetoothSetupPage({
    super.key,
    required this.onFinish,
    required this.onBack,
  });

  @override
  State<BluetoothSetupPage> createState() => _BluetoothSetupPageState();
}

class _BluetoothSetupPageState extends State<BluetoothSetupPage> {
  // Navigation State
  BluetoothSetupState _currentState = BluetoothSetupState.wifiInput;

  // Form Controllers
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedSecurity = 'WPA2/WPA3 Personal';

  // Mock Logic State
  bool _isMockEmptyCase = false; // To toggle between empty and list for demo

  // Add this to your State class variables
  String? _selectedDeviceId = 'fusion_mini_1'; // Default selection or null

  Timer? _scanTimer;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _currentState = BluetoothSetupState.scanning;
    });

    // Mock Timer: Simulate 3 seconds of scanning
    _scanTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          // Toggle between "No Devices" and "Device List" for demo purposes
          // In real app, check actual bluetooth results
          if (_isMockEmptyCase) {
            _currentState = BluetoothSetupState.noDevices;
          } else {
            _currentState = BluetoothSetupState.deviceList;
          }
          // Flip the mock switch for next time (so you can see both screens)
          _isMockEmptyCase = !_isMockEmptyCase;
        });
      }
    });
  }

  void _handleBack() {
    if (_scanTimer != null && _scanTimer!.isActive) {
      _scanTimer!.cancel();
    }
    setState(() {
      if (_currentState == BluetoothSetupState.wifiInput) {
        widget.onBack(); // Exit the page
      } else if (_currentState == BluetoothSetupState.scanning) {
        // Cancel scan and go back
        _currentState = BluetoothSetupState.wifiInput;
      } else {
        // From List or NoDevices, go back to Wifi Input?
        // Or re-scan? Usually back to Wifi Input or Previous step.
        _currentState = BluetoothSetupState.wifiInput;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentState) {
      case BluetoothSetupState.wifiInput:
        return _buildWifiInputView();
      case BluetoothSetupState.scanning:
        return _buildScanningView();
      case BluetoothSetupState.noDevices:
        return _buildNoDevicesView();
      case BluetoothSetupState.deviceList:
        return _buildDeviceListView();
    }
  }

  // --------------------------------------------------------------------------
  // VIEW 1: WIFI CREDENTIALS INPUT
  // --------------------------------------------------------------------------
  Widget _buildWifiInputView() {
    return SizedBox(
      width: 0.3 * MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          key: const ValueKey<String>('WifiInput'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Wifi Credentials',
                style: TextStyle(
                  fontSize: 24,
                  color: context.colorScheme.primaryBlack,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Info Box
            _buildInfoBox(
              'Enter the credentials of the wifi network you want to connect your devices.',
            ),
            const SizedBox(height: 32),

            Text(
              'Set Wifi Credentials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 24),

            // Network Name Field
            _buildLabel('Network name (SSID/Username) *'),
            const SizedBox(height: 8),
            _buildTextField(controller: _ssidController, hint: 'e.g., MyWifi'),
            const SizedBox(height: 20),

            // Security Dropdown
            _buildLabel('Security'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: context.colorScheme.greyLight.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSecurity,
                  dropdownColor: const Color(0xFF111111),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: context.colorScheme.primaryBlack),
                  style: TextStyle(color: context.colorScheme.primaryBlack),
                  items:
                      <String>['WPA2/WPA3 Personal', 'Open', 'WEP'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? val) => setState(() => _selectedSecurity = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildLabel('Password *'),
            const SizedBox(height: 8),
            _buildTextField(controller: _passwordController, hint: '****************', isObscure: true),

            const SizedBox(height: 20),

            // Bottom Buttons
            Row(
              children: <Widget>[
                _buildNavButton(
                  label: 'Go back',
                  onPressed: _handleBack,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNavButton(
                    label: 'Continue',
                    onPressed: _startScanning, // Go to next step
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VIEW 2: BLUETOOTH SCANNING
  // --------------------------------------------------------------------------
  Widget _buildScanningView() {
    return SizedBox(
      width: 0.3 * MediaQuery.of(context).size.width,
      child: Stack(
        key: const ValueKey<String>('Scanning'),
        children: <Widget>[
          // Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NeumorphicRippleWidget(
                  backgroundColor: context.colorScheme.primaryBlack,
                  animationDuration: const Duration(seconds: 4),
                  ripplesCount: 4,
                  minRadius: 25,
                  maxRadius: 200,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryWhite,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: context.colorScheme.primaryWhite.withAlpha((0.8 * 255).toInt()),
                          offset: const Offset(-4, -4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bluetooth, // Or auto_awesome for "Fusion" feel
                      size: 24,
                      color: context.colorScheme.primaryBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                Text(
                  'Hold on, searching for bluetooth devices...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colorScheme.primaryBlack),
                ),
                const SizedBox(height: 16),
                _buildInfoBox('Make sure your device is powered on and in Bluetooth pairing mode'),
              ],
            ),
          ),

          // Bottom Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildNavButton(
                label: 'Go back',
                onPressed: _handleBack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VIEW 3: NO DEVICES FOUND (Edge Case)
  // --------------------------------------------------------------------------
  Widget _buildNoDevicesView() {
    return SizedBox(
      width: 0.3 * MediaQuery.of(context).size.width,
      child: Stack(
        key: const ValueKey<String>('NoDevices'),
        children: <Widget>[
          // Top Header with Refresh
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Bluetooth Devices',
                    style: TextStyle(fontSize: 20, color: context.colorScheme.primaryBlack),
                  ),
                  _buildRefreshButton(),
                ],
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'No Devices Found!!',
                  style: TextStyle(color: context.colorScheme.greyLight, fontSize: 14),
                ),
                const SizedBox(height: 40),
                _buildInfoBox('Make sure your device is powered on and in Bluetooth pairing mode'),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _buildNavButton(
              label: 'Go back',
              onPressed: _handleBack,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VIEW 4: DEVICE LIST
  // --------------------------------------------------------------------------
  Widget _buildDeviceListView() {
    return SizedBox(
      width: 0.3 * MediaQuery.of(context).size.width,
      child: Column(
        key: const ValueKey<String>('DeviceList'),
        children: <Widget>[
          const SizedBox(height: 20),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Bluetooth Devices',
                style: TextStyle(
                  fontSize: 20,
                  color: context.colorScheme.primaryBlack,
                ),
              ),
              _buildRefreshButton(),
            ],
          ),
          const SizedBox(height: 24),

          // Info
          _buildInfoBox('Make sure your device is powered on and in Bluetooth pairing mode'),
          const SizedBox(height: 32),

          // List Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available Bluetooth Devices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primaryBlack,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List Items (Expanded to scroll)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDeviceItem(
                  name: 'Fusion Mini FM6',
                  subtitle: 'Connected to NamithGym',
                  // RADIO LOGIC:
                  value: 'fusion_mini_1', // Unique ID for this item
                  groupValue: _selectedDeviceId, // The currently selected ID
                  onChanged: (String? val) {
                    setState(() {
                      _selectedDeviceId = val;
                    });
                  },
                  buttonLabel: 'Disconnect from Wifi',
                  onPressed: () {},
                ),
                _buildDeviceItem(
                  name: 'Fusion Mini FM6',
                  value: 'fusion_mini_2',
                  groupValue: _selectedDeviceId,
                  onChanged: (String? val) {
                    setState(() {
                      _selectedDeviceId = val;
                    });
                  },
                  buttonLabel: 'Send Credentials',
                  onPressed: () {},
                ),
                _buildDeviceItem(
                  name: 'PowerSmart8300',
                  value: 'powersmart_1',
                  groupValue: _selectedDeviceId,
                  onChanged: (String? val) {
                    setState(() {
                      _selectedDeviceId = val;
                    });
                  },
                  buttonLabel: 'Send Credentials',
                  onPressed: () {},
                ),
                _buildDeviceItem(
                  name: 'PowerSmart8300',
                  value: 'powersmart_2',
                  groupValue: _selectedDeviceId,
                  onChanged: (String? val) {
                    setState(() {
                      _selectedDeviceId = val;
                    });
                  },
                  buttonLabel: 'Send Credentials',
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Footer Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildNavButton(
                label: 'Go back',
                onPressed: _handleBack,
              ),
              const SizedBox(width: 16),
              _buildNavButton(
                label: 'Finish',
                onPressed: widget.onFinish,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildRefreshButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
        onPressed: _startScanning, // Refresh restarts scan
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      width: 0.3 * MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.greyLight.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line
        children: <Widget>[
          Icon(Icons.info_outline, color: context.colorScheme.greyLight, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.colorScheme.greyLight, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: context.colorScheme.primaryBlack, fontSize: 14));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: context.colorScheme.primaryBlack),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF111111),
        hintText: hint,
        hintStyle: TextStyle(color: context.colorScheme.greyLight.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colorScheme.greyLight.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colorScheme.greyLight.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    // If not primary (like "Go Back"), use a fixed smaller width or different style
    // Based on screenshots, "Go Back" is small, "Continue" is wider/filled.

    return Container(
      height: 40,
      width: 100,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C), // Both use dark grey in screenshots
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildDeviceItem({
    required String name,
    String? subtitle,
    required String value, // UNIQUE ID for this device (e.g., device name)
    required String? groupValue, // The ID of the currently selected device
    required ValueChanged<String?> onChanged, // Callback returning the new selection
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.greyLight.withOpacity(0.1), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          // 1. Name and Subtitle
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    color: context.colorScheme.primaryBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.colorScheme.greyLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. The Radio Button (Replaces Checkbox)
          Transform.scale(
            scale: 0.9,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              // Styling to match your previous look
              activeColor: context.colorScheme.primaryBlack,
              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colorScheme.primaryBlack;
                }
                return context.colorScheme.greyLight;
              }),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(width: 8),

          // 3. Lightbulb Icon
          Icon(
            Icons.lightbulb_outline,
            color: context.colorScheme.primaryBlack,
            size: 18,
          ),
          const SizedBox(width: 12),

          // 4. Action Button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  foregroundColor: context.colorScheme.greyLight,
                  elevation: 0,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
