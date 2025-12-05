import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/features/processing_block/datasource/pb_widgets.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';

import '../../../../core/service_locator.dart';
import '../../viewmodel/algorithm_customization_vm.dart';
import '../../viewmodel/pbc_viewmodel.dart';
import '../algorithm_selection_wrapper.dart';
import '../item_widget_builder.dart';

part 'widgets/active_control.dart';
part 'widgets/bg_grid.dart';
part 'widgets/fields_list.dart';
part 'widgets/pb_canvas_view.dart';
part 'widgets/properties_panel.dart';

class ProcessingBlockCustomizer extends StatefulWidget {
  // selected algorithm
  final String? selectedAlgorithmId;
  const ProcessingBlockCustomizer({super.key, this.selectedAlgorithmId});

  @override
  State<ProcessingBlockCustomizer> createState() => _ProcessingBlockCustomizerState();
}

class _ProcessingBlockCustomizerState extends State<ProcessingBlockCustomizer> {
  late AlgorithmCustomizationVm _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AlgorithmCustomizationVm(
      config: serviceLocator.get<FusionAlgorithmsConfig>(),
    );

    // Set the selected algorithm if provided
    if (widget.selectedAlgorithmId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final Algorithm? selectedAlgorithm = _viewModel.availableAlgorithms.cast<Algorithm?>().firstWhere(
          (Algorithm? algo) => algo?.name == widget.selectedAlgorithmId,
          orElse: () => null,
        );

        if (selectedAlgorithm != null) {
          _viewModel.selectAlgorithm(selectedAlgorithm);
        }
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmSelectionWrapper(
      viewModel: _viewModel,
      builder: (BuildContext context, Algorithm algorithm) {
        return ChangeNotifierProxyProvider<AlgorithmCustomizationVm, PbcViewmodel>(
          create: (BuildContext context) => PbcViewmodel(algorithm: algorithm),
          update: (BuildContext context, AlgorithmCustomizationVm a, PbcViewmodel? b) => b!.algorithm != algorithm ? PbcViewmodel(algorithm: algorithm) : b,
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade400)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(
                  child: _PBCItemList(),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: _CanvasView(),
                    ),
                  ),
                ),
                Expanded(child: _PropertiesPanel()),
              ],
            ),
          ),
        );
      },
    );
  }
}
