import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class MeterBlock {
  final String blockName;
  final String meterName;
  final String valueType;
  final List<int> dimensions;
  final List<double> value;

  const MeterBlock({
    required this.blockName,
    required this.meterName,
    required this.valueType,
    required this.dimensions,
    required this.value,
  });

  static List<double> _parseDynamicList(dynamic value) {
    if (value == null) return <double>[];

    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        try {
          final dynamic parsed = jsonDecode(value);
          if (parsed is List) return _parseDynamicList(parsed);
        } catch (_) {}
      }
      final double? parsedNum = double.tryParse(value);
      if (parsedNum != null) return <double>[parsedNum];
      return <double>[];
    }

    if (value is List) {
      return value.map((dynamic e) {
        if (e is num) return e.toDouble();
        if (e is bool) return e ? 1.0 : 0.0;
        if (e is String) return double.tryParse(e) ?? 0.0;
        return 0.0;
      }).toList();
    } else if (value is num) {
      return <double>[value.toDouble()];
    } else if (value is bool) {
      return <double>[value ? 1.0 : 0.0];
    }

    return <double>[];
  }

  static List<int> _parseDimensions(dynamic value) {
    if (value == null) return <int>[];

    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        try {
          final dynamic parsed = jsonDecode(value);
          if (parsed is List) return _parseDimensions(parsed);
        } catch (_) {}
      }
      final int? parsedNum = int.tryParse(value);
      if (parsedNum != null) return <int>[parsedNum];
      return <int>[];
    }

    if (value is List) {
      return value.map((dynamic e) {
        if (e is num) return e.toInt();
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    } else if (value is num) {
      return <int>[value.toInt()];
    }

    return <int>[];
  }

  factory MeterBlock.fromMap(Map<String, dynamic> map) {
    return MeterBlock(
      blockName: map['block_name']?.toString() ?? '',
      meterName: map['meter_name']?.toString() ?? '',
      valueType: map['value_type']?.toString() ?? '',
      dimensions: _parseDimensions(map['dimensions']),
      value: _parseDynamicList(map['value']),
    );
  }

  /// Display label: block name stripped of trailing numeric ID suffix
  String get displayName {
    // e.g. "GAIN1772532371599915492" → "GAIN"
    final RegExpMatch? match = RegExp(r'^([A-Za-z_]+)').firstMatch(blockName);
    return match?.group(1) ?? blockName;
  }

  /// Compact value string, rounded to 1 decimal
  String get valueLabel {
    if (value.length == 1) {
      return '${value[0].toStringAsFixed(1)} dB';
    }
    return '${value.map((double v) => v.toStringAsFixed(1)).join(' / ')} dB';
  }

  /// Colour-code by signal level
  Color get levelColor {
    final double peak = value.reduce((double a, double b) => a > b ? a : b);
    if (peak <= -100) return const Color(0xFF4A5568); // silent / no signal
    if (peak <= -60) return const Color(0xFF48BB78); // nominal green
    if (peak <= -20) return const Color(0xFFECC94B); // warning yellow
    return const Color(0xFFFC8181); // hot / red
  }
}

class MeterPacket {
  final String name;
  final String type;
  final int length;
  final List<MeterBlock> blocks;

  const MeterPacket({
    required this.name,
    required this.type,
    required this.length,
    required this.blocks,
  });

  factory MeterPacket.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? params = map['parameters'] as Map<String, dynamic>?;
    if (params == null) {
      return const MeterPacket(name: '', type: '', length: 0, blocks: <MeterBlock>[]);
    }

    return MeterPacket(
      name: params['name']?.toString() ?? '',
      type: params['type']?.toString() ?? '',
      length: (params['length'] is num) ? (params['length'] as num).toInt() : int.tryParse(params['length']?.toString() ?? '') ?? 0,
      blocks: _parseBlocks(params['value']),
    );
  }

  static List<MeterBlock> _parseBlocks(dynamic value) {
    if (value == null) return <MeterBlock>[];

    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        try {
          final dynamic parsed = jsonDecode(value);
          if (parsed is List) return _parseBlocks(parsed);
        } catch (_) {}
      }
      return <MeterBlock>[];
    }

    if (value is List) {
      return value
          .map((dynamic e) {
            if (e is Map<String, dynamic>) {
              return MeterBlock.fromMap(e);
            }
            if (e is String) {
              try {
                final dynamic mapped = jsonDecode(e);
                if (mapped is Map<String, dynamic>) {
                  return MeterBlock.fromMap(mapped);
                }
              } catch (_) {}
            }
            return null;
          })
          .whereType<MeterBlock>()
          .toList();
    }
    return <MeterBlock>[];
  }
}

// ─────────────────────────────────────────────
// CUBIT
// ─────────────────────────────────────────────

class MeterDataState {
  final Map<String, MeterPacket> packets;
  final bool hasData;

  const MeterDataState({this.packets = const <String, MeterPacket>{}, this.hasData = false});

  MeterDataState copyWith({Map<String, MeterPacket>? packets}) => MeterDataState(
    packets: packets ?? this.packets,
    hasData: true,
  );
}

class MeterDataCubit extends Cubit<MeterDataState> {
  MeterDataCubit() : super(const MeterDataState());

  StreamSubscription<ResponseCallback<dynamic>>? _telemetrySubscription;

  @override
  Future<void> close() {
    disposeTelemetry();
    return super.close();
  }

  Future<void> initializeTelemetryData() async {
    final FusionNetworkClient client = serviceLocator<FusionNetworkClient>();
    final String vip = serviceLocator<ProjectViewModel>().virtualIP ?? "";
    await client.connect(vip: vip);
    //stream telemetry data for testing
    _telemetrySubscription = client.responseMessages.listen(
      (ResponseCallback<dynamic> message) {
        debugPrint("######### Received telemetry message ############: ${message.data}");
        try {
          final MeterPacket packet = MeterPacket.fromMap(message.data);
          final Map<String, MeterPacket> newPackets = Map<String, MeterPacket>.from(state.packets);
          newPackets[packet.name] = packet;
          emit(state.copyWith(packets: newPackets));
        } catch (e) {
          debugPrint("######### Error parsing telemetry message ############: $e");
        }
      },
      onError: (dynamic error) {
        debugPrint("######### Telemetry error ############: $error");
      },
      onDone: () {
        debugPrint("######### Telemetry stream closed ############");
      },
    );
  }

  void disposeTelemetry() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
  }
}

// ─────────────────────────────────────────────
// POPUP WIDGET
// ─────────────────────────────────────────────

/// Show the popup over any existing UI.
///
/// Usage:
///   showMeterDataPopup(context, cubit: context.read<MeterDataCubit>());
Future<void> showMeterDataPopup(
  BuildContext context,
) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder:
        (_) => BlocProvider<MeterDataCubit>.value(
          value: MeterDataCubit()..initializeTelemetryData(),
          child: const _MeterDataDialog(),
        ),
  );
}

class _MeterDataDialog extends StatelessWidget {
  const _MeterDataDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: BlocBuilder<MeterDataCubit, MeterDataState>(
        builder: (BuildContext context, MeterDataState state) {
          return _DialogShell(state: state);
        },
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  final MeterDataState state;
  const _DialogShell({required this.state});

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height * 0.85;
    return Container(
      width: 1000,
      height: h > 720 ? 720 : h,
      constraints: const BoxConstraints(maxWidth: 1000),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3748), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFF2D3748), width: 1)),
              ),
              child: _PacketView(
                packet: state.packets['fusion_dsp'],
                expectedName: 'fusion_dsp',
                showClose: false,
              ),
            ),
          ),
          Expanded(
            child: _PacketView(
              packet: state.packets['fusion_system_monitor'],
              expectedName: 'fusion_system_monitor',
              showClose: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PacketView extends StatelessWidget {
  final MeterPacket? packet;
  final String expectedName;
  final bool showClose;

  const _PacketView({
    this.packet,
    required this.expectedName,
    required this.showClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _Header(packet: packet, expectedName: expectedName, showClose: showClose),
        const Divider(color: Color(0xFF2D3748), height: 1),
        if (packet == null || packet!.blocks.isEmpty) const Expanded(child: _EmptyState()) else Expanded(child: _BlockList(blocks: packet!.blocks)),
        const Divider(color: Color(0xFF2D3748), height: 1),
        _Footer(packet: packet, expectedName: expectedName),
      ],
    );
  }
}

// ── Header ──────────────────────────────────

class _Header extends StatelessWidget {
  final MeterPacket? packet;
  final String expectedName;
  final bool showClose;

  const _Header({
    this.packet,
    required this.expectedName,
    required this.showClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: packet != null ? const Color(0xFF48BB78) : const Color(0xFF718096),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            (packet?.name ?? expectedName).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE2E8F0),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          if (packet != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A202C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF4A5568)),
              ),
              child: Text(
                packet!.type,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF90CDF4),
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ),
          const Spacer(),
          if (showClose)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF718096)),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 18,
            )
          else
            const SizedBox(width: 36, height: 36),
        ],
      ),
    );
  }
}

// ── Block list ───────────────────────────────

class _BlockList extends StatelessWidget {
  final List<MeterBlock> blocks;
  const _BlockList({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: blocks.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF1A202C), height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, int i) => _BlockTile(block: blocks[i]),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final MeterBlock block;
  const _BlockTile({required this.block});

  @override
  Widget build(BuildContext context) {
    final bool isSilent = block.value.every((double v) => v <= -100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          // Level indicator dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: block.levelColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Block / meter name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  block.blockName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF718096),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Text(
                      block.meterName,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFFCBD5E0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (block.dimensions.first > 1) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3748),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${block.dimensions.first}ch',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF90CDF4),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Value badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: block.levelColor.withOpacity(isSilent ? 0.08 : 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: block.levelColor.withOpacity(isSilent ? 0.2 : 0.4),
              ),
            ),
            child: Text(
              block.valueLabel,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: block.levelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cable_outlined, size: 36, color: Color(0xFF4A5568)),
            SizedBox(height: 12),
            Text(
              'Waiting for ZMQ data…',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF718096),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ───────────────────────────────────

class _Footer extends StatelessWidget {
  final MeterPacket? packet;
  final String expectedName;

  const _Footer({this.packet, required this.expectedName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: <Widget>[
          Text(
            packet != null ? '${packet!.blocks.length} blocks · length ${packet!.length}' : 'No packet',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4A5568),
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            expectedName,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4A5568),
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
