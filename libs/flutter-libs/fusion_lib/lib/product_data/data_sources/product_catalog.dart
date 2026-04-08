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
      speakers: (json['speaker'] as List<dynamic>?)?.map((e) => SpeakerProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      amplifiers: (json['amplifier'] as List<dynamic>?)?.map((e) => AmplifierProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      controllers: (json['controller'] as List<dynamic>?)?.map((e) => ControllerProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      dsps: (json['dsp'] as List<dynamic>?)?.map((e) => DspProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      ioEndpoints: (json['io_endpoint'] as List<dynamic>?)?.map((e) => IoEndpointProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      accessories: (json['additional_accessories'] as List<dynamic>?)?.map((e) => AccessoryProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'speaker': speakers.map((e) => e.toJson()).toList(),
    'amplifier': amplifiers.map((e) => e.toJson()).toList(),
    'controller': controllers.map((e) => e.toJson()).toList(),
    'dsp': dsps.map((e) => e.toJson()).toList(),
    'io_endpoint': ioEndpoints.map((e) => e.toJson()).toList(),
    'additional_accessories': accessories.map((e) => e.toJson()).toList(),
  };

  /// Check if catalog has any products
  bool get isEmpty => speakers.isEmpty && amplifiers.isEmpty && controllers.isEmpty && dsps.isEmpty && accessories.isEmpty && ioEndpoints.isEmpty;

  /// Get total product count
  int get totalCount => speakers.length + amplifiers.length + controllers.length + dsps.length + accessories.length + ioEndpoints.length;

  @override
  String toString() => 'ProductCatalog(version: $version, totalCount: $totalCount)';
}
