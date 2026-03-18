import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
        final MessagePlayerConfigCubit messagePlayerConfigCubit = context.read<MessagePlayerConfigCubit>();
        final MediaFileModel? mediaFile = messagePlayerConfigCubit.getMediaFileForSelectedMessage();

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
              /// Message Name
              _MessageNameField(
                initialValue: selectedMessage.name,
                onChanged: (String value) {
                  context.read<MessagePlayerConfigCubit>().updateMessageName(value);
                },
              ),

              const SizedBox(height: 20),

              /// Audio File
              _AudioFileSection(
                selectedMessage: selectedMessage,
                state: state,
              ),

              /// Audio Player (only show if audio file is selected)
              if (messagePlayerConfigCubit.hasMediaAssignedToSelectedMessage() && mediaFile != null) ...<Widget>[
                const SizedBox(height: 16),
                _AudioPlayerWidget(state: state),

                const SizedBox(height: 16),

                /// Gain Control
                _GainControlSection(
                  gain: selectedMessage.gain,
                  onChanged: (double value) {
                    context.read<MessagePlayerConfigCubit>().updateGain(value);
                  },
                ),
                const SizedBox(height: 20),

                /// Repeat Settings
                _RepeatSettingsSection(
                  repeat: selectedMessage.repeat,
                  repeatCount: selectedMessage.repeatCount,
                  intervalSeconds: selectedMessage.repeatIntervalSeconds,
                ),
              ],
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
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _MessageNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the value changed externally (e.g., selecting different message)
    // and the field is not currently focused
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  void _onFocusChange() {
    // When focus is lost, update the name if it changed
    if (!_focusNode.hasFocus && _controller.text != widget.initialValue) {
      widget.onChanged(_controller.text);
    }
  }

  void _onSubmitted(String value) {
    if (value != widget.initialValue) {
      widget.onChanged(value);
    }
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
          height: 40,
          width: 400,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: context.textTheme.b3Regular,
            onSubmitted: _onSubmitted,
            decoration: InputDecoration(
              hintText: 'Enter message Name',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textPlaceholder,
              ),
              fillColor: context.colorScheme.elevation1,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        _AudioFileDropdown(selectedMessage: selectedMessage),
      ],
    );
  }
}

/// Enum for audio file dropdown options
enum _AudioFileOption { selectAudioFile, uploadAudioFile }

class _AudioFileDropdown extends StatefulWidget {
  final MessageModel selectedMessage;

  const _AudioFileDropdown({required this.selectedMessage});

  @override
  State<_AudioFileDropdown> createState() => _AudioFileDropdownState();
}

class _AudioFileDropdownState extends State<_AudioFileDropdown> {
  final GlobalKey _audioFilesPopupKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();
    final MediaFileModel? mediaFile = cubit.getMediaFileForSelectedMessage();
    final String? audioFileName = mediaFile?.name;

    return Stack(
      children: <Widget>[
        // Main popup menu (always visible as trigger)
        _buildMainPopup(context, cubit, audioFileName),
        // Hidden audio files popup - we'll trigger it programmatically
        Positioned(
          left: 0,
          right: 0,
          child: Opacity(
            opacity: 0,
            child: IgnorePointer(
              child: SizedBox(
                height: 0,
                child: _buildAudioFilesListPopup(context, cubit, audioFileName),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainPopup(BuildContext context, MessagePlayerConfigCubit cubit, String? audioFileName) {
    return FusionPopupMenu<_AudioFileOption>(
      items: const <_AudioFileOption>[
        _AudioFileOption.selectAudioFile,
        _AudioFileOption.uploadAudioFile,
      ],
      tooltip: 'Audio file options',
      matchChildWidth: true,
      semanticsId: 'audio_file_options_popup',
      popupOffset: const Offset(0, 6),
      onSelected: (_AudioFileOption option) {
        if (option == _AudioFileOption.selectAudioFile) {
          final List<MediaFileModel> audioFiles = cubit.getAvailableAudioFiles();
          if (audioFiles.isEmpty) {
            FusionToast.error(context, message: 'No audio files available. Please upload an audio file first.');
            return;
          }
          // Show the audio files dialog after a short delay to let the main popup close
          Future<void>.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _showAudioFilesDialog(context, cubit);
            }
          });
        } else {
          _uploadAudioFile(context, cubit);
        }
      },
      itemBuilder: (BuildContext context, _AudioFileOption item) {
        return Row(
          children: <Widget>[
            Icon(
              item == _AudioFileOption.selectAudioFile ? LucideIcons.music : LucideIcons.upload,
              size: 18,
              color: context.colorScheme.textPrimary,
            ),
            const SizedBox(width: 12),
            FusionAppText(
              text: item == _AudioFileOption.selectAudioFile ? 'Select Audio File' : 'Upload Audio File',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.textPrimary,
              ),
            ),
          ],
        );
      },
      child: _buildTrigger(context, audioFileName),
    );
  }

  void _showAudioFilesDialog(BuildContext context, MessagePlayerConfigCubit cubit) {
    final List<MediaFileModel> audioFiles = cubit.getAvailableAudioFiles();
    final MediaFileModel? currentMediaFile = cubit.getMediaFileForSelectedMessage();
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Offset offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size size = renderBox?.size ?? Size.zero;

    showMenu<MediaFileModel>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        offset.dy + size.height + 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colorScheme.strokeLight, width: 1),
      ),
      color: context.colorScheme.elevation2,
      items:
          audioFiles.map((MediaFileModel file) {
            final bool isSelected = file.id == currentMediaFile?.id;
            return PopupMenuItem<MediaFileModel>(
              value: file,
              child: SizedBox(
                width: size.width - 32,
                child: Row(
                  children: <Widget>[
                    Icon(
                      LucideIcons.music,
                      size: 18,
                      color: isSelected ? context.colorScheme.primary : context.colorScheme.iconDefault,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FusionAppText(
                        text: file.name,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? context.colorScheme.primary : context.colorScheme.textPrimary,
                        ),
                        maxLine: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        LucideIcons.check,
                        size: 18,
                        color: context.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
    ).then((MediaFileModel? selectedFile) {
      if (selectedFile != null) {
        cubit.assignAudioFile(selectedFile.id);
      }
    });
  }

  Widget _buildAudioFilesListPopup(BuildContext context, MessagePlayerConfigCubit cubit, String? audioFileName) {
    final List<MediaFileModel> audioFiles = cubit.getAvailableAudioFiles();
    final MediaFileModel? currentMediaFile = cubit.getMediaFileForSelectedMessage();

    return FusionPopupMenu<MediaFileModel>(
      key: _audioFilesPopupKey,
      items: audioFiles,
      tooltip: 'Select audio file',
      semanticsId: 'audio_files_list_popup',
      popupOffset: const Offset(0, 8),
      onSelected: (MediaFileModel file) {
        cubit.assignAudioFile(file.id);
      },
      itemBuilder: (BuildContext context, MediaFileModel file) {
        final bool isSelected = file.id == currentMediaFile?.id;
        return Row(
          children: <Widget>[
            Icon(
              LucideIcons.music,
              size: 18,
              color: isSelected ? context.colorScheme.primary : context.colorScheme.iconDefault,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FusionAppText(
                text: file.name,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? context.colorScheme.primary : context.colorScheme.textPrimary,
                ),
                maxLine: 1,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: context.colorScheme.primary,
              ),
          ],
        );
      },
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildTrigger(BuildContext context, String? audioFileName) {
    return FusionContainer(
      raised: true,
      width: 400,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: audioFileName ?? 'Select Audio File',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: audioFileName != null ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
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
    );
  }

  Future<void> _uploadAudioFile(BuildContext context, MessagePlayerConfigCubit cubit) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile platformFile = result.files.first;
        if (platformFile.path != null) {
          final File file = File(platformFile.path!);
          await cubit.uploadAudioFile(file, fileName: platformFile.name);

          // After upload, get the newly added file and assign it
          final List<MediaFileModel> audioFiles = cubit.getAvailableAudioFiles();
          if (audioFiles.isNotEmpty) {
            final MediaFileModel newFile = audioFiles.last;
            cubit.assignAudioFile(newFile.id);
          }

          if (context.mounted) {
            FusionToast.success(context, message: 'Audio file uploaded successfully');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        FusionToast.error(context, message: 'Failed to upload audio file');
      }
    }
  }
}

class _AudioPlayerWidget extends StatelessWidget {
  final MessagePlayerConfigState state;

  const _AudioPlayerWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();
    final MediaFileModel? mediaFile = cubit.getMediaFileForSelectedMessage();

    if (mediaFile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// File name with play button
          Row(
            children: <Widget>[
              InkWell(
                onTap: () => cubit.togglePlayPause(),
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: context.colorScheme.iconWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FusionAppText(
                  text: mediaFile.name,
                  style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
                  maxLine: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: FusionAudioSlider(
              currentPosition: state.currentPosition,
              totalDuration: state.totalDuration,
              onSeek: (Duration duration) => cubit.seekTo(duration),
              activeColor: context.colorScheme.primary,
              inactiveColor: context.colorScheme.elevation4,
              textColor: context.colorScheme.textSecondary,
              timeTextStyle: context.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Icon(
              //   LucideIcons.volume2,
              //   size: 18,
              //   color: context.colorScheme.iconDefault,
              // ),
              // const SizedBox(width: 8),
              FusionAppText(
                text: 'Audio Gain Control',
                style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FusionAudioGainSlider(
            value: gain,
            onChanged: (double value) {
              context.read<MessagePlayerConfigCubit>().updateGain(value);
            },
            activeColor: context.colorScheme.primary,
            inactiveColor: context.colorScheme.elevation4,
            textColor: context.colorScheme.textSecondary,
          ),

          // _GainSlider(
          //   value: gain,
          //   onChanged: onChanged,
          // ),
        ],
      ),
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
            const SizedBox(width: 8),
            FusionAppText(text: 'Repeat', style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary)),
          ],
        ),

        if (repeat) ...<Widget>[
          const SizedBox(height: 16),

          // Times and Interval dropdowns
          Column(
            children: <Widget>[
              _DropdownField(
                label: 'Times (No.)',
                value: repeatCount,
                items: List<int>.generate(10, (int i) => i + 1),
                onChanged: (int value) => cubit.updateRepeatCount(value),
              ),
              const SizedBox(height: 20),
              _DropdownField(
                label: 'Interval (sec.)',
                value: intervalSeconds,
                items: <int>[1, 2, 3, 5, 10, 15, 30, 60],
                onChanged: (int value) => cubit.updateRepeatInterval(value),
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
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
          child: FusionAppText(
            text: label,
            style: context.textTheme.l1Medium,
          ),
        ),
        FusionPopupMenu<int>(
          semanticsId: '${label}_dropdown',
          items: items,
          popupOffset: const Offset(0, 6),
          onSelected: onChanged,
          matchChildWidth: true,
          itemBuilder: (BuildContext context, int item) {
            final bool isSelected = item == value;
            return FusionAppText(
              text: item.toString(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textPrimary,
              ),
            );
          },
          child: FusionContainer(
            color: context.colorScheme.elevation1,
            width: 53,
            height: 24,
            raised: true,
            borderRadius: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FusionAppText(text: value.toString(), style: context.textTheme.b3Regular),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: context.colorScheme.iconDefault,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
