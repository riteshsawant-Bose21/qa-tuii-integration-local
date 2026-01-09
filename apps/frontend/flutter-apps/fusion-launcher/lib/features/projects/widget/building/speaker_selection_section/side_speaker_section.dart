import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';
import 'parts/select_speaker_popup.dart';

class SpeakerSelectionWidget extends StatefulWidget {
  const SpeakerSelectionWidget({super.key});

  @override
  State<SpeakerSelectionWidget> createState() => _SpeakerSelectionWidgetState();
}

class _SpeakerSelectionWidgetState extends State<SpeakerSelectionWidget> {
  bool _isExpanded = true; // intialized to true

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
        final ListeningArea? currentSelectedListeningAreaId = projectViewModel.getCurrentSelectedListeningArea();

        if (currentSelectedListeningAreaId == null || projectViewModel.currentToolbarMode == ToolbarMode.system) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: "SPEAKERS",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ),

                    BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                      builder: (BuildContext context, ProjectViewModelState state) {
                        final String? areaId = projectViewModel.currentSelectedListeningAreaId;
                        if (areaId == null) return const SizedBox.shrink();

                        final List<HardwareComponent> allHardware = projectViewModel.getHardwareForListeningArea(listeningAreaId: areaId);
                        final List<Speaker> speakers = allHardware.whereType<Speaker>().where((Speaker element) => element.pos == null).toList();

                        if (speakers.isNotEmpty) return const SizedBox.shrink();

                        return PopupMenuButton<String>(
                          color: Colors.transparent,
                          shadowColor: Colors.transparent,
                          tooltip: 'Add speakers',
                          padding: EdgeInsets.zero,
                          menuPadding: EdgeInsets.zero,
                          clipBehavior: Clip.none,
                          offset: const Offset(45, 0),
                          constraints: const BoxConstraints(minWidth: 1000),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              LucideIcons.plus200,
                              size: 14,
                              color: Theme.of(context).colorScheme.fusionTextViewColor,
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                enabled: false,
                                padding: EdgeInsets.zero,
                                child: Theme(
                                  data: ThemeData.dark(),
                                  child: const SpeakerQueryPopup(),
                                ),
                              ),
                            ];
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  final String? listeningAreaId = projectViewModel.currentSelectedListeningAreaId;
                  if (listeningAreaId == null) return const SizedBox.shrink();

                  final ListeningArea listeningArea = projectViewModel.getListeningArea(areaId: listeningAreaId);

                  final List<HardwareComponent> allHardware = projectViewModel.getHardwareForListeningArea(listeningAreaId: listeningAreaId);
                  final List<Speaker> speakers = allHardware.whereType<Speaker>().where((Speaker element) => element.pos == null).toList();

                  if (speakers.isEmpty) return const SizedBox.shrink();

                  final bool shouldPlaceNonPlacedSpeakers = projectViewModel.shouldPlaceNonPlacedSpeakers;

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Row(
                            children: <Widget>[
                              Icon(
                                _isExpanded ? LucideIcons.chevronDown200 : LucideIcons.chevronRight200,
                                size: 16,
                                color: context.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              FusionAppText(
                                text: listeningArea.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isExpanded && speakers.isNotEmpty) ...<Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  projectViewModel.shouldPlaceNonPlacedSpeakers = !projectViewModel.shouldPlaceNonPlacedSpeakers;
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: shouldPlaceNonPlacedSpeakers ? context.colorScheme.surfaceDim : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Image.asset(speakers.first.assetImagePath),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FusionAppText(
                                          text: speakers.first.name,
                                          style: context.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (speakers.isNotEmpty) ...<Widget>[
                                        // edit icon
                                        PopupMenuButton<String>(
                                          color: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          tooltip: 'Edit speakers',
                                          padding: EdgeInsets.zero,
                                          menuPadding: EdgeInsets.zero,
                                          clipBehavior: Clip.none,
                                          offset: const Offset(45, 0),
                                          constraints: const BoxConstraints(minWidth: 1000),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: Icon(
                                              LucideIcons.pencil200,
                                              size: 12,
                                              color: context.colorScheme.onSurface,
                                            ),
                                          ),
                                          itemBuilder: (BuildContext context) {
                                            return <PopupMenuEntry<String>>[
                                              PopupMenuItem<String>(
                                                enabled: false,
                                                padding: EdgeInsets.zero,
                                                child: Theme(
                                                  data: ThemeData.dark(),
                                                  child: const SpeakerQueryPopup(),
                                                ),
                                              ),
                                            ];
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                              // Total speakers
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: FusionAppText(
                                        text: 'Quantity',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
                                          projectViewModel.decreaseQty();
                                        },
                                        child: Icon(
                                          LucideIcons.minus200,
                                          size: 12,
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FusionAppText(
                                      text: "${speakers.length}",
                                      style: context.textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
                                          projectViewModel.increaseQty();
                                        },
                                        child: Icon(
                                          LucideIcons.plus200,
                                          size: 12,
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Total speakers
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: FusionAppText(
                                        text: 'Not placed speakers',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.surfaceDim,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),
                                    FusionAppText(
                                      text: "${speakers.length}",
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.surfaceDim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
