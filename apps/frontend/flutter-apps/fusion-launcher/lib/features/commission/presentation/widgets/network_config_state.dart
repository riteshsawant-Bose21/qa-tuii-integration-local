/// Enum representing different states of the network configuration flow
enum NetworkConfigState {
  initial,
  mdnsSearching,
  mdnsRetry,
  bluetoothSearching,
  bluetoothRetry,
  bluetoothDevicesFound,
  vipConfiguration,
  success,
}

/// Model for Bluetooth device
class BluetoothDevice {
  final String id;
  final String name;
  bool isSelected;

  BluetoothDevice({
    required this.id,
    required this.name,
    this.isSelected = false,
  });
}

/// Model for WiFi credentials
class WiFiCredentials {
  final String ssid;
  final String password;
  final String securityType;

  WiFiCredentials({
    required this.ssid,
    required this.password,
    required this.securityType,
  });
}
