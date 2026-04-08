import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../projects/viewmodel/building_page_viewmodel.dart';
import '../viewmodel/add_speaker_view_model.dart';
import 'widgets/properties_and_filter_section.dart';
import 'widgets/speaker_lists.dart';

class SpeakerSelectionPopup extends StatefulWidget {
  final bool isFromBuildingPage;
  final String? zoneId;
  final String? subZoneId;
  const SpeakerSelectionPopup({
    super.key,
    required this.isFromBuildingPage,
    this.zoneId,
    this.subZoneId,
  });

  @override
  State<SpeakerSelectionPopup> createState() => SpeakerSelectionPopupState();
}

class SpeakerSelectionPopupState extends State<SpeakerSelectionPopup> {
  final TextEditingController searchController = TextEditingController();

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
  }

  void onClose() {
    final int totalNonPlacedSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea().length;
    context.read<BuildingPageViewModel>().setShouldPlaceNonPlacedSpeakers(totalNonPlacedSpeakers > 0);
  }

  @override
  void dispose() {
    onClose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.isFromBuildingPage || widget.zoneId != null,
      'zoneId must be provided when not coming from Building Page',
    );

    return BlocProvider<SpeakerSelectionViewModel>(
      create: (BuildContext context) {
        return SpeakerSelectionViewModel()..init(
          isFromBuilding: widget.isFromBuildingPage,
          zoneId: widget.zoneId,
          subZoneId: widget.subZoneId,
        );
      },
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: "Select Speaker",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
                SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, "close_dropdown_button"),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(LucideIcons.x200, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(child: SpeakerListeningAreaProperties()),
                  const SizedBox(width: 8),
                  Expanded(child: ProductQuerySpeakerList(searchController: searchController)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
