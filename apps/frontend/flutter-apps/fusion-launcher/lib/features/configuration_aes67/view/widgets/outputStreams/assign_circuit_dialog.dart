import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_aes67/viewModel/assign_circuit_viewmodel/assign_circuit_viewmodel.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/aes67/configation_aes67.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class AssignCircuitDialog extends StatelessWidget {
  final Aes67Config stream;
  final void Function(Aes67Config updatedStream)? onSave;

  const AssignCircuitDialog({super.key, required this.stream, this.onSave});

  static Future<void> show(
    BuildContext context, {
    required Aes67Config stream,
    void Function(Aes67Config updatedStream)? onSave,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext ctx, _, __) => AssignCircuitDialog(stream: stream, onSave: onSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    return BlocProvider<AssignCircuitViewmodel>(
      create: (_) => AssignCircuitViewmodel(projectViewModel: projectViewModel)..init(stream),
      child: _DialogContent(onSave: onSave),
    );
  }
}

// ── Dialog shell ──────────────────────────────────────────────────────────────

class _DialogContent extends StatelessWidget {
  final void Function(Aes67Config updatedStream)? onSave;
  const _DialogContent({this.onSave});

  void _close(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.aes67_assign_circuit_dialog),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            GestureDetector(onTap: () => _close(context), child: Container(color: Colors.transparent)),
            Center(
              child: Container(
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.all(32),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.52,
                  maxHeight: MediaQuery.of(context).size.height * 0.80,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  border: Border.all(color: context.colorScheme.strokeLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Header(onClose: () => _close(context)),
                    Flexible(
                      child: BlocBuilder<AssignCircuitViewmodel, AssignCircuitState>(
                        builder:
                            (BuildContext context, AssignCircuitState state) => switch (state) {
                              AssignCircuitInitial() => const SizedBox.shrink(),
                              AssignCircuitLoading() => const Padding(
                                padding: EdgeInsets.all(48),
                                child: CircularProgressIndicator(),
                              ),
                              AssignCircuitLoaded() => _LoadedBody(state: state, onSave: onSave),
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.aes67_assign_circuit_dialog_header),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              semanticId: FusionTestKeys.instance.aes67_assign_circuit_dialog_header_text,
              text: 'ASSIGN CIRCUIT',
              style: context.textTheme.bodySmall?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.textPrimary,
              ),
            ),
            InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FusionIcon.icon(
                  semanticId: FusionTestKeys.instance.aes67_assign_circuit_dialog_header_icon,
                  LucideIcons.x,
                  size: 18,
                  color: context.colorScheme.iconDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loaded body ───────────────────────────────────────────────────────────────
//
// Layout:  ┌─────────────────┬────────────────────────────────┐
//          │  Channel list   │  Circuit tree                  │
//          │  (left panel)   │  (right panel, scrollable)     │
//          └─────────────────┴────────────────────────────────┘
//          │              Footer (Save)                       │

class _LoadedBody extends StatelessWidget {
  final AssignCircuitLoaded state;
  final void Function(Aes67Config updatedStream)? onSave;

  const _LoadedBody({required this.state, this.onSave});

  @override
  Widget build(BuildContext context) {
    final AssignCircuitViewmodel cubit = context.read<AssignCircuitViewmodel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── Two-panel body ───────────────────────────────────────────
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Left: channel list (elevation2 background) ──────────
              SizedBox(
                width: 150,
                child: _ChannelPanel(
                  channelRows: state.channelRows,
                  selectedChannelNumber: state.selectedChannelNumber,
                  onChannelTap: cubit.selectChannel,
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: context.colorScheme.strokeLight),
              // ── Right: circuit tree ─────────────────────────────────
              Expanded(
                child: _CircuitTreePanel(
                  zoneTree: state.zoneTree,
                  selectedCircuitId: state.selectedChannel.selectedCircuitId,
                  onCircuitSelected: (String id) => cubit.selectCircuit(state.selectedChannelNumber, id),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
        _Footer(
          onSave: () {
            final Aes67Config? updated = cubit.buildUpdatedStream();
            if (updated != null) onSave?.call(updated);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// ── Left panel ────────────────────────────────────────────────────────────────

class _ChannelPanel extends StatelessWidget {
  final List<ChannelAssignmentRow> channelRows;
  final int selectedChannelNumber;
  final ValueChanged<int> onChannelTap;

  const _ChannelPanel({
    required this.channelRows,
    required this.selectedChannelNumber,
    required this.onChannelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Panel header ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight)),
            ),
            child: FusionAppText(
              text: 'Channels',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
                color: context.colorScheme.textSecondary,
              ),
            ),
          ),
          // ── Channel items ────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children:
                    channelRows.map((ChannelAssignmentRow row) {
                      final bool isActive = row.channelNumber == selectedChannelNumber;
                      final bool assigned = row.selectedCircuitId != null;
                      return InkWell(
                        onTap: () => onChannelTap(row.channelNumber),
                        child: SemanticHelper.container(
                          testId: SemanticHelper.createTestId(
                            SemanticTypes.container,
                            '${FusionTestKeys.instance.aes67_assign_circuit_dialog_channel_row}_${row.channelNumber}',
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: double.infinity,
                            padding: const EdgeInsets.only(left: 12, right: 10, top: 11, bottom: 11),
                            decoration: BoxDecoration(
                              color: isActive ? context.colorScheme.elevation1 : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isActive ? context.colorScheme.primaryColor : Colors.transparent,
                                  width: 3,
                                ),
                                bottom: BorderSide(color: context.colorScheme.strokeLight),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: FusionAppText(
                                    semanticId: '${FusionTestKeys.instance.aes67_assign_circuit_dialog_channel_label}_${row.channelNumber}',
                                    text: row.channelLabel,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                      color: isActive ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                                    ),
                                  ),
                                ),
                                if (assigned)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Right panel ───────────────────────────────────────────────────────────────

class _CircuitTreePanel extends StatelessWidget {
  final List<CircuitTreeNode> zoneTree;
  final String? selectedCircuitId;
  final ValueChanged<String> onCircuitSelected;

  const _CircuitTreePanel({
    required this.zoneTree,
    required this.selectedCircuitId,
    required this.onCircuitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Panel header ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight)),
          ),
          child: FusionAppText(
            text: 'Select Circuit',
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
              color: context.colorScheme.textSecondary,
            ),
          ),
        ),
        // ── Tree ─────────────────────────────────────────────────
        Flexible(
          child:
              zoneTree.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.cable_outlined, size: 28, color: context.colorScheme.iconDefault),
                          const SizedBox(height: 8),
                          FusionAppText(
                            text: 'No zones configured',
                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          zoneTree.map((CircuitTreeNode node) {
                            return switch (node) {
                              ZoneTreeNode() => _ZoneSection(
                                zoneName: node.name,
                                zoneColor: node.color,
                                circuits: node.circuits,
                                selectedCircuitId: selectedCircuitId,
                                onCircuitSelected: onCircuitSelected,
                              ),
                              ZoneWithSubZonesTreeNode() => _ZoneWithSubZonesSection(
                                zoneName: node.name,
                                zoneColor: node.color,
                                subZones: node.subZones,
                                selectedCircuitId: selectedCircuitId,
                                onCircuitSelected: onCircuitSelected,
                              ),
                              SubZoneTreeNode() => const SizedBox.shrink(),
                            };
                          }).toList(),
                    ),
                  ),
        ),
      ],
    );
  }
}

// ── Zone (no sub-zones) ───────────────────────────────────────────────────────

class _ZoneSection extends StatelessWidget {
  final String zoneName;
  final Color zoneColor;
  final List<CircuitModel> circuits;
  final String? selectedCircuitId;
  final ValueChanged<String> onCircuitSelected;

  const _ZoneSection({
    required this.zoneName,
    required this.zoneColor,
    required this.circuits,
    required this.selectedCircuitId,
    required this.onCircuitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ZoneHeader(label: zoneName, color: zoneColor),
        if (circuits.isEmpty)
          const _EmptyHint(indent: 16)
        else
          ...circuits.map(
            (CircuitModel c) => _CircuitRow(
              circuit: c,
              isSelected: selectedCircuitId == c.id,
              indent: 16,
              onTap: () => onCircuitSelected(c.id),
            ),
          ),
      ],
    );
  }
}

// ── Zone (with sub-zones) ────────────────────────────────────────────────────

class _ZoneWithSubZonesSection extends StatelessWidget {
  final String zoneName;
  final Color zoneColor;
  final List<SubZoneTreeNode> subZones;
  final String? selectedCircuitId;
  final ValueChanged<String> onCircuitSelected;

  const _ZoneWithSubZonesSection({
    required this.zoneName,
    required this.zoneColor,
    required this.subZones,
    required this.selectedCircuitId,
    required this.onCircuitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ZoneHeader(label: zoneName, color: zoneColor),
        ...subZones.map(
          (SubZoneTreeNode sz) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SubZoneHeader(label: sz.name, zoneColor: zoneColor),
              if (sz.circuits.isEmpty)
                const _EmptyHint(indent: 32)
              else
                ...sz.circuits.map(
                  (CircuitModel c) => _CircuitRow(
                    circuit: c,
                    isSelected: selectedCircuitId == c.id,
                    indent: 32,
                    onTap: () => onCircuitSelected(c.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Zone header ───────────────────────────────────────────────────────────────

class _ZoneHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _ZoneHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight)),
      ),
      child: Row(
        children: <Widget>[
          // ── Colored square indicator ──────────────────────────
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-zone header ───────────────────────────────────────────────────────────

class _SubZoneHeader extends StatelessWidget {
  final String label;
  final Color zoneColor;
  const _SubZoneHeader({required this.label, required this.zoneColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 16, top: 8, bottom: 4),
      child: Row(
        children: <Widget>[
          // ── Zone-colored accent bar ───────────────────────────
          Container(
            width: 3,
            height: 12,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circuit radio row ─────────────────────────────────────────────────────────

class _CircuitRow extends StatelessWidget {
  final CircuitModel circuit;
  final bool isSelected;
  final double indent;
  final VoidCallback onTap;

  const _CircuitRow({
    required this.circuit,
    required this.isSelected,
    required this.indent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // toggles: select if not selected, deselect if already selected
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isSelected ? context.colorScheme.primaryColor.withValues(alpha: 0.06) : Colors.transparent,
        padding: EdgeInsets.only(left: indent, right: 16, top: 1, bottom: 1),
        child: Row(
          children: <Widget>[
            // Use a custom radio-like toggle instead of Radio widget so tapping
            // an already-selected item fires onChanged (Radio blocks that natively).
            GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? context.colorScheme.primaryColor : context.colorScheme.strokeLight,
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FusionAppText(
                text: circuit.name,
                style: context.textTheme.bodySmall?.copyWith(
                  color: isSelected ? context.colorScheme.primaryColor : context.colorScheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty hint ────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final double indent;
  const _EmptyHint({required this.indent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent + 16, top: 4, bottom: 6),
      child: FusionAppText(
        text: 'No circuits',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback onSave;
  const _Footer({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.aes67_assign_circuit_dialog_footer),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.textPrimary,
                foregroundColor: context.colorScheme.primaryBlack,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: FusionAppText(
                semanticId: FusionTestKeys.instance.aes67_assign_circuit_dialog_save_button,
                text: 'Save',
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.primaryBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
