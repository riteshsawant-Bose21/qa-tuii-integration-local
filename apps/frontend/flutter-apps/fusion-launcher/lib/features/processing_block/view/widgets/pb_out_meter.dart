import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../../projects/view_model/meter_data/meter_data_view_model.dart';

class PbOutMeter extends StatefulWidget {
  final String blockId;
  final int? dimension;
  final String semanticId;

  const PbOutMeter({
    super.key,
    required this.blockId,
    this.dimension,
    required this.semanticId,
  });

  @override
  State<PbOutMeter> createState() => _PbOutMeterState();
}

class _PbOutMeterState extends State<PbOutMeter> {
  int get dimensionOrDefault => widget.dimension ?? 0;
  double _lastMeterValue = -60.0;
  late final MeterDataViewModel _meterDataViewModel;

  @override
  void initState() {
    super.initState();
    _meterDataViewModel = serviceLocator<MeterDataViewModel>();
    _meterDataViewModel.registerObserver();
  }

  @override
  void dispose() {
    _meterDataViewModel.unregisterObserver();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MeterDataViewModel, MeterDataState, double>(
      bloc: _meterDataViewModel,
      selector: (MeterDataState state) {
        final double? current = state.meterValues?[widget.blockId]?.value[dimensionOrDefault];
        if (current != null) {
          _lastMeterValue = current;
        }
        return _lastMeterValue;
      },
      builder: (BuildContext context, double meterValue) {
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            "PBMeter_${widget.semanticId ?? ''}",
          ),
          value: meterValue.toStringAsFixed(1),
          child: VerticalMeter(
            value: meterValue,
            min: -60,
            max: 0,
          ),
        );
      },
    );
  }
}
