import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';

import '../../../projects/view_model/meter_data/meter_data_view_model.dart';

class PbOutMeter extends StatelessWidget {
  final String blockId;
  final int? dimension;

  const PbOutMeter({
    super.key,
    required this.blockId,
    this.dimension,
  });

  int get dimensionOrDefault => dimension ?? 0;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MeterDataViewModel, MeterDataState, double>(
      selector: (MeterDataState state) {
        // Fast dictionary lookup. Defaults to -60.0 if not found.
        return state.meterValues?[blockId]?.value[dimensionOrDefault] ?? -60.0;
      },
      builder: (BuildContext context, double meterValue) {
        return VerticalMeter(
          value: meterValue,
          min: -60,
          max: 0,
        );
      },
    );
  }
}
