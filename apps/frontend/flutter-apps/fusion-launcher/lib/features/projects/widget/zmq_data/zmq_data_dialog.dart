import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/meter_data.dart';
import '../../view_model/meter_data/meter_data_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POPUP  —  now just reads the global cubit, never creates its own
// ─────────────────────────────────────────────────────────────────────────────

/// Show the meter-data overlay.
/// The global [MeterDataViewModel] singleton must already be provided above
/// [MaterialApp] in the widget tree.
Future<void> showMeterDataPopup(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _MeterDataDialog(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS  (layout unchanged, only wiring updated)
// ─────────────────────────────────────────────────────────────────────────────

class _MeterDataDialog extends StatelessWidget {
  const _MeterDataDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: BlocBuilder<MeterDataViewModel, MeterDataState>(
        builder: (BuildContext context, MeterDataState state) => _DialogShell(state: state),
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
        border: Border.all(color: const Color(0xFF2D3748)),
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
                border: Border(right: BorderSide(color: Color(0xFF2D3748))),
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

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final MeterPacket? packet;
  final String expectedName;
  final bool showClose;

  const _Header({this.packet, required this.expectedName, required this.showClose});

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

// ── Block list ────────────────────────────────────────────────────────────────

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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: block.levelColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  block.blockName,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF718096)),
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
                    if (block.dimensions.isNotEmpty && block.dimensions.first > 1) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3748),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${block.dimensions.first}ch',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF90CDF4), fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: block.levelColor.withOpacity(isSilent ? 0.08 : 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: block.levelColor.withOpacity(isSilent ? 0.2 : 0.4)),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // Show a context-aware message depending on why there is no data.
    final MeterInactiveReason? reason = context.select<MeterDataViewModel, MeterInactiveReason?>((MeterDataViewModel c) => c.state.inactiveReason);

    final String message = switch (reason) {
      MeterInactiveReason.controlModeOff => 'Enable Control Mode to receive data.',
      MeterInactiveReason.projectClosed => 'No active project.',
      _ => 'Waiting for ZMQ data…',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cable_outlined, size: 36, color: Color(0xFF4A5568)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF718096), fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

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
            style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568), fontFamily: 'monospace'),
          ),
          const Spacer(),
          Text(
            expectedName,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568), fontFamily: 'monospace', letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
