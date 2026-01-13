import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/view_model/view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/service_locator.dart';
import '../../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../widgets/drop_down.dart';

class SelectListeningArea extends StatelessWidget {
  final SpeakerSelectionViewModel speakerSelectionViewModel;

  const SelectListeningArea({super.key, required this.speakerSelectionViewModel});

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      blurAmount: 0,
      showArrow: false,
      backgroundColor: const Color(0xFF292826),
      barrierColor: Colors.transparent,
      content: SizedBox(
        width: 250,
        child: BlocProvider<SpeakerSelectionViewModel>.value(
          value: speakerSelectionViewModel,
          child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              final SpeakerSelectionViewModel speakerSelectionViewModel = context.watch<SpeakerSelectionViewModel>();

              final List<ListeningArea> listeningAreas = speakerSelectionViewModel.getListeningAreas();

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ...listeningAreas.map(
                      (ListeningArea area) {
                        return GestureDetector(
                          onTap: () {
                            context.read<SpeakerSelectionViewModel>().setListeningAreaForDropDown(area);
                            Navigator.of(context).pop();
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: FusionAppText(
                                      text: area.name,
                                      style: context.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(thickness: 0.5, height: 0),
                    _CreateNewListeningAreaWidget(
                      onListeningAreaCreated: (ListeningArea area) {
                        context.read<SpeakerSelectionViewModel>().setListeningAreaForDropDown(area);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      child: BlocProvider<SpeakerSelectionViewModel>.value(
        value: speakerSelectionViewModel,
        child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final SpeakerSelectionViewModel speakerSelectionViewModel = context.watch<SpeakerSelectionViewModel>();

            return Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.withValues(alpha: 0.05),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Builder(
                      builder: (BuildContext context) {
                        if (speakerSelectionViewModel.selectedListeningArea != null) {
                          return FusionAppText(
                            text: speakerSelectionViewModel.selectedListeningArea!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }

                        return FusionAppText(
                          text: "Select listening area",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                          ),
                        );
                      },
                    ),
                  ),
                  // arrow icon
                  Icon(
                    LucideIcons.chevronDown200,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CreateNewListeningAreaWidget extends StatefulWidget {
  final ValueChanged<ListeningArea> onListeningAreaCreated;

  const _CreateNewListeningAreaWidget({required this.onListeningAreaCreated});

  @override
  State<_CreateNewListeningAreaWidget> createState() => __CreateNewListeningAreaWidgetState();
}

class __CreateNewListeningAreaWidgetState extends State<_CreateNewListeningAreaWidget> {
  final TextEditingController listeningAreaNameController = TextEditingController();
  bool _isExpanded = false;
  FloorModel? _selectedFloor;

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  void _addNewLocationToFloor() {
    if (listeningAreaNameController.text.trim().isEmpty || _selectedFloor == null) {
      FusionToast.error(context, message: "Please enter location name and select a floor");
      return;
    }

    final String floorId = _selectedFloor!.id;
    final String locationName = listeningAreaNameController.text.trim();

    final ListeningArea newListeningArea = ListeningArea(
      name: locationName,
      vertices: <Offset>[
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(0, 100),
      ],
    );

    final String? zoneId = context.read<SpeakerSelectionViewModel>().zoneId;
    final String? subZoneId = context.read<SpeakerSelectionViewModel>().subZoneId;
    serviceLocator<ProjectViewModel>().addListeningArea(area: newListeningArea, floorId: floorId);

    if (subZoneId != null) {
      projectViewModel.addListeningAreaToSubZone(subZoneId: subZoneId, areaId: newListeningArea.id);
    } else if (zoneId != null) {
      projectViewModel.addListeningAreaToZone(zoneId: zoneId, listeningAreaId: newListeningArea.id);
    }

    FusionToast.success(context, message: "Listening area '${newListeningArea.name}' created");
    widget.onListeningAreaCreated(newListeningArea);

    // clear inputs
    listeningAreaNameController.clear();
    _selectedFloor = null;
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Header
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: "Create new location",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        /// Expanded form
        if (_isExpanded) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Floor label
                FusionAppText(
                  text: "Floor",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                /// Floor dropdown
                BuildingPageDronDown<FloorModel>(
                  value: _selectedFloor,
                  items: serviceLocator<ProjectViewModel>().getAllFloors(),
                  onSelect: (FloorModel selectedValue) {
                    setState(() {
                      _selectedFloor = selectedValue;
                    });
                  },
                  labelBuilder: (FloorModel option) {
                    return FusionAppText(
                      text: option.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
                const SizedBox(height: 12),

                /// Location Name
                FusionAppText(
                  text: "Location Name",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                TextFormField(
                  controller: listeningAreaNameController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Enter location name',
                    hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    hoverColor: Colors.transparent,
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    fillColor: context.colorScheme.surface,
                  ),
                  style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                ),
                const SizedBox(height: 12),

                /// Add Button
                Align(
                  alignment: Alignment.centerRight,

                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _addNewLocationToFloor,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FusionDarkColorPallette.green20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FusionAppText(
                          text: "Save",
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
