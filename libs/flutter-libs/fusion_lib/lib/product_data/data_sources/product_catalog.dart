import '../models/models.dart';
import '../models/output_product.dart';

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
  final List<SourceProduct> sources;
  final List<OutputProduct> outputs;

  const ProductCatalog({
    required this.version,
    this.speakers = const [],
    this.amplifiers = const [],
    this.controllers = const [],
    this.dsps = const [],
    this.accessories = const [],
    this.ioEndpoints = const [],
    this.sources = const [],
    this.outputs = const [],
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
      sources: (json['source'] as List<dynamic>?)?.map((e) => SourceProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      outputs: (json['output'] as List<dynamic>?)?.map((e) => OutputProduct.fromJson(e as Map<String, dynamic>)).toList() ?? [],
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
    'source': sources.map((e) => e.toJson()).toList(),
    'output': outputs.map((e) => e.toJson()).toList(),
  };
}
