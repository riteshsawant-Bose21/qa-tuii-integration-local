import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../viewModel/input_stream_viewmodel/input_stream_viewmodel.dart';
import 'header.dart';

class InputStreamDialog extends StatelessWidget {
  final Aes67AppMode mode;

  const InputStreamDialog({super.key, required this.mode});

  static Future<void> show(
    BuildContext context, {
    required Aes67AppMode mode,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext ctx, _, __) => InputStreamDialog(mode: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InputStreamViewmodel>(
      create: (_) => InputStreamViewmodel()..init(mode: mode),
      child: const _InputStreamDialogContent(),
    );
  }
}

class _InputStreamDialogContent extends StatelessWidget {
  const _InputStreamDialogContent();

  void _close(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () => _close(context),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: Container(
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(color: context.colorScheme.strokeLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Header(onClose: () => _close(context)),
                  Flexible(
                    child: BlocBuilder<InputStreamViewmodel, InputStreamState>(
                      builder:
                          (BuildContext context, InputStreamState state) => switch (state) {
                            InputStreamInitial() => const SizedBox.shrink(),
                            InputStreamLoading() => const Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            ),
                            ConfigAes67DialogError(:final String message) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: FusionAppText(text: message),
                            ),
                            InputStreamLoaded() => _DialogContent(state: state),
                          },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  final InputStreamLoaded state;
  const _DialogContent({required this.state});

  /// ── Fixed column measurements (shared by header rows AND every channel row
  ///    so every element lines up in a perfect two-column grid) ──────────────
  static const double _numW = 28.0; // channel-number badge
  static const double _dropW = 200.0; // label / assign dropdown
  static const double _labelW = 90.0; // "Name" / "Channels" / "Assigned to"
  static const double _nameFieldW = 200.0;
  static const double _gapNum = 8.0; // number ↔ dropdown
  static const double _gapLabel = 8.0; // label ↔ field
  static const double _gapCols = 48.0; // left col ↔ right col

  @override
  Widget build(BuildContext context) {
    final InputStreamViewmodel cubit = context.read<InputStreamViewmodel>();
    final bool isControl = state.mode == Aes67AppMode.control;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// ── Row 1: Name  |  Assigned to (control only) ─────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    /// LEFT col — label + name field
                    const SizedBox(width: _labelW, child: _FieldLabel(text: 'Name')),
                    const SizedBox(width: _gapLabel),
                    SizedBox(
                      width: _nameFieldW,
                      child: _DarkTextField(
                        semanticId: 'name-field',
                        value: state.name,
                        onChanged: cubit.updateName,
                      ),
                    ),

                    if (isControl) ...<Widget>[
                      const SizedBox(width: _gapCols),

                      /// RIGHT col — label + assigned-to dropdown
                      const SizedBox(width: _labelW, child: _FieldLabel(text: 'Assigned to')),
                      const SizedBox(width: _gapLabel),
                      SizedBox(
                        width: _dropW,
                        child: _DarkDropdown<String>(
                          value: state.assignedTo,
                          hint: '—',
                          items: state.danteAssignableOptions,
                          labelBuilder: (String v) => v,
                          onChanged: cubit.updateAssignedTo,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                /// ── Row 2: Channels  |  (right col empty) ──────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: _labelW, child: _FieldLabel(text: 'Channels')),
                    const SizedBox(width: _gapLabel),

                    /// dynamic channel list
                    SizedBox(
                      width: _nameFieldW,
                      child: _DarkDropdown<int>(
                        value: state.channelCount,
                        hint: '—',
                        items: List<int>.generate(8, (int i) => i + 1),
                        labelBuilder: (int v) => v.toString(),
                        onChanged: (int? v) {
                          if (v != null) cubit.updateChannelCount(v);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// ── Channel config rows (one per channel, in a two-column grid) ─────────
                _ChannelGrid(
                  channelConfigs: state.channelConfigs,
                  cubit: cubit,
                  isControl: isControl,
                  numW: _numW,
                  dropW: _dropW,
                  labelW: _labelW,
                  gapNum: _gapNum,
                  gapCols: _gapCols,
                ),

                const SizedBox(height: 24),

                if (isControl) _SelectSessionSection(state: state, cubit: cubit),
              ],
            ),
          ),
        ),

        if (isControl)
          _Footer(
            onImport: cubit.importSdp,
            onConfirm: cubit.confirmSelectSession,
          ),
      ],
    );
  }
}
// ── Channel rows ──────────────────────────────────────────────────────────────

class _ChannelGrid extends StatelessWidget {
  final List<Aes67ChannelConfig> channelConfigs;
  final InputStreamViewmodel cubit;
  final bool isControl;
  final double numW;
  final double dropW;
  final double labelW; // re-used so numbers sit under "Name" label
  final double gapNum;
  final double gapCols;

  const _ChannelGrid({
    required this.channelConfigs,
    required this.cubit,
    required this.isControl,
    required this.numW,
    required this.dropW,
    required this.labelW,
    required this.gapNum,
    required this.gapCols,
  });

  static const List<String> _assignOptions = <String>[
    'StageEX4ML1_1',
    'StageEX4ML1_2',
    'StageEX4ML1_3',
    'StageEX4ML1_4',
    'MainMix_L',
    'MainMix_R',
  ];

  @override
  Widget build(BuildContext context) {
    final TextStyle? numStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.textSecondary,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          channelConfigs.map((Aes67ChannelConfig channel) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  /// lines up under the "Name" / "Channels" label above.
                  SizedBox(
                    width: labelW,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FusionAppText(
                        text: channel.channelNumber.toString(),
                        style: numStyle,
                      ),
                    ),
                  ),
                  SizedBox(width: gapNum),
                  SizedBox(
                    width: dropW,
                    child: _DarkTextField(
                      semanticId: '',
                      value: channel.label ?? '',
                      onChanged: (String v) => cubit.updateChannelLabel(channel.channelNumber, v),
                    ),
                  ),

                  // ── RIGHT column (control mode only) ─────────────────────
                  if (isControl) ...<Widget>[
                    SizedBox(width: gapCols),
                    SizedBox(
                      width: labelW,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FusionAppText(
                          text: channel.channelNumber.toString(),
                          style: numStyle,
                        ),
                      ),
                    ),
                    SizedBox(width: gapNum),
                    SizedBox(
                      width: dropW,
                      child: _DarkDropdown<String>(
                        value: channel.assignedTo,
                        hint: 'Assign',
                        items: _assignOptions,
                        labelBuilder: (String v) => v,
                        onChanged: (String? v) {
                          if (v != null) cubit.updateChannelAssignment(channel.channelNumber, v);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _SelectSessionSection extends StatelessWidget {
  final InputStreamLoaded state;
  final InputStreamViewmodel cubit;

  const _SelectSessionSection({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Collapsible header row
        InkWell(
          onTap: cubit.toggleSessionSection,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedRotation(
                  turns: state.isSessionSectionExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: context.colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                FusionAppText(
                  text: 'Select Session',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animated expand/collapse
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _SessionTable(state: state, cubit: cubit),
          ),
          crossFadeState: state.isSessionSectionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

// ── Session table ─────────────────────────────────────────────────────────────

class _SessionTable extends StatelessWidget {
  final InputStreamLoaded state;
  final InputStreamViewmodel cubit;

  const _SessionTable({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2.withAlpha(200),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Column(
        children: <Widget>[
          // Header row
          const _SessionTableHeader(),
          Divider(height: 1, color: context.colorScheme.strokeLight),
          // Data rows
          ...state.sessions.map(
            (Aes67SessionEntry session) => _SessionTableRow(
              session: session,
              isSelected: state.selectedSessionId == session.id,
              onSelect: () => cubit.selectSession(session.id),
              onToggleDante: () => cubit.toggleDanteDevice(session.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTableHeader extends StatelessWidget {
  const _SessionTableHeader();

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = context.textTheme.bodySmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: context.colorScheme.textSecondary,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(flex: 3, child: FusionAppText(text: 'SESSION ID', style: style)),
          Expanded(flex: 2, child: FusionAppText(text: 'CHANNELS', style: style)),
          Expanded(flex: 3, child: FusionAppText(text: 'IP ADDRESS', style: style)),
          Expanded(flex: 2, child: FusionAppText(text: 'PORT', style: style)),
          Expanded(flex: 2, child: FusionAppText(text: 'BIT DEPTH', style: style)),
          Expanded(flex: 2, child: FusionAppText(text: 'SAMPLE RATE', style: style)),
          Expanded(flex: 2, child: FusionAppText(text: 'PACKET TIME', style: style)),
          Expanded(flex: 2, child: FusionAppText(text: 'DANTE DEVICE', style: style)),
          const SizedBox(width: 40), // radio column
        ],
      ),
    );
  }
}

class _SessionTableRow extends StatelessWidget {
  final Aes67SessionEntry session;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onToggleDante;

  const _SessionTableRow({
    required this.session,
    required this.isSelected,
    required this.onSelect,
    required this.onToggleDante,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.textPrimary,
      fontWeight: FontWeight.w400,
    );
    final TextStyle? boldStyle = textStyle?.copyWith(fontWeight: FontWeight.w700);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.strokeLight.withOpacity(0.4),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            // Session ID (bold)
            Expanded(
              flex: 3,
              child: FusionAppText(
                text: session.sessionId,
                style: boldStyle,
                maxLine: 1,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),
            // Channels
            Expanded(
              flex: 2,
              child: FusionAppText(text: session.channels.toString(), style: textStyle),
            ),
            // IP Address — "IPv4  239.x.x.x"
            Expanded(
              flex: 3,
              child: Row(
                children: <Widget>[
                  FusionAppText(
                    text: session.ipVersion,
                    style: textStyle?.copyWith(color: context.colorScheme.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FusionAppText(
                      text: session.ipAddress,
                      style: textStyle,
                      maxLine: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Port
            Expanded(
              flex: 2,
              child: FusionAppText(text: session.port.toString(), style: textStyle),
            ),
            // Bit depth
            Expanded(
              flex: 2,
              child: FusionAppText(text: session.bitDepth.toString(), style: textStyle),
            ),
            // Sample rate
            Expanded(
              flex: 2,
              child: FusionAppText(text: session.sampleRate, style: textStyle),
            ),
            // Packet time
            Expanded(
              flex: 2,
              child: FusionAppText(text: session.packetTime, style: textStyle),
            ),
            // Dante Device checkbox
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: session.isDanteDevice,
                    onChanged: (_) => onToggleDante(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: context.colorScheme.strokeLight,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            // Radio select
            SizedBox(
              width: 40,
              child: Radio<String>(
                value: session.id,
                groupValue: isSelected ? session.id : null,
                onChanged: (_) => onSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onConfirm;

  const _Footer({required this.onImport, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colorScheme.strokeLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Import SDP
          OutlinedButton(
            onPressed: onImport,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colorScheme.strokeLight),
              foregroundColor: context.colorScheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: FusionAppText(
              text: 'Import SDP Configuration',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.textPrimary,
              ),
            ),
          ),

          // Select Session
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.textPrimary,
              foregroundColor: context.colorScheme.primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: FusionAppText(
              text: 'Select Session',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared primitive widgets ──────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: text,
      style: context.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: context.colorScheme.textPrimary,
      ),
    );
  }
}

/// Dark rounded text field matching the dialog aesthetic
class _DarkTextField extends StatefulWidget {
  final String value;
  final String semanticId;
  final ValueChanged<String> onChanged;

  const _DarkTextField({required this.value, required this.onChanged, required this.semanticId});

  @override
  State<_DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<_DarkTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_DarkTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FusionCustomTextField(
      variant: FusionFieldVariant.neumorphic,
      semanticId: widget.semanticId,
      controller: _ctrl,
      onChange: widget.onChanged,
      height: 35,
      borderRadius: 8,
    );
  }
}

/// Dark rounded dropdown matching the dialog aesthetic
class _DarkDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: DropdownButtonHideUnderline(
        child: FusionNeumorphicDropdown<T>(
          value: value,
          height: 35,
          borderRadius: BorderRadius.circular(8),

          hintText: hint,
          items: items,
          itemBuilderWithSelection: (BuildContext context, T item, bool isSelected) {
            return FusionAppText(
              text: labelBuilder(item),
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected ? context.colorScheme.primary : context.colorScheme.textPrimary,
              ),
            );
          },
          onChanged: onChanged,
        ),
      ),
    );
    // );
  }
}
