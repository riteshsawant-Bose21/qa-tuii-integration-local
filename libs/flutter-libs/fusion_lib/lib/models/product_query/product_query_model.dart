import 'dart:ui';

import '../../fusion_utils/app_enums.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Unified Product model
class ProductQueryModel {
  const ProductQueryModel({
    required this.name,
    this.series,
    required this.price,
    required this.image,
    required this.type,
    this.specifications = '',
    required this.sku,
    this.color,
    this.mountingType,
    this.outdoorRated,
    this.maxSpl,
    this.nominalOhms,
  });

  final String name;
  final String? series;
  final double price;
  final String image;
  final ProductType type;
  final String sku;
  final String specifications;
  final String? color;
  final String? mountingType;
  final bool? outdoorRated;
  final double? maxSpl;
  final double? nominalOhms;
}
