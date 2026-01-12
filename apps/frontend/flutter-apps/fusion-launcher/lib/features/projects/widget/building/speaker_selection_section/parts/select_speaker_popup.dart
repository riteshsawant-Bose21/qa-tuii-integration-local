import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../view_model/view_model.dart';
import 'properties_and_filter_section.dart';
import 'speaker_lists.dart';

class SpeakerQueryPopup extends StatefulWidget {
  final bool isFromBuildingPage;
  final String? zoneOrSubzoneId;
  const SpeakerQueryPopup({super.key, required this.isFromBuildingPage, this.zoneOrSubzoneId});

  @override
  State<SpeakerQueryPopup> createState() => SpeakerQueryPopupState();
}

class SpeakerQueryPopupState extends State<SpeakerQueryPopup> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.isFromBuildingPage || widget.zoneOrSubzoneId != null,
      'Either zone or subzone id should be provided',
    );

    return BlocProvider<SpeakerSelectionViewModel>(
      create: (BuildContext context) {
        return SpeakerSelectionViewModel()..init(
          isFromBuilding: widget.isFromBuildingPage,
          zoneOrSubzoneId: widget.zoneOrSubzoneId,
        );
      },
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ProductQuerySpeakerList(searchController: searchController),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SpeakerListeningAreaProperties()),
          ],
        ),
      ),
    );
  }
}
