import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';

import '../../../projects/view_model/meter_data/meter_data_view_model.dart';

class PbOutMeter extends StatefulWidget {
  final String blockId;
  final int? dimension;

  const PbOutMeter({
    super.key,
    required this.blockId,
    this.dimension,
  });

  @override
  State<PbOutMeter> createState() => _PbOutMeterState();
}

class _PbOutMeterState extends State<PbOutMeter> {
  int get dimensionOrDefault => widget.dimension ?? 0;
  double _lastMeterValue = -60.0;

  @override
  void initState() {
    super.initState();
    serviceLocator<MeterDataViewModel>().registerObserver();
  }

  @override
  void dispose() {
    serviceLocator<MeterDataViewModel>().unregisterObserver();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MeterDataViewModel, MeterDataState, double>(
      selector: (MeterDataState state) {
        final double? current = state.meterValues?[widget.blockId]?.value[dimensionOrDefault];
        if (current != null) {
          _lastMeterValue = current;
        }
        return _lastMeterValue;
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
