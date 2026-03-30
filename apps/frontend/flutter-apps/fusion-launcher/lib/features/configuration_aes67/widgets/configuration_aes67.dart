import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_aes67/widgets/outputStreams/output_stream_dialog.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../viewModel/config_aes67_viewmodel.dart';
import 'inputStreams/input_stream_dialog.dart';

/// Top-level screen — provides the Cubit
class ConfigurationAes67Screen extends StatelessWidget {
  const ConfigurationAes67Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return BlocProvider<ConfigAes67Viewmodel>(
      create:
          (_) => ConfigAes67Viewmodel(
            projectViewModel: projectViewModel,
          ),
      child: const _ConfigurationAes67View(),
    );
  }
}

class _ConfigurationAes67View extends StatelessWidget {
  const _ConfigurationAes67View();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: context.colorScheme.elevation2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// ── Title bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: FusionAppText(text: 'AES 67', style: Theme.of(context).textTheme.labelMedium),
          ),

          Divider(height: 1, color: context.colorScheme.strokeLight),

          /// ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<ConfigAes67Viewmodel, ConfigAes67State>(
              builder: (BuildContext context, ConfigAes67State state) {
                return switch (state) {
                  ConfigAes67Initial() => const SizedBox.shrink(),
                  ConfigAes67Loading() => const Center(child: CircularProgressIndicator()),
                  ConfigAes67Error(:final String message) => Center(
                    child: FusionAppText(text: 'Error: $message'),
                  ),
                  ConfigAes67Loaded() => _buildLoaded(context, state),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, ConfigAes67Loaded state) {
    final ConfigAes67Viewmodel cubit = context.read<ConfigAes67Viewmodel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Clock Leader + Status row ────────────────────────────────
          Row(
            children: <Widget>[
              FusionAppText(
                text: 'Clock Leader',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FusionAppText(
                  text: state.clockLeader,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              FusionAppText(
                text: 'Status',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              _StatusDot(active: state.globalStatus),
            ],
          ),

          const SizedBox(height: 24),

          // ── Input Streams Section ────────────────────────────────────
          _StreamSection(
            title: 'AES 67 Input Streams',
            addLabel: 'Add Input Stream',
            emptyMessage: 'No input streams configured',
            onAdd:
                (BuildContext context) => InputStreamDialog.show(
                  context,
                  onSave: cubit.addInputStream,
                ),
            onRowTap: (String streamId) {
              final Aes67Config? stream = cubit.getInputStreamById(streamId);
              if (stream != null) {
                InputStreamDialog.show(
                  context,
                  existingStream: stream,
                  isEditing: true,
                  onSave: cubit.updateInputStream,
                );
              }
            },
            columns: _inputColumns(),
            rows: _buildInputRows(context, state.inputStreams, cubit),
          ),

          const SizedBox(height: 24),

          // ── Output Streams Section ───────────────────────────────────
          _StreamSection(
            title: 'AES 67 Output Streams',
            addLabel: 'Add Output Stream',
            emptyMessage: 'No output streams configured',
            onAdd:
                (BuildContext context) => OutputStreamDialog.show(
                  context,
                  onSave: cubit.addOutputStream,
                ),
            onRowTap: (String streamId) {
              final Aes67Config? stream = cubit.getOutputStreamById(streamId);
              if (stream != null) {
                OutputStreamDialog.show(
                  context,
                  existingStream: stream,
                  isEditing: true,
                  onSave: cubit.updateOutputStream,
                );
              }
            },
            columns: _outputColumns(),
            rows: _buildOutputRows(context, state.outputStreams, cubit),
          ),
        ],
      ),
    );
  }

  // ── Column definitions ────────────────────────────────────────────────

  List<FusionTableColumn> _inputColumns() => const <FusionTableColumn>[
    FusionTableColumn(key: 'toggle', header: '', flex: 1, sortable: false),
    FusionTableColumn(key: 'name', header: 'Name', flex: 3),
    FusionTableColumn(key: 'device', header: 'Device', flex: 3),
    FusionTableColumn(key: 'stream', header: 'Stream', flex: 3),
    FusionTableColumn(key: 'address', header: 'Address Port', flex: 3),
    FusionTableColumn(key: 'channels', header: 'Channels', flex: 2, alignment: Alignment.center),
    FusionTableColumn(key: 'bitDepth', header: 'Bit Depth', flex: 2, alignment: Alignment.center),
    FusionTableColumn(key: 'packetTime', header: 'Packet Time', flex: 2, alignment: Alignment.center),
    FusionTableColumn(key: 'status', header: 'Status', flex: 1, sortable: false, alignment: Alignment.center),
  ];

  List<FusionTableColumn> _outputColumns() => const <FusionTableColumn>[
    FusionTableColumn(key: 'toggle', header: '', flex: 1, sortable: false),
    FusionTableColumn(key: 'name', header: 'Name', flex: 3),
    FusionTableColumn(key: 'device', header: 'Device', flex: 3),
    FusionTableColumn(key: 'advertisement', header: 'Advertisment', flex: 3),
    FusionTableColumn(key: 'address', header: 'Address Port', flex: 3),
    FusionTableColumn(key: 'channels', header: 'Channels', flex: 2, alignment: Alignment.center),
    FusionTableColumn(key: 'bitDepth', header: 'Bit Depth', flex: 2, alignment: Alignment.center),
    FusionTableColumn(key: 'packetTime', header: 'Packet Time', flex: 2, alignment: Alignment.center),
    FusionTableColumn(key: 'status', header: 'Status', flex: 1, sortable: false, alignment: Alignment.center),
  ];

  // ── Row builders ────────────────────────────────────────────────────

  List<FusionTableRow> _buildInputRows(
    BuildContext context,
    List<Aes67Config> streams,
    ConfigAes67Viewmodel cubit,
  ) {
    return streams
        .map(
          (Aes67Config s) => FusionTableRow(
            key: s.id,
            cells: <String, FusionTableCell>{
              'toggle': FusionTableCell(
                value: s.isEnabled,
                child: _StreamToggle(
                  value: s.isEnabled,
                  onChanged: (_) => cubit.toggleInputStreamEnabled(s.id),
                ),
              ),
              'name': FusionTableCell(
                value: s.name,
                child: _CellText(text: s.name, bold: true, context: context),
              ),
              'device': FusionTableCell(
                value: s.device,
                child: _CellText(text: s.device, context: context),
              ),
              'stream': FusionTableCell(
                value: s.streamOrAdvertisement,
                child: _CellText(text: s.streamOrAdvertisement, context: context),
              ),
              'address': FusionTableCell(
                value: '${s.ipAddress}:${s.port}',
                child: _CellText(text: '${s.ipAddress}:${s.port}', context: context),
              ),
              'channels': FusionTableCell(
                value: s.channels,
                child: _CellText(text: s.channels.toString(), context: context),
              ),
              'bitDepth': FusionTableCell(
                value: s.bitDepth,
                child: _CellText(text: s.bitDepth, context: context),
              ),
              'packetTime': FusionTableCell(
                value: s.packetTime,
                child: _CellText(text: s.packetTime, context: context),
              ),
              'status': FusionTableCell(
                value: s.isEnabled,
                child: _StatusDot(active: s.isEnabled),
              ),
            },
          ),
        )
        .toList();
  }

  List<FusionTableRow> _buildOutputRows(
    BuildContext context,
    List<Aes67Config> streams,
    ConfigAes67Viewmodel cubit,
  ) {
    return streams
        .map(
          (Aes67Config s) => FusionTableRow(
            key: s.id,
            cells: <String, FusionTableCell>{
              'toggle': FusionTableCell(
                value: s.isEnabled,
                child: _StreamToggle(
                  value: s.isEnabled,
                  onChanged: (_) => cubit.toggleOutputStreamEnabled(s.id),
                ),
              ),
              'name': FusionTableCell(
                value: s.name,
                child: _CellText(text: s.name, bold: true, context: context),
              ),
              'device': FusionTableCell(
                value: s.device,
                child: _CellText(text: s.device, context: context),
              ),
              'advertisement': FusionTableCell(
                value: s.streamOrAdvertisement,
                child: _CellText(text: s.streamOrAdvertisement, context: context),
              ),
              'address': FusionTableCell(
                value: '${s.ipAddress}:${s.port}',
                child: _CellText(text: '${s.ipAddress}:${s.port}', context: context),
              ),
              'channels': FusionTableCell(
                value: s.channels,
                child: _CellText(text: s.channels.toString(), context: context),
              ),
              'bitDepth': FusionTableCell(
                value: s.bitDepth,
                child: _CellText(text: s.bitDepth, context: context),
              ),
              'packetTime': FusionTableCell(
                value: s.packetTime,
                child: _CellText(text: s.packetTime, context: context),
              ),
              'status': FusionTableCell(
                value: s.isEnabled,
                child: _StatusDot(active: s.isEnabled),
              ),
            },
          ),
        )
        .toList();
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────────────────

/// Section card: title bar + FusionTable
class _StreamSection extends StatelessWidget {
  final String title;
  final String addLabel;
  final List<FusionTableColumn> columns;
  final List<FusionTableRow> rows;
  final void Function(BuildContext context) onAdd;
  final void Function(String rowKey)? onRowTap;
  final String emptyMessage;

  const _StreamSection({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.columns,
    required this.rows,
    required this.emptyMessage,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed row height * count + header + bottom padding
    const double headerHeight = 44;
    const double rowHeight = 48;
    final double tableHeight = // half of the screen or enough to show all rows, whichever is smaller;
        (rows.length * rowHeight + headerHeight + 16).clamp(0, MediaQuery.sizeOf(context).height * 0.5);

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorScheme.elevation2),
      ),
      child: Column(
        children: <Widget>[
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FusionAppText(
                  text: title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => onAdd(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.add, size: 14, color: context.colorScheme.iconWhite),
                        const SizedBox(width: 4),
                        FusionAppText(
                          text: addLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show empty state or table
          if (rows.isEmpty)
            Container(
              color: context.colorScheme.elevation1,
              padding: const EdgeInsets.symmetric(vertical: 48),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FusionAppText(
                    text: emptyMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => onAdd(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.add, size: 16, color: context.colorScheme.primaryColor),
                          const SizedBox(width: 4),
                          FusionAppText(
                            text: addLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.colorScheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // FusionTable with fixed height so it doesn't need Expanded inside scroll
            Container(
              color: context.colorScheme.elevation1,
              height: tableHeight,
              child: FusionTable(
                columns: columns,
                rows: rows,
                onRowTap: onRowTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Toggle switch styled to match the green pill in the screenshot
class _StreamToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StreamToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.75,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: context.colorScheme.primaryColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: context.colorScheme.strokeLight,
      ),
    );
  }
}

/// Small filled circle indicating active/inactive status
class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? context.colorScheme.primaryColor : context.colorScheme.textSecondary,
      ),
    );
  }
}

/// Standard table cell text
class _CellText extends StatelessWidget {
  final String text;
  final bool bold;
  final BuildContext context;

  const _CellText({
    required this.text,
    required this.context,
    this.bold = false,
  });

  @override
  Widget build(BuildContext _) {
    final String displayText = text.isEmpty ? '-' : text;
    return FusionAppText(
      text: displayText,
      maxLine: 1,
      textOverflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: bold ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
      ),
    );
  }
}
