import 'package:fusion_lib/fusion_algorithms/device_recommender/dsp_device_recommendation.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';

import '../../../speaker_selection_popup/viewmodel/product_query_view_model.dart';

class DeviceSuggestionUseCase {
  final ProductQueryViewModel productQueryVM;
  DeviceSuggestionUseCase({required this.productQueryVM});

  DeviceSuggestionResult suggest({
    required List<Source> sources,
    required List<CircuitModel> circuits,
  }) {
    final int noOfAnalogInputs = sources.where((Source s) => s.connectionType == SourceConnectionType.analogInput).length;
    final int noOfOutput = circuits.length;
    final ({List<RecommendedDeviceResult> powerPure, List<RecommendedDeviceResult> powerSmart}) recommendation = DspDeviceRecommendation().recommendDevices(
      analogInputs: noOfAnalogInputs,
      analogOutputs: noOfOutput,
    );
    final List<AmplifierProduct> amplifiers = productQueryVM.amplifiers;
    final List<DspProduct> dsps = productQueryVM.dsps;

    final Map<String, AmplifierProduct> mappedAmpProduct = <String, AmplifierProduct>{};
    for (({String device, String family, int input, int output}) device in DspDeviceRecommendation().amps) {
      final AmplifierProduct? firstWhereOrNull = amplifiers.firstWhereOrNull(
        (AmplifierProduct amp) =>
            amp.numberOfInputsAndOutputs?.analog?.inputs == device.input &&
            amp.numberOfInputsAndOutputs?.loudspeakerPorts?.outputs == device.output &&
            amp.modelFamily.toLowerCase().contains(device.family.toLowerCase()),
      );
      if (firstWhereOrNull == null) {
        print("No matching amplifier found for ${device.device} with ${device.input} inputs and ${device.output} outputs");
        continue;
      }
      mappedAmpProduct[device.device] = firstWhereOrNull;
    }

    final Map<String, DspProduct> mappedDspProduct = <String, DspProduct>{};
    for (({String device, int input, int output}) device in DspDeviceRecommendation().dsps) {
      final DspProduct? firstWhereOrNull = dsps.firstWhereOrNull(
        (DspProduct dsp) =>
            dsp.numberOfInputsAndOutputs?.analog?.inputBalanced == device.input && dsp.numberOfInputsAndOutputs?.analog?.outputBalanced == device.output,
      );
      if (firstWhereOrNull == null) {
        print("No matching DSP found for ${device.device} with ${device.input} inputs and ${device.output} outputs");
        continue;
      }
      mappedDspProduct[device.device] = firstWhereOrNull;
    }

    final num ppPrice = _calculateCombinationPrice(
      combination: recommendation.powerPure,
      mappedAmpProduct: mappedAmpProduct,
      mappedDspProduct: mappedDspProduct,
    );
    final num psPrice = _calculateCombinationPrice(
      combination: recommendation.powerSmart,
      mappedAmpProduct: mappedAmpProduct,
      mappedDspProduct: mappedDspProduct,
    );

    print("PowerPure combination price: $ppPrice");
    print("PowerSmart combination price: $psPrice");

    final List<RecommendedDeviceResult> chosenCombination = ppPrice <= psPrice ? recommendation.powerPure : recommendation.powerSmart;
    final List<({AmplifierProduct product, int quantity})> amps =
        chosenCombination
            .where((RecommendedDeviceResult r) => mappedAmpProduct.containsKey(r.device))
            .map((RecommendedDeviceResult r) => (product: mappedAmpProduct[r.device]!, quantity: r.quantity))
            .toList();
    final List<({DspProduct product, int quantity})> dsp =
        chosenCombination
            .where((RecommendedDeviceResult r) => mappedDspProduct.containsKey(r.device))
            .map((RecommendedDeviceResult r) => (product: mappedDspProduct[r.device]!, quantity: r.quantity))
            .toList();
    return DeviceSuggestionResult(
      amplifiers: amps,
      dsps: dsp,
    );
  }

  num _calculateCombinationPrice({
    required List<RecommendedDeviceResult> combination,
    required Map<String, AmplifierProduct> mappedAmpProduct,
    required Map<String, DspProduct> mappedDspProduct,
  }) {
    num totalPrice = 0;
    for (final RecommendedDeviceResult result in combination) {
      final String deviceName = result.device;
      final int quantity = result.quantity;

      final AmplifierProduct? ampProduct = mappedAmpProduct[deviceName];
      if (ampProduct != null) {
        totalPrice += productQueryVM.getPrice(ampProduct.productId) * quantity;
        continue;
      }

      final DspProduct? dspProduct = mappedDspProduct[deviceName];
      if (dspProduct != null) {
        totalPrice += productQueryVM.getPrice(dspProduct.productId) * quantity;
        continue;
      }

      print("No product found for device $deviceName to calculate price.");
    }
    return totalPrice;
  }
}

class DeviceSuggestionResult {
  final List<({AmplifierProduct product, int quantity})> amplifiers;
  final List<({DspProduct product, int quantity})> dsps;

  DeviceSuggestionResult({required this.amplifiers, required this.dsps});
}
