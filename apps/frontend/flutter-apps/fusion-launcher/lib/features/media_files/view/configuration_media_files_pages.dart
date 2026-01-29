import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/media_files/state/media_files_state.dart';
import 'package:fusion_launcher/features/media_files/viewModel/media_files_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class ConfigurationMediaFilesPage extends StatelessWidget {
  const ConfigurationMediaFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _TopBar(),
        BlocBuilder<MediaFilesViewModel, ConfigurationMediaFilesState>(
          builder: (BuildContext context, ConfigurationMediaFilesState state) {
            if (state.errorMessage != null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.error, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FusionAppText(
                        text: state.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "close_error_message"),
                      child: GestureDetector(
                        onTap: () => context.read<MediaFilesViewModel>().clearError(),
                        child: Icon(Icons.close, color: Colors.red.shade700, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
        SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, "upload_media_files"),
          child: GestureDetector(
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
        ),
      ],
    );
  }
}

class _MediaTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return BlocBuilder<MediaFilesViewModel, ConfigurationMediaFilesState>(
          builder: (BuildContext context, ConfigurationMediaFilesState state) {
            return Column(
              children: <Widget>[
                const _TableHeader(),
                const Divider(height: 1),

                Expanded(
                  child:
                      context.read<MediaFilesViewModel>().getAllFiles().isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.audio_file_outlined,
                                  size: 42,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                FusionAppText(
                                  text: "Add files to view media",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: context.read<MediaFilesViewModel>().getAllFiles().length,
                            itemBuilder: (BuildContext context, int index) {
                              final MediaFileModel file = context.read<MediaFilesViewModel>().getAllFiles()[index];
                              final bool isSelected = state.selectedMediaFileId == file.id;

                              return SemanticHelper.button(
                                testId: SemanticHelper.createTestId(SemanticTypes.button, "media_file_$index"),
                                child: InkWell(
                                  onTap: () => context.read<MediaFilesViewModel>().selectFile(file),
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
                                        Expanded(flex: 2, child: Text(file.size.toString())),
                                        Expanded(flex: 2, child: Text(file.length.toString())),
                                        Expanded(flex: 3, child: Text(file.date.toString())),

                                        GestureDetector(
                                          onTap: () {
                                            context.read<MediaFilesViewModel>().deleteMediaFile(file.id);
                                          },
                                          child: const Icon(Icons.delete_outline, size: 18),
                                        ),
                                      ],
                                    ),
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
        final MediaFileModel? selectedFile = context.read<MediaFilesViewModel>().getSelectedFile();
        if (selectedFile == null) {
          return Center(
            child: FusionAppText(
              text: "Select a media file to preview",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
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
                            SemanticHelper.button(
                              testId: SemanticHelper.createTestId(SemanticTypes.button, "play_previous"),
                              child: _CircleButton(
                                icon: Icons.fast_rewind_outlined,
                                borderColor: colors.greyDark,
                                onTap: cubit.playPrevious,
                              ),
                            ),
                            SemanticHelper.button(
                              testId: SemanticHelper.createTestId(SemanticTypes.button, "play_pause"),
                              child: _CircleButton(
                                icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                                borderColor: colors.greyDark,
                                onTap: cubit.playPause,
                              ),
                            ),

                            SemanticHelper.button(
                              testId: SemanticHelper.createTestId(SemanticTypes.button, "play_next"),
                              child: _CircleButton(
                                icon: Icons.fast_forward_outlined,
                                borderColor: colors.greyDark,
                                onTap: cubit.playNext,
                              ),
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
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "media_seek_slider"),
                      child: SliderTheme(
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
                          max: file.length!.inSeconds > 0 ? file.length!.inSeconds.toDouble() : 1,
                          divisions: 100,

                          onChanged: (double v) {
                            cubit.seek(Duration(seconds: v.toInt()));
                          },
                        ),
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
