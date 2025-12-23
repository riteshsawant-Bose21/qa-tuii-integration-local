/// Products Library Usage - Full Model Fields
///
/// Run with: dart run products_usage.dart
///
/// Shows all fields from the product models
library;

// ignore_for_file: avoid_print

import 'products.dart';

Future<void> main() async {
  print('=== Products Library - Full Model Fields ===\n');

  final products = Products(baseUrl: 'http://fusionapi.cloud-dev-external-bpro.in:8080/api/v1');
  await products.initialize();

  print('Source: ${products.wasSyncedFromApi ? "API" : "LOCAL CACHE"}');
  print('Version: ${products.version}');
  print('Total: ${products.totalCount} products\n');

  // ============= SPEAKERS =============
  print('=' * 60);
  print('SPEAKERS (${products.speakers.length})');
  print('=' * 60);
  for (final s in products.speakers.take(2)) {
    print('\n📢 ${s.modelName}');
    print('   ProductId: ${s.productId}');
    print('   ModelFamily: ${s.modelFamily}');
    print('   Description: ${_truncate(s.description, 50)}');
    print('   ShortDescription: ${s.shortDescription ?? "N/A"}');
    print('   Environment: ${s.environment ?? "N/A"}');
    print('   MountType: ${s.mountType ?? "N/A"}');
    print('   IsSubwoofer: ${s.isSubwoofer}');
    print('   IsWeatherRated: ${s.isWeatherRated}');
    print('   IsHighImpedanceRated: ${s.isHighImpedanceRated}');
    print('   FrequencyRange: ${s.frequencyRange?.low}-${s.frequencyRange?.high} ${s.frequencyRange?.unit}');
    print('   MaxSpl: ${s.maxSpl?.at.map((e) => "${e.value} ${e.unit}").join(", ") ?? "N/A"}');
    print('   PowerHandling: RMS=${s.powerHandling?.longTermRms}W, Peak=${s.powerHandling?.peak}W');
    print('   NominalImpedance: ${s.nominalImpedance?.value} ${s.nominalImpedance?.unit}');
    print('   Impedance: ${s.impedance?.low}-${s.impedance?.high} ${s.impedance?.unit}');
    print('   Sensitivity: ${s.sensitivity?.at.map((e) => "${e.value} ${e.key}").join(", ") ?? "N/A"}');
    print('   Coverage: ${s.coverage.map((c) => "${c.horizontalDeg}°x${c.verticalDeg}°").join(", ")}');
    print('   AvailableTaps: 70v=${s.availableTaps?.taps70V}, 100v=${s.availableTaps?.taps100V}');
    print('   HighImpedanceTaps: ${s.highImpedanceTaps}');
    print('   BSFFileUrl: ${s.bsfFileUrl ?? "N/A"}');
    print('   SKUs: ${s.skus}');
    print('   Assets: ${s.assets.allAssetUrls.length} images');
  }

  // ============= AMPLIFIERS =============
  print('\n${"=" * 60}');
  print('AMPLIFIERS (${products.amplifiers.length})');
  print('=' * 60);
  for (final a in products.amplifiers.take(2)) {
    print('\n🔊 ${a.modelName}');
    print('   ProductId: ${a.productId}');
    print('   ModelFamily: ${a.modelFamily}');
    print('   Description: ${_truncate(a.description ?? "", 50)}');
    print('   ShortDescription: ${a.shortDescription ?? "N/A"}');
    print('   NumberOfLoudspeakerInputs: ${a.numberOfLoudspeakerInputs ?? "N/A"}');
    print('   NumberOfInputsAndOutputs:');
    print('     Analog: ${a.numberOfInputsAndOutputs?.analog?.inputs ?? 0} in / ${a.numberOfInputsAndOutputs?.analog?.outputs ?? 0} out');
    print('   SKUs: ${a.skus}');
    print('   Assets: ${a.assets.allAssetUrls.length} images');
  }

  // ============= CONTROLLERS =============
  print('\n${"=" * 60}');
  print('CONTROLLERS (${products.controllers.length})');
  print('=' * 60);
  for (final c in products.controllers.take(2)) {
    print('\n🎛️ ${c.modelName}');
    print('   ProductId: ${c.productId}');
    print('   ModelFamily: ${c.modelFamily}');
    print('   Description: ${_truncate(c.description ?? "", 50)}');
    print('   ShortDescription: ${c.shortDescription ?? "N/A"}');
    print('   ControlType: ${c.controlType ?? "N/A"}');
    print('   PhysicalSize: ${c.physicalSize ?? "N/A"}');
    print('   ZoneControlCount: ${c.zoneControlCount ?? "N/A"}');
    print('   AdditionalSensors: ${c.additionalSensors}');
    print('   ApplicableRegions: ${c.applicableRegions}');
    print('   SKUs: ${c.skus}');
    print('   Assets: ${c.assets.allAssetUrls.length} images');
  }

  // ============= DSPs =============
  print('\n${"=" * 60}');
  print('DSPs (${products.dsps.length})');
  print('=' * 60);
  for (final d in products.dsps.take(2)) {
    print('\n🖥️ ${d.modelName}');
    print('   ProductId: ${d.productId}');
    print('   ModelFamily: ${d.modelFamily}');
    print('   Description: ${_truncate(d.description ?? "", 50)}');
    print('   ShortDescription: ${d.shortDescription ?? "N/A"}');
    print('   MaxNumberOfAnalogControl: ${d.maxNumberOfAnalogControl ?? "N/A"}');
    print('   MaxNumberOfDigitalControl: ${d.maxNumberOfDigitalControl ?? "N/A"}');
    print('   GpioLogicPorts: ${d.gpioLogicPorts?.inputs ?? 0} in / ${d.gpioLogicPorts?.outputs ?? 0} out');
    print('   NumberOfInputsAndOutputs:');
    print('     Analog: ${d.numberOfInputsAndOutputs?.analog?.inputs ?? 0} in / ${d.numberOfInputsAndOutputs?.analog?.outputs ?? 0} out');
    print('   SKUs: ${d.skus}');
    print('   Assets: ${d.assets.allAssetUrls.length} images');
  }

  // ============= ACCESSORIES =============
  print('\n${"=" * 60}');
  print('ACCESSORIES (${products.accessories.length})');
  print('=' * 60);
  for (final a in products.accessories.take(20)) {
    print('\n🔧 ${a.modelName}');
    print('   ProductId: ${a.productId}');
    print('   ModelFamily: ${a.modelFamily}');
    print('   Description: ${_truncate(a.description ?? "", 50)}');
    print('   ShortDescription: ${a.shortDescription ?? "N/A"}');
    print('   Type: ${a.type ?? "N/A"}');
    print('   Quantity: ${a.quantity ?? "N/A"}');
    print('   SKUs: ${a.skus}');
    print('   Assets: ${a.assets.allAssetUrls.length} images');
  }

  // ============= IO ENDPOINTS =============
  print('\n${"=" * 60}');
  print('IO ENDPOINTS (${products.ioEndpoints.length})');
  print('=' * 60);
  for (final io in products.ioEndpoints.take(2)) {
    print('\n🔌 ${io.modelName}');
    print('   ProductId: ${io.productId}');
    print('   ModelFamily: ${io.modelFamily}');
    print('   Description: ${_truncate(io.description ?? "", 50)}');
    print('   ShortDescription: ${io.shortDescription ?? "N/A"}');
    print('   Network: ${io.network}');
    print('   Inputs: ${io.inputs?.quantity ?? 0} x ${io.inputs?.type ?? "N/A"}');
    print('   Outputs: ${io.outputs?.quantity ?? 0} x ${io.outputs?.type ?? "N/A"}');
    print('   SKUs: ${io.skus}');
    print('   Assets: ${io.assets.allAssetUrls.length} images');
  }

  // ============= IMAGE ACCESS EXAMPLE =============
  print('\n${"=" * 60}');
  print('IMAGE ACCESS EXAMPLE');
  print('=' * 60);

  if (products.speakers.isNotEmpty) {
    final speaker = products.speakers.first;
    print('\nSpeaker: ${speaker.modelName}');

    // All image URLs
    print('\n   All Image URLs:');
    for (final url in speaker.assets.allAssetUrls) {
      print('     - $url');
    }

    // By color - use getAssetsFor()
    print('\n   Black Images: ${speaker.assets.getAssetsFor("black").length}');
    print('   White Images: ${speaker.assets.getAssetsFor("white").length}');

    // Check if cached
    if (speaker.assets.allAssetUrls.isNotEmpty) {
      final url = speaker.assets.allAssetUrls.first;
      final localPath = products.getImagePath(url);
      final isCached = products.isImageCached(url);
      print('\n   First Image:');
      print('     URL: $url');
      print('     Cached: $isCached');
      print('     Local Path: $localPath');
    }
  }

  print('\n${"=" * 60}');
  print('✅ Done!');
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
