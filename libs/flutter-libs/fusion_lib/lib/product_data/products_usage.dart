// /// Products Library Usage - Simple JSON Output
// ///
// /// Run with: dart run products_usage.dart
// ///
// /// Fetches and shows products as JSON
// library;

// // ignore_for_file: avoid_print

// import 'dart:convert';
// import 'products.dart';

// Future<void> main() async {
//   const bool fusionOnly = true; // Set to true to show only Fusion compatible products
  
//   final products = Products(
//     baseUrl: 'http://fusionapi.cloud-dev-external-bpro.in:8080/api/v1',
//     networkClient: ,
//     fusionOnly: fusionOnly,
//   );
//   await products.initialize();

//   final result = {
//     'meta': {
//       'totalCount': products.totalCount,
//       'fusionOnly': fusionOnly,
//     },
//     'speakers': products.speakers.map((s) => _productToMap(s)).toList(),
//     'amplifiers': products.amplifiers.map((a) => _productToMap(a)).toList(),
//     'controllers': products.controllers.map((c) => _productToMap(c)).toList(),
//     'dsps': products.dsps.map((d) => _productToMap(d)).toList(),
//     'accessories': products.accessories.map((a) => _productToMap(a)).toList(),
//     'ioEndpoints': products.ioEndpoints.map((io) => _productToMap(io)).toList(),
//   };
  
//   print(const JsonEncoder.withIndent('  ').convert(result));
// }

// Map<String, dynamic> _productToMap(dynamic product) {
//   final Map<String, dynamic> base = {
//     'productId': product.productId,
//     'modelName': product.modelName,
//     'modelFamily': product.modelFamily,
//     'description': product.description,
//     'shortDescription': product.shortDescription,
//     'isFusionCompatible': product.isFusionCompatible,
//     'skus': product.skus,
//   };

//   // Use the product's toJson method to get the correct asset structure
//   final productJson = product.toJson();
//   base['assets'] = productJson['assets'];

//   // Add product-specific fields safely
//   try {
//     if (product.numberOfInputsAndOutputs != null) {
//       base['numberOfInputsAndOutputs'] = product.numberOfInputsAndOutputs;
//     }
//   } catch (e) {
//     // Field doesn't exist on this product type
//   }

//   try {
//     if (product.environment != null) {
//       base['environment'] = product.environment;
//     }
//   } catch (e) {
//     // Field doesn't exist on this product type
//   }

//   try {
//     if (product.mountType != null) {
//       base['mountType'] = product.mountType;
//     }
//   } catch (e) {
//     // Field doesn't exist on this product type
//   }

//   return base;
// }
