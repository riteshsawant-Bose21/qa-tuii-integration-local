import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/algorithm_customization_vm.dart';
import 'package:provider/provider.dart';

class AlgorithmSelectionWrapper extends StatelessWidget {
  const AlgorithmSelectionWrapper({
    super.key,
    required this.builder,
    this.viewModel,
  });

  final Widget Function(BuildContext context, Algorithm algorithm) builder;
  final AlgorithmCustomizationVm? viewModel;

  @override
  Widget build(BuildContext context) {
    // If viewModel is provided, use it directly, otherwise create a new one
    if (viewModel != null) {
      return ChangeNotifierProvider<AlgorithmCustomizationVm>.value(
        value: viewModel!,
        child: Builder(
          builder: _buildContent,
        ),
      );
    }

    return ChangeNotifierProvider<AlgorithmCustomizationVm>(
      create: (BuildContext context) => AlgorithmCustomizationVm(config: serviceLocator.get<FusionAlgorithmsConfig>()),
      child: Builder(
        builder: _buildContent,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final AlgorithmCustomizationVm viewModel = context.watch<AlgorithmCustomizationVm>();
    final List<Algorithm> algorithm = viewModel.availableAlgorithms;
    final Algorithm? selectedAlgo = viewModel.selectedAlgorithm;

    if (algorithm.isNotEmpty && selectedAlgo != null) {
      return Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  algorithm.map((Algorithm algo) {
                    final bool isSelected = algo == selectedAlgo;
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.black : Colors.grey,
                        ),
                        onPressed: () {
                          viewModel.selectAlgorithm(algo);
                        },
                        child: Text(algo.name),
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(child: builder(context, selectedAlgo)),
        ],
      );
    }

    return GridView.builder(
      itemCount: algorithm.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (BuildContext context, int index) {
        final Algorithm algo = algorithm[index];
        return GestureDetector(
          onTap: () {
            viewModel.selectAlgorithm(algo);
          },
          child: Card(
            child: Center(
              child: Text(algo.name),
            ),
          ),
        );
      },
    );
  }
}
