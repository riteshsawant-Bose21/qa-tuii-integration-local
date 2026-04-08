import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/projects/models/device_system_info.dart';
import 'package:fusion_launcher/features/projects/view_model/meter_data/meter_data_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared lightweight BlocBuilder wrappers for live device telemetry.
//
// Only the tiny metric/status widgets rebuild — the surrounding card / table
// structure stays completely untouched on every ZMQ packet.
// ─────────────────────────────────────────────────────────────────────────────

/// Callback used by [LiveDeviceMetric].
typedef LiveDeviceWidgetBuilder =
    Widget Function(
      DeviceSystemInfo? info,
      bool isOnline,
    );

/// Wraps a single metric widget (temperature, disk, CPU, status dot in tables)
/// with a [BlocBuilder] scoped to [MeterDataState.deviceSystemInfo] changes.
class LiveDeviceMetric extends StatelessWidget {
  final String deviceId;
  final LiveDeviceWidgetBuilder builder;

  const LiveDeviceMetric({
    super.key,
    required this.deviceId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeterDataViewModel, MeterDataState>(
      bloc: serviceLocator<MeterDataViewModel>(),
      buildWhen: (MeterDataState prev, MeterDataState curr) => prev.isConnected != curr.isConnected || prev.deviceSystemInfo != curr.deviceSystemInfo,
      builder: (BuildContext context, MeterDataState state) {
        final DeviceSystemInfo? info = state.systemInfoFor(deviceId);
        final bool isOnline = state.isConnected && info != null && info.hasData;
        return builder(info, isOnline);
      },
    );
  }
}

/// Status dot that marks a device offline only after [offlineThreshold]
/// of continuous silence (no system-monitor data).
///
/// Combines [BlocBuilder] (reacts instantly when new data arrives) with a
/// periodic [Timer] (detects staleness when no new data triggers a rebuild).
class LiveStatusDot extends StatefulWidget {
  final String deviceId;
  final double size;
  final Duration offlineThreshold;
  final Color? onlineColor;
  final Color? offlineColor;

  const LiveStatusDot({
    super.key,
    required this.deviceId,
    this.size = 6,
    this.offlineThreshold = const Duration(seconds: 10),
    this.onlineColor,
    this.offlineColor,
  });

  @override
  State<LiveStatusDot> createState() => _LiveStatusDotState();
}

class _LiveStatusDotState extends State<LiveStatusDot> {
  static const Duration _checkInterval = Duration(seconds: 3);

  Timer? _staleCheckTimer;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _staleCheckTimer = Timer.periodic(_checkInterval, (_) => _evaluateOnlineStatus());
  }

  @override
  void dispose() {
    _staleCheckTimer?.cancel();
    super.dispose();
  }

  void _evaluateOnlineStatus() {
    final MeterDataState state = serviceLocator<MeterDataViewModel>().state;
    final bool newOnline = _computeOnline(state);
    if (newOnline != _isOnline && mounted) {
      setState(() => _isOnline = newOnline);
    }
  }

  bool _computeOnline(MeterDataState state) {
    if (!state.isConnected) return false;
    final DeviceSystemInfo? info = state.systemInfoFor(widget.deviceId);
    if (info == null || !info.hasData) return false;
    return DateTime.now().difference(info.updatedAt) < widget.offlineThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeterDataViewModel, MeterDataState>(
      bloc: serviceLocator<MeterDataViewModel>(),
      buildWhen: (MeterDataState prev, MeterDataState curr) => prev.isConnected != curr.isConnected || prev.deviceSystemInfo != curr.deviceSystemInfo,
      builder: (BuildContext context, MeterDataState state) {
        _isOnline = _computeOnline(state);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isOnline ? (widget.onlineColor ?? context.colorScheme.green) : (widget.offlineColor ?? context.colorScheme.error),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Dash placeholder for unavailable metrics.
Widget buildDash({Color? color}) => Align(
  alignment: Alignment.centerLeft,
  child: Text("-", style: TextStyle(color: color ?? Colors.grey)),
);
