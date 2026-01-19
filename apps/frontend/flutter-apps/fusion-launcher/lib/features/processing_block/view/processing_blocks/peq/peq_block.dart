import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';

import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../../widgets/pb_dropdown.dart';
import '../../widgets/pb_textfield.dart';
import '../widgets/block_header.dart';

part '_peq_band_section.dart';
part '_peq_controller.dart';
part '_peq_graph.dart';

class PeqBlock extends StatelessWidget {
  const PeqBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return ProxyProvider<AlgorithmDataViewmodel, PEQController>(
      create: (BuildContext context) => PEQController(context.read<AlgorithmDataViewmodel>()),
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, PEQController? previous) => PEQController(valueHandler),
      child: Column(
        spacing: 10,
        children: <Widget>[
          BlockHeader(
            pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
          ),
          const Expanded(
            child: Row(
              spacing: 4,
              children: <Widget>[
                Expanded(child: PeqGraph()),
                SizedBox(width: 600, child: _PeqBandSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
