import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/product_query/product_query_model.dart';
import 'package:fusion_lib/models/project_entities/listening_area_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../product_query/presentation/pages/product_query.dart';
import 'listening_area_dropdown_widget.dart';

/// Common reusable popup menu widget for adding a circuit (speaker group)
class AddSpeakersMenu extends StatefulWidget {
  final String zoneId;
  final String? subZoneId;
  final VoidCallback? onSpeakerAdded;

  const AddSpeakersMenu({
    super.key,
    required this.zoneId,
    this.subZoneId,
    this.onSpeakerAdded,
  });

  @override
  State<AddSpeakersMenu> createState() => _AddSpeakersMenuState();
}

class _AddSpeakersMenuState extends State<AddSpeakersMenu> {
  final TextEditingController numberOfSpeakers = TextEditingController(text: "1");

  String? selectedListeningAreaId;
  List<ListeningArea> listeningAreas = <ListeningArea>[];
  ProductQueryModel? speakerData;
  List<String> _selectedListeningAreaIds = <String>[];

  @override
  void initState() {
    super.initState();

    // if (widget.subZoneId != null) {
    //   listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: widget.subZoneId!);
    // } else {
    //   listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: widget.zoneId);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      tooltip: "Add Speakers",
      onCanceled: () {
        /// Clear selections when menu is closed without adding
        speakerData = null;
        _selectedListeningAreaIds.clear();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        maxHeight: 550,
        maxWidth: 300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Theme.of(context).colorScheme.white,
      menuPadding: EdgeInsets.zero,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<dynamic>>[
          PopupMenuItem<dynamic>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 300,
              constraints: const BoxConstraints(
                maxHeight: 520,
                maxWidth: 300,
              ),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setMenuState) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12, bottom: 12, top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          /// ---- Speaker Selection ----
                          ...ProductAPI.getSpeakerProducts().map(
                            (ProductQueryModel item) => InkWell(
                              onTap: () {
                                setMenuState(() {
                                  speakerData = item;
                                });
                              },
                              child: SemanticHelper.container(
                                testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_${item.sku}"),
                                child: Container(
                                  height: 30,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: speakerData?.sku == item.sku ? Colors.black : Theme.of(context).colorScheme.grey,
                                      width: 1,
                                    ),
                                    color: speakerData?.sku == item.sku ? Theme.of(context).colorScheme.grey : null,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      FusionImage.asset(
                                        item.image.isNotEmpty ? item.image : '',
                                        height: 14,
                                        width: 14,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FusionAppText(
                                          text: item.name,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            fontWeight: speakerData?.sku == item.sku ? FontWeight.w600 : null,
                                          ),
                                        ),
                                      ),
                                      if (speakerData?.sku == item.sku)
                                        const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// ---- Speakers count ----
                          FusionAppText(
                            text: "Speakers count",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // todo change it to + and - button
                          SemanticHelper.formControl(
                            testId: SemanticHelper.createTestId(SemanticTypes.textInput, "speakers_count_field"),
                            child: FusionTextField(
                              controller: numberOfSpeakers,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                              hintText: "Enter zone name",
                              decoration: FusionInputDecoration.fusionDense(
                                colorScheme: Theme.of(context).colorScheme,
                                hintText: 'Enter zone name',
                              ),
                              onChanged: (String value) {
                                final int count = int.tryParse(value) ?? 1;
                                if (count < 1 || count > 25) {
                                  setMenuState(() {
                                    numberOfSpeakers.text = '1';
                                  });
                                  FusionToast.error(
                                    context,
                                    message: "Count should be between 1 and 25",
                                  );
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// ---- Location ----
                          FusionAppText(
                            text: "Select Listening Area",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                              builder: (BuildContext context, ProjectViewModelState state) {
                                if (widget.subZoneId != null) {
                                  listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: widget.subZoneId!);
                                } else {
                                  listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: widget.zoneId);
                                }
                                return ListeningAreaDropdownWidget(
                                  listeningAreas: listeningAreas,
                                  selectedListeningAreaIds: _selectedListeningAreaIds,
                                  onSelectionChanged: (List<String> selectedIds, String floorId) {
                                    /// Add listening area to zone/subzone if not already added
                                    if (widget.subZoneId != null) {
                                      serviceLocator<ProjectViewModel>().addListeningAreaToSubZone(
                                        areaId: selectedIds.first,
                                        subZoneId: widget.subZoneId!,
                                      );
                                    } else {
                                      serviceLocator<ProjectViewModel>().addListeningAreaToZone(
                                        listeningAreaId: selectedIds.first,
                                        zoneId: widget.zoneId,
                                      );
                                    }

                                    _selectedListeningAreaIds = selectedIds;
                                    setMenuState(() {});
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Flexible(
                                child: FusionOutlinedButton(
                                  width: double.infinity,
                                  label: "Cancel",
                                  semanticsId: "add_speakers_cancel_button",
                                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    // remove speakerData
                                    speakerData = null;

                                    _selectedListeningAreaIds.clear();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "add_speakers_save_button"),
                                  child: FusionButton(
                                    width: double.infinity,
                                    textStyle: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                                    label: "Save",
                                    isActive: speakerData != null && _selectedListeningAreaIds.isNotEmpty,
                                    onTap: () {
                                      if (speakerData != null && _selectedListeningAreaIds.isNotEmpty) {
                                        serviceLocator<ProjectViewModel>().createCircuitWithSpeakers(
                                          speakerData: speakerData!,
                                          listeningAreaId: _selectedListeningAreaIds.first,
                                          speakerCount: int.tryParse(numberOfSpeakers.text) ?? 1,
                                          zoneId: widget.zoneId,
                                          subZoneId: widget.subZoneId,
                                          isFromBuildingPage: false,
                                          circuitName: "${speakerData!.name} Circuit",
                                        );
                                        FusionToast.success(
                                          context,
                                          message: "Speakers added to circuit successfully",
                                        );
                                        if (widget.onSpeakerAdded != null) {
                                          widget.onSpeakerAdded!();
                                        }
                                      }
                                      speakerData = null;
                                      Navigator.pop(context);
                                      numberOfSpeakers.text = '1';
                                      _selectedListeningAreaIds.clear();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ];
      },
      child: Row(
        children: <Widget>[
          const Icon(Icons.add, size: 10, color: Colors.black87),
          const SizedBox(width: 4),
          FusionAppText(
            text: "Speaker",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
