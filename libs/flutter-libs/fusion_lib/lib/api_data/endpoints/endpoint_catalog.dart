/// Endpoint Catalog
///
/// Contains the catalog of available Bluetooth and XLR endpoints

import 'endpoint_types.dart';

/// Catalog of all available endpoints
class EndpointCatalog {
  /// List of Bluetooth endpoints
  static const List<BluetoothEndpoint> bluetoothEndpoints = [
    BluetoothEndpoint(
      name: "Bluetooth endpoint",
      imageUrl: "assets/images/endpoints/blue_pal.png",
      price: 199.99,
    ),
  ];

  /// List of XLR endpoints
  static const List<XLREndpoint> xlrEndpoints = [
    XLREndpoint(
      name: "XLR endpoint",
      imageUrl: "assets/images/endpoints/xlr_pal.png",
      price: 299.99,
    ),
  ];

  /// Get all endpoints
  static List<EndpointDevice> getAllEndpoints() {
    return [
      ...bluetoothEndpoints,
      ...xlrEndpoints,
    ];
  }

  /// Find endpoint by name
  static EndpointDevice? findByName(String name) {
    try {
      return getAllEndpoints().firstWhere((endpoint) => endpoint.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get Bluetooth endpoints
  static List<BluetoothEndpoint> getBluetoothEndpoints() => bluetoothEndpoints;

  /// Get XLR endpoints
  static List<XLREndpoint> getXLREndpoints() => xlrEndpoints;
}
