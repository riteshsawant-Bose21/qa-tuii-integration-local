/// Controller Types Module
/// 
/// This module defines the types used for Bose controllers like ControlPal series

/// Represents a controller device specification
class ControllerSpec {
  final String name;
  final String imageUrl;
  final String description;
  final double price;

  const ControllerSpec({
    required this.name,
    required this.imageUrl,
    this.description = '',
    this.price = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
    'description': description,
    'price' : price
  };
}
