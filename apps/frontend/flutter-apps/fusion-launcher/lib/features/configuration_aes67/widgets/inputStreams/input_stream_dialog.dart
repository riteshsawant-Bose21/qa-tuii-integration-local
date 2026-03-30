import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../viewModel/input_stream_viewmodel/input_stream_viewmodel.dart';
import 'header.dart';

class InputStreamDialog extends StatelessWidget {
  final void Function(Aes67Config stream)? onSave;
  final Aes67Config? existingStream;
  final bool isEditing;

  const InputStreamDialog({super.key, this.onSave, this.existingStream, this.isEditing = false});

  static Future<void> show(
    BuildContext context, {
    void Function(Aes67Config stream)? onSave,
    Aes67Config? existingStream,
    bool isEditing = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext ctx, _, __) => InputStreamDialog(onSave: onSave, existingStream: existingStream, isEditing: isEditing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return BlocProvider<InputStreamViewmodel>(
      create: (_) => InputStreamViewmodel(projectViewModel: projectViewModel, streamId: existingStream?.id)..init(existingStream: existingStream),
      child: _InputStreamDialogContent(onSave: onSave, isEditing: isEditing),
    );
  }
}

class _InputStreamDialogContent extends StatelessWidget {
  final void Function(Aes67Config stream)? onSave;
  final bool isEditing;

  const _InputStreamDialogContent({this.onSave, this.isEditing = false});

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
                            InputStreamError(:final String message) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: FusionAppText(text: message),
                            ),
                            InputStreamLoaded() => _DialogContent(state: state, onSave: onSave, isEditing: isEditing),
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
  final void Function(Aes67Config stream)? onSave;
  final bool isEditing;

  const _DialogContent({required this.state, this.onSave, this.isEditing = false});

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
    final bool isControl = serviceLocator<ProjectViewModel>().isInControlMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// ── Row 1: Name  |  Assigned to ─────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    /// LEFT col — label + name field
                    const SizedBox(width: _labelW, child: _FieldLabel(text: 'Name')),
                    const SizedBox(width: _gapLabel),
                    SizedBox(
                      width: _nameFieldW,
                      child: _DarkTextField(
                        value: state.name,
                        onChanged: cubit.updateName,
                      ),
                    ),

                    const SizedBox(width: _gapCols),

                    /// RIGHT col — label + assigned-to dropdown (always visible, disabled when not in control mode)
                    Opacity(
                      opacity: isControl ? 1.0 : 0.5,
                      child: const SizedBox(width: _labelW, child: _FieldLabel(text: 'Assigned to')),
                    ),
                    const SizedBox(width: _gapLabel),
                    Opacity(
                      opacity: isControl ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !isControl,
                        child: SizedBox(
                          width: _dropW,
                          child: _DarkDropdown<String>(
                            // Only use the value if it exists in the current options, otherwise null
                            value: (state.assignedTo != null && state.danteAssignableOptions.contains(state.assignedTo)) ? state.assignedTo : null,
                            hint: '—',
                            items: state.danteAssignableOptions,
                            labelBuilder: (String v) => v,
                            onChanged: cubit.updateAssignedTo,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// ── Row 2: Channels  |  (right col empty) ──────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: _labelW, child: _FieldLabel(text: 'Channels')),
                    const SizedBox(width: _gapLabel),
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
                  assignOptions: state.selectedSessionChannelOptions,
                ),

                const SizedBox(height: 24),

                /// ── Network connection note (only in design mode) ─────────
                if (!isControl)
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: context.colorScheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      FusionAppText(
                        text:
                            state.selectedSessionId != null
                                ? 'Discovered sessions will be shown here when connected to the network.'
                                : 'Connect to network to map channels.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                if (serviceLocator<ProjectViewModel>().isInControlMode) _SelectSessionSection(state: state, cubit: cubit),
              ],
            ),
          ),
        ),

        // Show footer when in control mode OR when editing in non-control mode (to allow name editing)
        if (isControl || isEditing)
          _Footer(
            onImport: cubit.importSdp,
            onConfirm: () {
              // Get the current stream from the viewmodel
              final Aes67Config? stream = cubit.getCurrentStream();
              if (stream != null) {
                onSave?.call(stream);
                cubit.save();
              }
              Navigator.of(context).pop();
            },
            isEditing: isEditing,
            isControlMode: isControl,
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
  final List<String> assignOptions; // Dynamic options from selected session

  const _ChannelGrid({
    required this.channelConfigs,
    required this.cubit,
    required this.isControl,
    required this.numW,
    required this.dropW,
    required this.labelW,
    required this.gapNum,
    required this.gapCols,
    required this.assignOptions,
  });

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
                      value: channel.label ?? '',
                      onChanged: (String v) => cubit.updateChannelLabel(channel.channelNumber, v),
                    ),
                  ),

                  // ── RIGHT column (always visible, disabled when not in control mode) ─────────────────────
                  SizedBox(width: gapCols),
                  SizedBox(
                    width: labelW,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Opacity(
                        opacity: isControl ? 1.0 : 0.5,
                        child: FusionAppText(
                          text: channel.channelNumber.toString(),
                          style: numStyle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gapNum),
                  Opacity(
                    opacity: isControl ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isControl,
                      child: SizedBox(
                        width: dropW,
                        child: _DarkDropdown<String>(
                          // Only use the value if it exists in the current options, otherwise null
                          value: (channel.assignedTo != null && assignOptions.contains(channel.assignedTo)) ? channel.assignedTo : null,
                          hint: 'Assign',
                          items: assignOptions,
                          labelBuilder: (String v) => v,
                          onChanged: (String? v) {
                            if (v != null) cubit.updateChannelAssignment(channel.channelNumber, v);
                          },
                        ),
                      ),
                    ),
                  ),
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
        color: context.colorScheme.primaryBlack,
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

  const _SessionTableRow({
    required this.session,
    required this.isSelected,
    required this.onSelect,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            // Dante Device checkbox (read-only, from API)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: session.isDanteDevice ? 1.0 : 0.5,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: IgnorePointer(
                      child: Checkbox(
                        value: session.isDanteDevice,
                        onChanged: null,
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
              ),
            ),
            // Radio select for assigning session
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
  final bool isEditing;
  final bool isControlMode;

  const _Footer({
    required this.onImport,
    required this.onConfirm,
    this.isEditing = false,
    this.isControlMode = false,
  });

  /// Determine the button text based on mode:
  /// - When editing: "Edit"
  /// - When adding new: "Save"
  String get _buttonText => isEditing ? 'Edit' : 'Save';

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
          // Import SDP - only show in control mode
          if (isControlMode)
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
            )
          else
            const SizedBox.shrink(),

          // Save button
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.textPrimary,
              foregroundColor: context.colorScheme.primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: FusionAppText(
              text: _buttonText,
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
  final ValueChanged<String> onChanged;

  const _DarkTextField({required this.value, required this.onChanged});

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
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.textPrimary,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: context.colorScheme.elevation2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colorScheme.strokeLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colorScheme.strokeLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colorScheme.primaryColor),
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: FusionAppText(
            text: hint,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          isDense: true,
          isExpanded: true,
          dropdownColor: context.colorScheme.elevation2,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.colorScheme.textSecondary),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.textPrimary,
          ),
          items:
              items
                  .map(
                    (T item) => DropdownMenuItem<T>(
                      value: item,
                      child: FusionAppText(
                        text: labelBuilder(item),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
