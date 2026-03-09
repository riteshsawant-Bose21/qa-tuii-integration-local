import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/message_player_config/viewmodel/message_player_config_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Center panel for configuring message details
class MessageConfigPanel extends StatelessWidget {
  const MessageConfigPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagePlayerConfigCubit, MessagePlayerConfigState>(
      builder: (BuildContext context, MessagePlayerConfigState state) {
        final MessageModel? selectedMessage = state.selectedMessage;

        if (selectedMessage == null) {
          return Center(
            child: FusionAppText(
              text: 'Select a message to configure',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Message Name
              _MessageNameField(
                initialValue: selectedMessage.name,
                onChanged: (String value) {
                  context.read<MessagePlayerConfigCubit>().updateMessageName(value);
                },
              ),

              const SizedBox(height: 20),

              // Audio File
              _AudioFileSection(
                selectedMessage: selectedMessage,
                state: state,
              ),

              // Audio Player (only show if audio file is selected)
              if (selectedMessage.audioFileId != null) ...<Widget>[
                const SizedBox(height: 16),
                _AudioPlayerWidget(state: state),

                const SizedBox(height: 16),

                // Gain Control
                _GainControlSection(
                  gain: selectedMessage.gain,
                  onChanged: (double value) {
                    context.read<MessagePlayerConfigCubit>().updateGain(value);
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Repeat Settings
              _RepeatSettingsSection(
                repeat: selectedMessage.repeat,
                repeatCount: selectedMessage.repeatCount,
                intervalSeconds: selectedMessage.repeatIntervalSeconds,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageNameField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _MessageNameField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_MessageNameField> createState() => _MessageNameFieldState();
}

class _MessageNameFieldState extends State<_MessageNameField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _MessageNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'Message Name',
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        FusionContainer(
          raised: false,
          borderRadius: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controller,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Message Name',
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.textPlaceholder,
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioFileSection extends StatelessWidget {
  final MessageModel selectedMessage;
  final MessagePlayerConfigState state;

  const _AudioFileSection({
    required this.selectedMessage,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();
    final List<MediaFileModel> audioFiles = cubit.getAvailableAudioFiles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'Audio File',
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        FusionDropDown<MediaFileModel>(
          semanticId: 'audio_file_dropdown',
          items: audioFiles,
          selectedIndex: audioFiles.indexWhere(
            (MediaFileModel f) => f.id == selectedMessage.audioFileId,
          ),
          backgroundColor: context.colorScheme.elevation2,
          offset: const Offset(0, 50),
          trigger: FusionContainer(
            raised: false,
            borderRadius: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: selectedMessage.audioFileName ?? 'Select Audio File',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: selectedMessage.audioFileName != null ? context.colorScheme.textPrimary : context.colorScheme.textPlaceholder,
                      ),
                      maxLine: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: context.colorScheme.iconDefault,
                  ),
                ],
              ),
            ),
          ),
          itemBuilder: (BuildContext context, MediaFileModel item, bool isSelected) {
            return Row(
              children: <Widget>[
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: context.colorScheme.primary,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: FusionAppText(
                    text: item.name,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? context.colorScheme.primary : context.colorScheme.textPrimary,
                    ),
                    maxLine: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
          onSelected: (int index) {
            final MediaFileModel file = audioFiles[index];
            cubit.assignAudioFile(file.id, file.name);
          },
        ),
      ],
    );
  }
}

class _AudioPlayerWidget extends StatelessWidget {
  final MessagePlayerConfigState state;

  const _AudioPlayerWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();
    final MessageModel? selectedMessage = state.selectedMessage;

    if (selectedMessage?.audioFileName == null) return const SizedBox.shrink();

    return FusionContainer(
      raised: false,
      borderRadius: 12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // File name with play button
            Row(
              children: <Widget>[
                InkWell(
                  onTap: () => cubit.togglePlayPause(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: context.colorScheme.iconWhite,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FusionAppText(
                    text: selectedMessage!.audioFileName!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                    maxLine: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: <Widget>[
                FusionAppText(
                  text: _formatDuration(state.currentPosition),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: state.currentPosition.inSeconds.toDouble(),
                      min: 0,
                      max: (state.totalDuration?.inSeconds ?? 1).toDouble(),
                      activeColor: context.colorScheme.primary,
                      inactiveColor: context.colorScheme.elevation4,
                      onChanged: (double value) {
                        cubit.seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                ),
                FusionAppText(
                  text: _formatDuration(state.totalDuration ?? Duration.zero),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _GainControlSection extends StatelessWidget {
  final double gain;
  final ValueChanged<double> onChanged;

  const _GainControlSection({
    required this.gain,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      raised: false,
      borderRadius: 12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  LucideIcons.volume2,
                  size: 18,
                  color: context.colorScheme.iconDefault,
                ),
                const SizedBox(width: 8),
                FusionAppText(
                  text: 'Audio Gain Control',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GainSlider(
              value: gain,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _GainSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _GainSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: -6,
            max: 6,
            divisions: 24,
            activeColor: context.colorScheme.primary,
            inactiveColor: context.colorScheme.elevation4,
            onChanged: onChanged,
          ),
        ),
        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FusionAppText(
                text: '-6',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
              FusionAppText(
                text: '-3',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
              FusionAppText(
                text: '0',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
              FusionAppText(
                text: '+3',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
              FusionAppText(
                text: '+6',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepeatSettingsSection extends StatelessWidget {
  final bool repeat;
  final int repeatCount;
  final int intervalSeconds;

  const _RepeatSettingsSection({
    required this.repeat,
    required this.repeatCount,
    required this.intervalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Repeat checkbox
        Row(
          children: <Widget>[
            FusionCheckbox(
              value: repeat,
              semanticId: 'repeat_checkbox',
              onChanged: () => cubit.toggleRepeat(!repeat),
            ),
            const SizedBox(width: 12),
            FusionAppText(
              text: 'Repeat',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.textPrimary,
              ),
            ),
          ],
        ),

        if (repeat) ...<Widget>[
          const SizedBox(height: 16),

          // Times and Interval dropdowns
          Row(
            children: <Widget>[
              Expanded(
                child: _DropdownField(
                  label: 'Times (No.)',
                  value: repeatCount,
                  items: List<int>.generate(10, (int i) => i + 1),
                  onChanged: (int value) => cubit.updateRepeatCount(value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DropdownField(
                  label: 'Interval (sec.)',
                  value: intervalSeconds,
                  items: <int>[1, 2, 3, 5, 10, 15, 30, 60],
                  onChanged: (int value) => cubit.updateRepeatInterval(value),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final ValueChanged<int> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = items.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: label,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        FusionDropDown<int>(
          semanticId: '${label}_dropdown',
          items: items,
          selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
          backgroundColor: context.colorScheme.elevation2,
          offset: const Offset(0, 50),
          trigger: FusionContainer(
            raised: false,
            borderRadius: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FusionAppText(
                    text: value.toString(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: context.colorScheme.iconDefault,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          itemBuilder: (BuildContext context, int item, bool isSelected) {
            return FusionAppText(
              text: item.toString(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected ? context.colorScheme.primary : context.colorScheme.textPrimary,
              ),
            );
          },
          onSelected: (int index) {
            onChanged(items[index]);
          },
        ),
      ],
    );
  }
}
