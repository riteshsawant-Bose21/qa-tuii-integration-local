import '../models/models.dart';

/// Container for all product data from the API
///
/// This class holds all product types and the version string
/// for cache invalidation.
class ProductCatalog {
  final String version;
  final List<SpeakerProduct> speakers;
  final List<AmplifierProduct> amplifiers;
  final List<ControllerProduct> controllers;
  final List<DspProduct> dsps;
  final List<AccessoryProduct> accessories;
  final List<IoEndpointProduct> ioEndpoints;

  const ProductCatalog({
    required this.version,
    this.speakers = const [],
    this.amplifiers = const [],
    this.controllers = const [],
    this.dsps = const [],
    this.accessories = const [],
    this.ioEndpoints = const [],
  });

  /// Creates an empty catalog with default version
  factory ProductCatalog.empty() => const ProductCatalog(version: '');

  /// Creates from API JSON response
  factory ProductCatalog.fromJson(Map<String, dynamic> json) {
    return ProductCatalog(
      version: json['version'] as String? ?? '',
      speakers: (json['speakers'] as List<dynamic>?)?.map((e) => SpeakerProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      amplifiers: (json['amplifiers'] as List<dynamic>?)?.map((e) => AmplifierProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      controllers: (json['controllers'] as List<dynamic>?)?.map((e) => ControllerProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      dsps: (json['digital_signal_processors'] as List<dynamic>?)?.map((e) => DspProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      accessories: (json['additional_accessories'] as List<dynamic>?)?.map((e) => AccessoryProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      ioEndpoints: (json['i_o_endpoints'] as List<dynamic>?)?.map((e) => IoEndpointProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'speakers': speakers.map((e) => e.toJson()).toList(),
    'amplifiers': amplifiers.map((e) => e.toJson()).toList(),
    'controllers': controllers.map((e) => e.toJson()).toList(),
    'digital_signal_processors': dsps.map((e) => e.toJson()).toList(),
    'additional_accessories': accessories.map((e) => e.toJson()).toList(),
    'i_o_endpoints': ioEndpoints.map((e) => e.toJson()).toList(),
  };

  /// Check if catalog has any products
  bool get isEmpty => speakers.isEmpty && amplifiers.isEmpty && controllers.isEmpty && dsps.isEmpty && accessories.isEmpty && ioEndpoints.isEmpty;

  /// Get total product count
  int get totalCount => speakers.length + amplifiers.length + controllers.length + dsps.length + accessories.length + ioEndpoints.length;

  @override
  String toString() => 'ProductCatalog(version: $version, totalCount: $totalCount)';
}
