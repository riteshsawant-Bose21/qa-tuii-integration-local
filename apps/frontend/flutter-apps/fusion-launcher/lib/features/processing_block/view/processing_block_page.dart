import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';
import 'package:provider/provider.dart';

import '../viewmodel/algorithm_data_viewmodel.dart';
import 'dynamic_grid_view.dart';

class ProcessingBlockPage extends StatelessWidget {
  const ProcessingBlockPage({super.key, required this.algorithm});
  final String algorithm;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlgorithmDataViewmodel>(
      key: ValueKey<String>(algorithm),
      create: (BuildContext context) => AlgorithmDataViewmodel(algorithmId: algorithm, config: serviceLocator.get<FusionAlgorithmsConfig>()),

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<AlgorithmDataViewmodel>(
          builder: (BuildContext context, AlgorithmDataViewmodel viewModel, Widget? child) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final PBLayout? data = viewModel.layout;
                if (data == null) {
                  return const Center(
                    child: Text(""),
                  );
                }
                // return Text("${constraints.maxWidth} x ${constraints.maxHeight}");
                return DynamicGridView(
                  layout: data,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
