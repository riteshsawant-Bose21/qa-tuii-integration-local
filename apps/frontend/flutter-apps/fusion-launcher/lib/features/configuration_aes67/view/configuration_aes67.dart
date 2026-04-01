import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_aes67/view/widgets/outputStreams/output_stream_dialog.dart';
import 'package:fusion_launcher/features/configuration_aes67/view/widgets/status_dot.dart';
import 'package:fusion_launcher/features/configuration_aes67/view/widgets/stream_section.dart';
import 'package:fusion_launcher/features/configuration_aes67/view/widgets/stream_toggle.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../viewModel/config_aes67_viewmodel.dart';
import 'widgets/cell_text.dart';
import 'widgets/delete_button.dart';
import 'widgets/inputStreams/input_stream_dialog.dart';

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

    return Padding(
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
              StatusDot(active: state.globalStatus),
            ],
          ),

          const SizedBox(height: 24),

          // ── Input Streams Section ────────────────────────────────────
          Expanded(
            child: StreamSection(
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
          ),

          const SizedBox(height: 24),

          // ── Output Streams Section ───────────────────────────────────
          Expanded(
            child: StreamSection(
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
    FusionTableColumn(key: 'delete', header: '', flex: 1, sortable: false, alignment: Alignment.center),
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
    FusionTableColumn(key: 'delete', header: '', flex: 1, sortable: false, alignment: Alignment.center),
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
                child: StreamToggle(
                  value: s.isEnabled,
                  onChanged: (_) => cubit.toggleInputStreamEnabled(s.id),
                ),
              ),
              'name': FusionTableCell(
                value: s.name,
                child: CellText(text: s.name, bold: true, context: context),
              ),
              'device': FusionTableCell(
                value: s.device,
                child: CellText(text: s.device, context: context),
              ),
              'stream': FusionTableCell(
                value: s.streamOrAdvertisement,
                child: CellText(text: s.streamOrAdvertisement, context: context),
              ),
              'address': FusionTableCell(
                value: '${s.ipAddress}:${s.port}',
                child: CellText(text: '${s.ipAddress}:${s.port}', context: context),
              ),
              'channels': FusionTableCell(
                value: s.channels,
                child: CellText(text: s.channels.toString(), context: context),
              ),
              'bitDepth': FusionTableCell(
                value: s.bitDepth,
                child: CellText(text: s.bitDepth, context: context),
              ),
              'packetTime': FusionTableCell(
                value: s.packetTime,
                child: CellText(text: s.packetTime, context: context),
              ),
              'status': FusionTableCell(
                value: s.isEnabled,
                child: StatusDot(active: s.isEnabled),
              ),
              'delete': FusionTableCell(
                value: null,
                child: DeleteButton(
                  onDelete: () => cubit.deleteInputStream(s.id),
                ),
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
                child: StreamToggle(
                  value: s.isEnabled,
                  onChanged: (_) => cubit.toggleOutputStreamEnabled(s.id),
                ),
              ),
              'name': FusionTableCell(
                value: s.name,
                child: CellText(text: s.name, bold: true, context: context),
              ),
              'device': FusionTableCell(
                value: s.device,
                child: CellText(text: s.device, context: context),
              ),
              'advertisement': FusionTableCell(
                value: s.streamOrAdvertisement,
                child: CellText(text: s.streamOrAdvertisement, context: context),
              ),
              'address': FusionTableCell(
                value: '${s.ipAddress}:${s.port}',
                child: CellText(text: '${s.ipAddress}:${s.port}', context: context),
              ),
              'channels': FusionTableCell(
                value: s.channels,
                child: CellText(text: s.channels.toString(), context: context),
              ),
              'bitDepth': FusionTableCell(
                value: s.bitDepth,
                child: CellText(text: s.bitDepth, context: context),
              ),
              'packetTime': FusionTableCell(
                value: s.packetTime,
                child: CellText(text: s.packetTime, context: context),
              ),
              'status': FusionTableCell(
                value: s.isEnabled,
                child: StatusDot(active: s.isEnabled),
              ),
              'delete': FusionTableCell(
                value: null,
                child: DeleteButton(
                  onDelete: () => cubit.deleteOutputStream(s.id),
                ),
              ),
            },
          ),
        )
        .toList();
  }
}
