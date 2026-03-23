import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';


/// Product service to manage different product types
class ProductAPI {
  /// Get all products from all sources
  static List<ProductQueryModel> getAllProducts() {
    return <ProductQueryModel>[
      ...getSpeakerProducts(),
      ...getAmplifierProducts(),
      ...getDeviceProducts(),
      ...getControllers(),
      ...getEndpoints(),
    ];
  }

  /// Get products by type
  static List<ProductQueryModel> getProductsByType(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return getSpeakerProducts();
      case ProductType.amplifier:
        return getAmplifierProducts();
      case ProductType.controllers:
        return getControllers();
      case ProductType.endpoints:
        return getEndpoints();
      case ProductType.dsps:
        return getDeviceProducts();
      case ProductType.sources:
      case ProductType.racks:
        return <ProductQueryModel>[];
    }
  }

  /// Convert speaker models to products using fusion_lib
  static List<ProductQueryModel> getSpeakerProducts() {
    try {
      final String speakersJson = fusionDevices.getSpeakers();
      final List<dynamic> speakersData = jsonDecode(speakersJson);
      return speakersData.map((dynamic speakerData) {
        return ProductQueryModel(
          name: speakerData['model'] ?? '',
          price: (speakerData['price'] ?? 0.0).toDouble(),
          image: speakerData["image_url"] ?? '',
          type: ProductType.speaker,
          color: speakerData["color"],
          mountingType: speakerData["mounting_type"],
          outdoorRated: speakerData["outdoor_rated"],
          maxSpl: speakerData["max_spl"] != null ? (speakerData["max_spl"] as num).toDouble() : null,
          nominalOhms: speakerData["nominal_ohms"] != null ? (speakerData["nominal_ohms"] as num).toDouble() : null,
          sku: speakerData['model'] ?? '',
          specifications: '',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert amplifier models to products using fusion_lib
  static List<ProductQueryModel> getAmplifierProducts() {
    try {
      final String amplifiersJson = fusionDevices.getAmplifiers();
      final List<dynamic> amplifiersData = jsonDecode(amplifiersJson);

      return amplifiersData.map((dynamic ampData) {
        return ProductQueryModel(
          name: ampData['name'] ?? '',
          series: ampData['series'] ?? '',
          price: ampData['price'] != null ? (ampData['price'] as num).toDouble() : 0.0,
          image: ampData['image_url'] ?? '',
          type: ProductType.amplifier,
          sku: ampData['name'] ?? '',
          specifications: '${ampData['channels']}ch • ${(ampData['peakPerChannel'] ?? 0).toInt()}W per ch',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert device specs to products using fusion_lib
  static List<ProductQueryModel> getDeviceProducts() {
    try {
      final String devicesJson = fusionDevices.getDevices();
      final List<dynamic> devicesData = jsonDecode(devicesJson);

      return devicesData.map((dynamic deviceData) {
        return ProductQueryModel(
          name: deviceData['name'] ?? '',
          price: deviceData['price'] != null ? (deviceData['price'] as num).toDouble() : 0.0,
          image: deviceData['image_url'] ?? '',
          type: ProductType.dsps,
          sku: deviceData['name'] ?? '',
          specifications: '${deviceData['analogInputs'] ?? 0}in • ${deviceData['analogOutputs'] ?? 0}out • ${deviceData['networkIO'] ?? 0} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert controllers specs to products using fusion_lib
  static List<ProductQueryModel> getControllers() {
    try {
      final String controllersJson = fusionDevices.getControllers();
      final List<dynamic> controllersData = jsonDecode(controllersJson);

      return controllersData.map((dynamic data) {
        return ProductQueryModel(
          name: data['name'] ?? '',
          price: data["price"] != null ? (data['price'] as num).toDouble() : 0.0,
          image: data['imageUrl'] ?? '',
          type: ProductType.controllers,
          sku: data['name'] ?? '',
          specifications: '${data['analogInputs'] ?? 0}in • ${data['analogOutputs'] ?? 0}out • ${data['networkIO'] ?? 0} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert endpoints specs to products using fusion_lib
  static List<ProductQueryModel> getEndpoints() {
    try {
      final String controllersJson = fusionDevices.getAllEndpoints();
      final List<dynamic> controllersData = jsonDecode(controllersJson);

      return controllersData.map((dynamic deviceData) {
        return ProductQueryModel(
          name: deviceData['name'] ?? '',
          price: deviceData['price'] != null ? (deviceData['price'] as num).toDouble() : 0.0,
          image: deviceData['imageUrl'] ?? '',
          type: ProductType.endpoints,
          sku: deviceData['name'] ?? '',
          specifications: '${deviceData['analogInputs'] ?? 0}in • ${deviceData['analogOutputs'] ?? 0}out • ${deviceData['networkIO'] ?? 0} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }
}
