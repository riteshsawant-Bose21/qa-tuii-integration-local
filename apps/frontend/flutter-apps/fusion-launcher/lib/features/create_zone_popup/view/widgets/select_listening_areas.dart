part of '../create_zone_popup.dart';

Widget _buildListeningAreaSelectionSection(
  BuildContext rootContextFromParent, {
  int? subZoneIndex,
}) {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  String? zoneName(String areaId) {
    String? zoneName = projectViewModel.getZonesForListeningArea(areaId: areaId)?.name;
    if (zoneName == null || zoneName.trim().isEmpty) {
      zoneName = projectViewModel.getSubZoneForListeningArea(areaId: areaId)?.name;
    }
    return zoneName;
  }

  final CreateZoneViewModel createZoneViewModel = rootContextFromParent.read<CreateZoneViewModel>();

  void onListeningAreaTap(bool isAlreadySelected, ListeningArea area, StateSetter setPopupState) {
    final bool isCreatingSubZonesAlongSide = createZoneViewModel.isCreatingSubZonesAlongSide;

    if (isCreatingSubZonesAlongSide) {
      createZoneViewModel.updateSubzoneListeningArea(subZoneIndex!, area, isAlreadySelected);
    } else {
      createZoneViewModel.updateZoneListeningArea(area, isAlreadySelected);
    }
    setPopupState(() {});
  }

  return FusionArrowPopup(
    semanticId: 'select_listening_areas',
    showArrow: false,
    blurAmount: 0,
    backgroundColor: rootContextFromParent.colorScheme.elevation1,
    content: StatefulBuilder(
      builder: (BuildContext context, StateSetter setPopupState) {
        final List<ListeningArea> allListeningAreas = context.watch<ProjectViewModel>().getAllListeningAreas();

        return SizedBox(
          width: 280,
          child: BlocProvider<CreateZoneViewModel>.value(
            value: createZoneViewModel,
            child: BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
              builder: (BuildContext context, CreateZoneViewModelState state) {
                final bool isCreatingSubZonesAlongSide = createZoneViewModel.isCreatingSubZonesAlongSide;

                final bool isFromBuildingPage = rootContextFromParent.read<CreateZoneViewModel>().isFromBuildingPage;

                return SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_container"),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12).copyWith(top: 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: FusionAppText(
                                text: 'Select Listening Areas',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SemanticHelper.button(
                              testId: SemanticHelper.createTestId(SemanticTypes.button, "select_listening_areas_close_button"),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: Navigator.of(context).pop,
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(LucideIcons.x200, size: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 0.5, height: 0),

                      /// Scrollable list of listening areas
                      Flexible(
                        child: Builder(
                          builder: (BuildContext context) {
                            if (allListeningAreas.isNotEmpty) {
                              return SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  children: <Widget>[
                                    ...List<Widget>.generate(
                                      allListeningAreas.length,
                                      (int index) {
                                        final ListeningArea area = allListeningAreas[index];
                                        final FloorModel? floorName = projectViewModel.getFloorForListeningArea(areaId: area.id);

                                        /// Get available areas for the current zone/sub-zone
                                        final List<ListeningArea> availableListeningAreas = projectViewModel.getAvailableListeningAreasForZone();

                                        final bool isListeningAreaSelected = createZoneViewModel.isListeningAreaSelected(area.id);

                                        final bool isAvailable = availableListeningAreas.any((ListeningArea a) => a.id == area.id);

                                        // Check availability for this zone/subzone
                                        late bool isAvailableToSelectOrDeselect;
                                        if (isCreatingSubZonesAlongSide) {
                                          isAvailableToSelectOrDeselect = createZoneViewModel.isListeningAreaSelectedForSubzone(subZoneIndex!, area.id);
                                        } else {
                                          isAvailableToSelectOrDeselect = createZoneViewModel.isListeningAreaSelectedForZone(area.id);
                                        }

                                        return GestureDetector(
                                          onTap: isAvailable ? () => onListeningAreaTap(isListeningAreaSelected, area, setPopupState) : null,
                                          child: SemanticHelper.container(
                                            testId: SemanticHelper.createTestId(SemanticTypes.container, "select_listening_areas_item_$index"),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              color: isAvailable ? Colors.transparent : Colors.grey.withOpacity(0.05),
                                              child: Row(
                                                children: <Widget>[
                                                  GestureDetector(
                                                    onTap:
                                                        isAvailable
                                                            ? () => onListeningAreaTap(
                                                              isListeningAreaSelected,
                                                              area,
                                                              setPopupState,
                                                            )
                                                            : null,
                                                    child: SemanticHelper.button(
                                                      testId: SemanticHelper.createTestId(
                                                        SemanticTypes.button,
                                                        "select_listening_areas_checkbox_$index",
                                                      ),
                                                      child: Icon(
                                                        (isAvailable ? isListeningAreaSelected : true) ? Icons.check_box : Icons.check_box_outline_blank,
                                                        size: 14,
                                                        color: isAvailable && isAvailableToSelectOrDeselect ? context.colorScheme.onSurface : Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),

                                                  /// Area and zone names
                                                  Expanded(
                                                    child: FusionAppText(
                                                      semanticId: "listening_area_name",
                                                      text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Area',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 10,
                                                        color:
                                                            isAvailable && isAvailableToSelectOrDeselect
                                                                ? Theme.of(context).textTheme.bodySmall?.color
                                                                : Colors.grey[400],
                                                      ),
                                                    ),
                                                  ),
                                                  /// Zone name
                                                  FusionAppText(
                                                    semanticId: "listening_area_zone_name",
                                                    text: zoneName(area.id) ?? "No zone",
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontSize: 9,
                                                      color: isAvailable ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outline,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: FusionAppText(
                                  text: "No locations available.",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      if (!isFromBuildingPage) ...<Widget>[
                        const SizedBox(height: 10),
                        const Divider(thickness: 0.5, height: 0),

                        // / Create New Location Section
                        _CreateNewListeningAreaWidget(
                          onListeningAreaCreated: (ListeningArea value) {
                            onListeningAreaTap(false, value, setPopupState);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
    child: Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rootContextFromParent.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rootContextFromParent.colorScheme.strokeLight, width: 1),
      ),
      child: BlocProvider<CreateZoneViewModel>.value(
        value: createZoneViewModel,
        child: BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
          builder: (BuildContext context, CreateZoneViewModelState state) {
            final bool isCreatingSubZonesAlongSide = createZoneViewModel.isCreatingSubZonesAlongSide;

            final int totalListeningAreasSelected =
                isCreatingSubZonesAlongSide
                    ? createZoneViewModel.totalLiseningAreasSelectedForSubzone(subZoneIndex!)
                    : createZoneViewModel.totalLiseningAreasSelectedForZone();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      semanticId: "listening_areas_dropdown",
                      text: totalListeningAreasSelected == 0 ? 'Select listening areas' : '$totalListeningAreasSelected listening areas selected',
                      style: context.textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        color: totalListeningAreasSelected == 0 ? context.colorScheme.onSurface.withAlpha(155) : context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
