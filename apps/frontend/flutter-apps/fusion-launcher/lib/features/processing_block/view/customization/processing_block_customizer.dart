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

import '../../viewmodel/algorithm_customization_vm.dart';
import '../../viewmodel/pbc_viewmodel.dart';
import '../algorithm_selection_wrapper.dart';
import '../item_widget_builder.dart';

part 'widgets/active_control.dart';
part 'widgets/bg_grid.dart';
part 'widgets/fields_list.dart';
part 'widgets/pb_canvas_view.dart';
part 'widgets/properties_panel.dart';

class ProcessingBlockCustomizer extends StatelessWidget {
  const ProcessingBlockCustomizer({super.key});

  @override
  Widget build(BuildContext context) {
    return AlgorithmSelectionWrapper(
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
