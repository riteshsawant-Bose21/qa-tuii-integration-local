import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../../core/service_locator.dart';
import '../../../../../projects/view_model/meter_data/meter_data_view_model.dart';

class StatusIndicator extends StatefulWidget {
  final String label;
  final String blockId;

  /// Duration of silence after which the indicator is considered inactive.
  final Duration inactiveThreshold;

  const StatusIndicator({
    required this.label,
    super.key,
    required this.blockId,
    this.inactiveThreshold = const Duration(seconds: 2),
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  static const Duration _checkInterval = Duration(seconds: 1);
  static const double _silenceThreshold = -60.0;

  late final MeterDataViewModel _meterDataViewModel;
  Timer? _staleCheckTimer;
  DateTime? _lastReceivedAt;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _meterDataViewModel = serviceLocator<MeterDataViewModel>();
    _meterDataViewModel.registerObserver();
    _staleCheckTimer = Timer.periodic(_checkInterval, (_) => _evaluateActive());
  }

  @override
  void dispose() {
    _staleCheckTimer?.cancel();
    _meterDataViewModel.unregisterObserver();
    super.dispose();
  }

  /// Called periodically to flip the indicator to inactive when data stops.
  void _evaluateActive() {
    final bool newActive = _lastReceivedAt != null && DateTime.now().difference(_lastReceivedAt!) < widget.inactiveThreshold;
    if (newActive != _isActive && mounted) {
      setState(() => _isActive = newActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MeterDataViewModel, MeterDataState, double?>(
      bloc: _meterDataViewModel,
      selector: (MeterDataState state) {
        return state.meterValues?[widget.blockId]?.value[0];
      },
      builder: (BuildContext context, double? meterValue) {
        // Values at or below the silence threshold are treated as no signal.
        if (meterValue != null && meterValue > _silenceThreshold) {
          _lastReceivedAt = DateTime.now();
          _isActive = true;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isActive ? context.colorScheme.green : context.colorScheme.textGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            FusionAppText(
              text: widget.label,
              style: context.textTheme.labelMedium!.copyWith(
                color: _isActive ? context.colorScheme.textPrimary : context.colorScheme.textGrey,
              ),
            ),
          ],
        );
      },
    );
  }
}
