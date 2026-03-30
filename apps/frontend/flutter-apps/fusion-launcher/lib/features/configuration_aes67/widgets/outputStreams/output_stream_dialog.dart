import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../viewModel/output_stream_viewmodel/output_stream_viewmodel.dart';

// ── Entry point ──────────────────────────────────────────────────────────────

class OutputStreamDialog extends StatelessWidget {
  final void Function(Aes67Config stream)? onSave;
  final Aes67Config? existingStream;
  final bool isEditing;

  const OutputStreamDialog({super.key, this.onSave, this.existingStream, this.isEditing = false});

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
      pageBuilder: (BuildContext ctx, _, __) => OutputStreamDialog(onSave: onSave, existingStream: existingStream, isEditing: isEditing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return BlocProvider<OutputStreamViewmodel>(
      create: (_) => OutputStreamViewmodel(projectViewModel: projectViewModel, streamId: existingStream?.id)..init(existingStream: existingStream),
      child: _DialogContent(onSave: onSave, isEditing: isEditing),
    );
  }
}

// ── Dialog shell ─────────────────────────────────────────────────────────────

class _DialogContent extends StatelessWidget {
  final void Function(Aes67Config stream)? onSave;
  final bool isEditing;

  const _DialogContent({this.onSave, this.isEditing = false});

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
                maxWidth: MediaQuery.of(context).size.width * 0.30,
                maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                    child: BlocBuilder<OutputStreamViewmodel, OutputStreamState>(
                      builder:
                          (BuildContext context, OutputStreamState state) => switch (state) {
                            OutputStreamInitial() => const SizedBox.shrink(),
                            OutputStreamLoading() => const Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            ),
                            OutputStreamError(:final String message) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: FusionAppText(text: message),
                            ),
                            OutputStreamLoaded() => _LoadedBody(state: state, onSave: onSave, isEditing: isEditing),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.strokeLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FusionAppText(
            text: 'AES 67 OUTPUT STREAM',
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
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: context.colorScheme.iconDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loaded body ───────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  final OutputStreamLoaded state;
  final void Function(Aes67Config stream)? onSave;
  final bool isEditing;

  const _LoadedBody({required this.state, this.onSave, this.isEditing = false});

  // Fixed measurement constants — shared by every row so columns align
  static const double _labelW = 100.0; // "Name", "Session ID", etc.
  static const double _gapLabel = 12.0; // label ↔ field

  @override
  Widget build(BuildContext context) {
    final OutputStreamViewmodel cubit = context.read<OutputStreamViewmodel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── Scrollable form area ─────────────────────────────────────
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Row 1: Name (stream name) ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      width: _labelW,
                      child: _FieldLabel(text: 'Name'),
                    ),
                    const SizedBox(width: _gapLabel),
                    Expanded(
                      child: _DarkTextField(
                        value: state.name,
                        onChanged: cubit.updateName,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Row 2: Channel count + per-channel name fields ───
                // Layout:
                //   [labelW: "Name"] [gap] [small-badge: count] [gap] [channel-name-field]
                //                                               [gap] [channel-name-field]
                //                                               ...
                _ChannelSection(
                  state: state,
                  cubit: cubit,
                  labelW: _labelW,
                  gapLabel: _gapLabel,
                ),

                const SizedBox(height: 20),

                // ── Advanced collapsible ─────────────────────────────
                _AdvancedSection(
                  state: state,
                  cubit: cubit,
                  labelW: _labelW,
                  gapLabel: _gapLabel,
                ),
              ],
            ),
          ),
        ),

        // ── Footer ──────────────────────────────────────────────────
        _Footer(
          onExport: cubit.exportSdp,
          onSave: () {
            final Aes67Config? stream = cubit.getCurrentStream();
            if (stream != null) {
              onSave?.call(stream);
              cubit.save();
            }
            Navigator.of(context).pop();
          },
          isEditing: isEditing,
        ),
      ],
    );
  }
}

// ── Channel section ───────────────────────────────────────────────────────────
//
// Renders:
//   Name  [2]  [Channel 1 field]
//              [Channel 2 field]
//              ...
//
// The count badge and every channel field are left-edge-aligned with each
// other (they all start at labelW + gap). The "Name" label is in the fixed
// labelW column so it lines up with the labels below it.

class _ChannelSection extends StatelessWidget {
  final OutputStreamLoaded state;
  final OutputStreamViewmodel cubit;
  final double labelW;
  final double gapLabel;

  const _ChannelSection({
    required this.state,
    required this.cubit,
    required this.labelW,
    required this.gapLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Count badge width — fixed so all channel fields left-align perfectly
    const double badgeW = 48.0;
    const double gapBadge = 12.0; // badge ↔ channel-name field

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // "Name" label
        SizedBox(
          width: labelW,
          child: const Padding(
            // Vertically centre against the first channel row (≈38px high)
            padding: EdgeInsets.only(top: 10),
            child: _FieldLabel(text: 'Name'),
          ),
        ),
        SizedBox(width: gapLabel),

        // Count badge — vertically centred against first channel field
        SizedBox(
          width: badgeW,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _CountDropdown(
              value: state.channelCount,
              onChanged: cubit.updateChannelCount,
            ),
          ),
        ),
        const SizedBox(width: gapBadge),

        // Channel name fields stacked
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                state.channelConfigs.map((Aes67ChannelConfig ch) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DarkTextField(
                      value: ch.label ?? 'Channel ${ch.channelNumber}',
                      onChanged: (String v) => cubit.updateChannelName(ch.channelNumber, v),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Advanced section ──────────────────────────────────────────────────────────

class _AdvancedSection extends StatelessWidget {
  final OutputStreamLoaded state;
  final OutputStreamViewmodel cubit;
  final double labelW;
  final double gapLabel;

  const _AdvancedSection({
    required this.state,
    required this.cubit,
    required this.labelW,
    required this.gapLabel,
  });

  static const List<String> _bitDepths = <String>['16 bit', '24 bit', '32 bit'];
  static const List<String> _sampleRates = <String>[
    '44.1 kHz',
    '48 kHz',
    '88.2 kHz',
    '96 kHz',
  ];
  static const List<String> _packetTimes = <String>[
    '125 µs',
    '250 µs',
    '333 µs',
    '1 ms',
    '4 ms',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── "Advanced" toggle — right-aligned ────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: cubit.toggleAdvanced,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FusionAppText(
                text: 'Advanced',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // ── Animated expand / collapse ───────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Session ID
                _FormRow(
                  labelW: labelW,
                  gapLabel: gapLabel,
                  label: 'Session ID',
                  child: _DarkTextField(
                    value: state.sessionId,
                    onChanged: cubit.updateSessionId,
                  ),
                ),
                const SizedBox(height: 14),

                // IP Address
                _FormRow(
                  labelW: labelW,
                  gapLabel: gapLabel,
                  label: 'IP Address',
                  child: _DarkTextField(
                    value: state.ipAddress,
                    onChanged: cubit.updateIpAddress,
                  ),
                ),
                const SizedBox(height: 14),

                // Bit Depth
                _FormRow(
                  labelW: labelW,
                  gapLabel: gapLabel,
                  label: 'Bit Depth',
                  child: _DarkDropdown<String>(
                    value: state.bitDepth,
                    hint: '—',
                    items: _bitDepths,
                    labelBuilder: (String v) => v,
                    onChanged: cubit.updateBitDepth,
                  ),
                ),
                const SizedBox(height: 14),

                // Sample Rate
                _FormRow(
                  labelW: labelW,
                  gapLabel: gapLabel,
                  label: 'Sample Rate',
                  child: _DarkDropdown<String>(
                    value: state.sampleRate,
                    hint: '—',
                    items: _sampleRates,
                    labelBuilder: (String v) => v,
                    onChanged: cubit.updateSampleRate,
                  ),
                ),
                const SizedBox(height: 14),

                // Packet Time
                _FormRow(
                  labelW: labelW,
                  gapLabel: gapLabel,
                  label: 'Packet Time',
                  child: _DarkDropdown<String>(
                    value: state.packetTime,
                    hint: '—',
                    items: _packetTimes,
                    labelBuilder: (String v) => v,
                    onChanged: cubit.updatePacketTime,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: state.isAdvancedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onSave;
  final bool isEditing;

  const _Footer({required this.onExport, required this.onSave, this.isEditing = false});

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
          // Export SDP Config — outlined
          OutlinedButton(
            onPressed: onExport,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colorScheme.strokeLight),
              foregroundColor: context.colorScheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: FusionAppText(
              text: 'Export SDP Config',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.textPrimary,
              ),
            ),
          ),

          // Save/Edit — filled
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.textPrimary,
              foregroundColor: context.colorScheme.primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

// ── Shared layout helper ──────────────────────────────────────────────────────

/// A label + arbitrary field widget that keeps the label column fixed-width
/// so all rows in the Advanced section align in a perfect grid.
class _FormRow extends StatelessWidget {
  final double labelW;
  final double gapLabel;
  final String label;
  final Widget child;

  const _FormRow({
    required this.labelW,
    required this.gapLabel,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: labelW,
          child: _FieldLabel(text: label),
        ),
        SizedBox(width: gapLabel),
        Expanded(child: child),
      ],
    );
  }
}

// ── Small channel-count badge dropdown ───────────────────────────────────────

class _CountDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CountDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: context.colorScheme.elevation2,
          icon: const SizedBox.shrink(), // no chevron — space is tight
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items:
              List<int>.generate(8, (int i) => i + 1)
                  .map(
                    (int n) => DropdownMenuItem<int>(
                      value: n,
                      child: FusionAppText(
                        text: n.toString(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (int? v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Primitive widgets (mirrored from input stream dialog) ─────────────────────

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
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: context.colorScheme.textSecondary,
          ),
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
