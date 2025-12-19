import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/media_files/state/media_files_state.dart';
import 'package:fusion_launcher/features/media_files/viewModel/media_files_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:intl/intl.dart';

// ==================== Models ====================
class MediaFileModel {
  final String id;
  final String name;
  final String path;
  final int size;
  final Duration length;
  final DateTime date;

  MediaFileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.length,
    required this.date,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedLength {
    final int minutes = length.inMinutes;
    final int seconds = length.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return DateFormat('M/d/yyyy; HH:mm').format(date);
  }
}

class ConfigurationMediaFilesPage extends StatelessWidget {
  const ConfigurationMediaFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _TopBar(),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(flex: 3, child: _MediaTable()),
              const VerticalDivider(width: 1),
              const Expanded(flex: 2, child: _PreviewPanel()),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final MediaFilesViewModel cubit = context.read<MediaFilesViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        GestureDetector(
          onTap: cubit.pickFiles,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.upload, size: 18),
                const SizedBox(
                  width: 10,
                ),
                FusionAppText(
                  text: "Upload",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaFilesViewModel, ConfigurationMediaFilesState>(
      builder: (BuildContext context, ConfigurationMediaFilesState state) {
        return Column(
          children: <Widget>[
            const _TableHeader(),
            const Divider(height: 1),

            Expanded(
              child: ListView.builder(
                itemCount: state.files.length,
                itemBuilder: (BuildContext context, int index) {
                  final MediaFileModel file = state.files[index];
                  final bool isSelected = index == state.selectedIndex;

                  return InkWell(
                    onTap: () => context.read<MediaFilesViewModel>().selectFile(index),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[200] : null,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.greyDark : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex: 4, child: Text(file.name)),
                          Expanded(flex: 2, child: Text(file.formattedSize)),
                          Expanded(flex: 2, child: Text(file.formattedLength)),
                          Expanded(flex: 3, child: Text(file.formattedDate)),

                          GestureDetector(onTap: () {}, child: const Icon(Icons.delete_outline, size: 18)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 20, right: 0, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: FusionAppText(
              text: "File Name",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: FusionAppText(
              text: "Size",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: FusionAppText(
              text: "Length",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: FusionAppText(
              text: "Date",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaFilesViewModel, ConfigurationMediaFilesState>(
      builder: (BuildContext context, ConfigurationMediaFilesState state) {
        final MediaFileModel? selectedFile = state.selectedFile;
        if (selectedFile == null) {
          return const Center(child: Text('Select a file'));
        }

        final MediaFilesViewModel cubit = context.read<MediaFilesViewModel>();
        final MediaFileModel file = selectedFile;

        final ThemeData theme = Theme.of(context);
        final ColorScheme colors = theme.colorScheme;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: 'Preview',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.dividerColor,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    /// CONTROLS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FusionAppText(
                          text: file.name.split('.').first,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _CircleButton(
                              icon: Icons.fast_rewind_outlined,
                              borderColor: colors.greyDark,
                              onTap: cubit.playPrevious,
                            ),
                            _CircleButton(
                              icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                              borderColor: colors.greyDark,
                              onTap: cubit.playPause,
                            ),

                            _CircleButton(
                              icon: Icons.fast_forward_outlined,
                              borderColor: colors.greyDark,
                              onTap: cubit.playNext,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(_fmt(state.currentPosition)),
                        Text(file.formattedLength),
                      ],
                    ),

                    /// SLIDER
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 4),
                        trackHeight: 1,
                        thumbColor: Theme.of(context).colorScheme.black,
                      ),
                      child: Slider(
                        value: state.currentPosition.inSeconds.toDouble(),
                        padding: EdgeInsets.zero,
                        activeColor: Theme.of(context).colorScheme.greyDark,
                        inactiveColor: Theme.of(context).colorScheme.grey,
                        min: 0,
                        max: file.length.inSeconds > 0 ? file.length.inSeconds.toDouble() : 1,
                        divisions: 100,

                        onChanged: (double v) {
                          cubit.seek(Duration(seconds: v.toInt()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(Duration d) {
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Extracted purely for reuse — no UI change
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color borderColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 22),
      ),
    );
  }
}
