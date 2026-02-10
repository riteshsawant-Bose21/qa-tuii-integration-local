import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../view_model/add_speaker_view_model.dart';
import 'properties_and_filter_section.dart';
import 'speaker_lists.dart';

class SpeakerQueryPopup extends StatefulWidget {
  final bool isFromBuildingPage;
  final String? zoneId;
  final String? subZoneId;
  const SpeakerQueryPopup({
    super.key,
    required this.isFromBuildingPage,
    this.zoneId,
    this.subZoneId,
  });

  @override
  State<SpeakerQueryPopup> createState() => SpeakerQueryPopupState();
}

class SpeakerQueryPopupState extends State<SpeakerQueryPopup> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    projectViewModel.setShouldPlaceNonPlacedSpeakers(false);
  }

  @override
  void dispose() {
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: ProductQuerySpeakerList(searchController: searchController)),
            const SizedBox(width: 8),
            const Expanded(child: SpeakerListeningAreaProperties()),
          ],
        ),
      ),
    );
  }
}
