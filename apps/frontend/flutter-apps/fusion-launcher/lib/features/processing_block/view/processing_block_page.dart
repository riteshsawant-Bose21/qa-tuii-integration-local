import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../viewmodel/algorithm_data_viewmodel.dart';
import 'dynamic_grid_view.dart';

class ProcessingBlockPage extends StatelessWidget {
  const ProcessingBlockPage({super.key, required this.processingBlock});
  final ProcessingBlockModel processingBlock;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlgorithmDataViewmodel>(
      key: ValueKey<String>(processingBlock.id),
      create: (BuildContext context) => AlgorithmDataViewmodel(processingBlock: processingBlock, config: serviceLocator.get<FusionAlgorithmsConfig>()),

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
              final ScrollController scrollController = viewModel.scrollController;
              return Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DynamicGridView(
                    layout: data,
                    scrollController: scrollController,
                    handler: viewModel,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
