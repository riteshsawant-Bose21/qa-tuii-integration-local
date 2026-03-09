// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:fusion_launcher/features/projects/viewmodel/eql_products_vm.dart';
import 'package:fusion_lib/product_data/models/product_port_data.dart';

class EQLProduct {
  final String name;
  final String? assetPath;
  final String description;
  final String modelFamily;
  final dynamic data;
  final String searchingFields;
  final EQLDeviceType deviceType;
  final double price;
  final Map<String, String> specifications;
  final ProductPortData portData;
  EQLProduct({
    required this.name,
    required this.assetPath,
    required this.description,
    required this.modelFamily,
    required this.data,
    required this.searchingFields,
    required this.deviceType,
    required this.price,
    required this.specifications,
    required this.portData,
  });
}
