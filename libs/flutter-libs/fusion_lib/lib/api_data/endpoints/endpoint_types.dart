/// Endpoint Types Module
///
/// Defines the types for Bluetooth and XLR endpoints with basic properties:
/// - name
/// - imageUrl
/// - price

/// Base class for all endpoints
abstract class EndpointDevice {
  final String name;
  final String imageUrl;
  final double price;

  const EndpointDevice({
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  Map<String, dynamic> toJson();
}

/// Represents a Bluetooth endpoint device
class BluetoothEndpoint extends EndpointDevice {
  const BluetoothEndpoint({
    required super.name,
    required super.imageUrl,
    required super.price,
  });

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
    'price': price
  };
}

/// Represents an XLR endpoint device
class XLREndpoint extends EndpointDevice {
  const XLREndpoint({
    required super.name,
    required super.imageUrl,
    required super.price,
  });

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
    'price': price
  };
}
