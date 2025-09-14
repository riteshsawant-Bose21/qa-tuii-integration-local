import '../../fusion_utils/app_enums.dart';

/// Unified Product model
class ProductQueryModel {
  const ProductQueryModel({
    required this.name,
    required this.price,
    required this.image,
    required this.type,
    this.specifications = '',
    required this.sku,
  });

  final String name;
  final double price;
  final String image;
  final ProductType type;
  final String sku;
  final String specifications;
}
