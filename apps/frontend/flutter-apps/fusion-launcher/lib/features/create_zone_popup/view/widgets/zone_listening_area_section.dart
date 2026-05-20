part of '../create_zone_content.dart';

class _ZoneListeningAreaSection extends StatefulWidget {
  final int? subzoneIndex;
  final bool isFromBuildingPage;
  final void Function(bool isAdding)? onAddingAreaChanged; // ← replace notifier with callback

  const _ZoneListeningAreaSection({
    required this.subzoneIndex,
    this.isFromBuildingPage = false,
    this.onAddingAreaChanged,
  });

  @override
  State<_ZoneListeningAreaSection> createState() => _ZoneListeningAreaSectionState();
}

class _ZoneListeningAreaSectionState extends State<_ZoneListeningAreaSection> {
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();

  bool _isAddingArea = false;
  FloorModel? _selectedFloor;
  bool _isAddingNewFloor = false;

  final TextEditingController _areaNameCtrl = TextEditingController();
  final TextEditingController _newFloorNameCtrl = TextEditingController();

  bool get _isSubzone => widget.subzoneIndex != null;

  @override
  void initState() {
    super.initState();
    final List<FloorModel> floors = _projectViewModel.getAllFloors();
    if (floors.isNotEmpty) {
      _selectedFloor = floors.first;
    }
  }

  @override
  void dispose() {
    _areaNameCtrl.dispose();
    _newFloorNameCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────

  bool _isSelectedHere(CreateZoneViewModel vm, String areaId) {
    return _isSubzone ? vm.isListeningAreaSelectedForSubzone(widget.subzoneIndex!, areaId) : vm.isListeningAreaSelectedForZone(areaId);
  }

  void _toggleArea(CreateZoneViewModel vm, ListeningArea area) {
    final bool already = _isSelectedHere(vm, area.id);
    if (_isSubzone) {
      vm.updateSubzoneListeningArea(widget.subzoneIndex!, area, already);
    } else {
      vm.updateZoneListeningArea(area, already);
    }
    setState(() {});
  }

  int _selectedCount(CreateZoneViewModel vm) {
    return _isSubzone ? vm.totalLiseningAreasSelectedForSubzone(widget.subzoneIndex!) : vm.totalLiseningAreasSelectedForZone();
  }

  void _saveListeningArea(BuildContext context) {
    final CreateZoneViewModel vm = context.read<CreateZoneViewModel>();
    final String areaName = _areaNameCtrl.text.trim();

    if (areaName.isEmpty) {
      FusionToast.error(context, message: 'Please enter a listening area name');
      return;
    }

    FloorModel? floor = _selectedFloor;

    if (_isAddingNewFloor || _projectViewModel.getAllFloors().isEmpty) {
      final String floorName = _newFloorNameCtrl.text.trim();
      if (floorName.isEmpty) {
        FusionToast.error(context, message: 'Please enter a floor name');
        return;
      }
      final FloorModel newFloor = FloorModel(
        name: floorName,
        floorPlan: FloorPlanModel.defaultFloorPlan,
      );
      _projectViewModel.addFloor(floor: newFloor);
      floor = newFloor;
    }

    floor ??= _projectViewModel.getAllFloors().firstOrNull;

    if (floor == null) {
      FusionToast.error(context, message: 'Please select or create a floor');
      return;
    }

    final ListeningArea newArea = ListeningArea(
      name: areaName,
      vertices: <FusionCanvasPoint>[],
      isDrawn: false,
    );

    _projectViewModel.addListeningArea(area: newArea, floorId: floor.id);

    if (_isSubzone) {
      vm.updateSubzoneListeningArea(widget.subzoneIndex!, newArea, false);
    } else {
      vm.updateZoneListeningArea(newArea, false);
    }

    FusionToast.success(context, message: "Listening area '${newArea.name}' created");
    _resetAddForm();
  }

  void _resetAddForm() {
    _areaNameCtrl.clear();
    _newFloorNameCtrl.clear();
    setState(() {
      _selectedFloor = _projectViewModel.getAllFloors().firstOrNull;
      _isAddingArea = false;
      _isAddingNewFloor = false;
    });
    widget.onAddingAreaChanged?.call(false);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
      builder: (BuildContext context, CreateZoneViewModelState state) {
        final CreateZoneViewModel vm = context.read<CreateZoneViewModel>();
        final int selectedCount = _selectedCount(vm);

        // Only areas that are truly available (not used anywhere else)
        final List<ListeningArea> availableAreas =
            _isSubzone ? _getAvailableAreasForSubzoneCreation(vm, state) : _projectViewModel.getAvailableListeningAreasForZone();

        // Include currently selected areas so they remain visible in the dropdown
        final List<ListeningArea> selectableAreas =
            availableAreas.where((ListeningArea area) {
              return availableAreas.any((ListeningArea a) => a.id == area.id) || _isSelectedHere(vm, area.id);
            }).toList();

        final bool noSelectableAreas = selectableAreas.isEmpty && !_isAddingArea;

        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            'zone_listening_area_section_${widget.subzoneIndex ?? 'zone'}',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  FusionAppText(
                    text: 'Add listening area for the ${_isSubzone ? 'SubZone' : 'Zone'}',
                    style: context.textTheme.b3Medium.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Zones and SubZones are built using listening areas, which define where sound should feel right to listeners.',
                    preferBelow: true,
                    textAlign: TextAlign.left,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.help,
                      child: FusionIcon.icon(
                        Icons.info_outline,
                        size: 14,
                        color: context.colorScheme.iconWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (selectableAreas.isNotEmpty && !_isAddingArea) ...<Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionOutlinedDropdown<ListeningArea>(
                      semanticId: SemanticHelper.createTestId(
                        SemanticTypes.button,
                        'listening_area_dropdown_${widget.subzoneIndex ?? 'zone'}',
                      ),
                      hint: 'Select Listening Area',
                      value: selectableAreas.firstWhereOrNull(
                        (ListeningArea a) => _isSelectedHere(vm, a.id),
                      ),
                      items: selectableAreas,
                      itemLabelBuilder: (ListeningArea area) {
                        final FloorModel? floor = _projectViewModel.getFloorForListeningArea(areaId: area.id);
                        return '${floor?.name ?? ''}/${area.name.isNotEmpty ? area.name : 'Unnamed'}';
                      },
                      itemWidgetBuilder: (
                        BuildContext context,
                        ListeningArea area,
                        bool _,
                      ) {
                        final FloorModel? floor = _projectViewModel.getFloorForListeningArea(areaId: area.id);

                        final bool isSelected = _isSelectedHere(vm, area.id);

                        final int index = selectableAreas.indexOf(area);
                        return SemanticHelper.container(
                          testId: SemanticHelper.createTestId(
                            SemanticTypes.container,
                            'listening_area_item_$index',
                          ),
                          child: Row(
                            children: <Widget>[
                              FusionCheckbox(
                                semanticId: '_area_$index',
                                value: isSelected,
                                enabled: true,
                                onChanged: () => _toggleArea(vm, area),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FusionAppText(
                                  text: '${floor?.name ?? ''}/${area.name.isNotEmpty ? area.name : 'Unnamed'}',
                                  style: context.textTheme.b3Regular.copyWith(
                                    color: context.colorScheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      selectedItemBuilder: (BuildContext context, ListeningArea _) {
                        return FusionAppText(
                          semanticId: 'Listening_Area_Selected',
                          text: '$selectedCount Listening Area${selectedCount == 1 ? '' : 's'} Selected',
                          maxLine: 1,
                          style: context.textTheme.b3Regular.copyWith(
                            color: context.colorScheme.textPrimary,
                          ),
                        );
                      },
                      onChanged: (ListeningArea area) => _toggleArea(vm, area),
                    ),
                    const SizedBox(height: 10),
                    _buildAddAreaButton(context),
                  ],
                ),
              ],

              // ── No selectable areas OR explicitly adding: show create form ──
              if (noSelectableAreas || _isAddingArea) ...<Widget>[
                if (_isAddingArea) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Add listening area',
                          style: context.textTheme.b3Medium.withColor(
                            context.colorScheme.textPrimary,
                          ),
                        ),
                      ),
                      FusionHoverTextButton(
                        label: 'Cancel',
                        semanticId: 'listening_area_cancel_${widget.subzoneIndex ?? 'zone'}',
                        onTap: _resetAddForm,
                        style: context.textTheme.b3SemiBold.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (noSelectableAreas && !_isAddingArea) ...<Widget>[
                  FusionAppText(
                    text: 'All listening areas are assigned. Create a new one.',
                    style: context.textTheme.b3Regular.copyWith(
                      color: context.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildCreateAreaForm(context),
              ],
            ],
          ),
        );
      },
    );
  }

  List<ListeningArea> _getAvailableAreasForSubzoneCreation(
    CreateZoneViewModel vm,
    CreateZoneViewModelState state,
  ) {
    final List<ListeningArea> baseAvailable = _projectViewModel.getAvailableListeningAreasForZone();

    final Set<String> selectedInOtherSubzones = <String>{};
    for (int i = 0; i < state.subzones.length; i++) {
      if (i == widget.subzoneIndex) continue;
      for (final ListeningArea area in state.subzones[i].listeningAreas) {
        selectedInOtherSubzones.add(area.id);
      }
    }

    return baseAvailable.where((ListeningArea a) => !selectedInOtherSubzones.contains(a.id)).toList();
  }

  // ── Dropdown trigger ──────────────────────────────────────────

  // ── "+ Add New Listening Area" button ─────────────────────────

  Widget _buildAddAreaButton(BuildContext context) {
    return FusionIconTextButton(
      icon: LucideIcons.plus200,
      label: 'Add New Listening Area',
      semanticId: 'add_listening_area_btn_${widget.subzoneIndex ?? 'zone'}',
      iconSize: 16,
      onTap: () {
        setState(() {
          _isAddingArea = true;
        });
        widget.onAddingAreaChanged?.call(true);
      },
      iconColor: context.colorScheme.iconWhite,
      style: context.textTheme.l1SemiBold.copyWith(color: context.colorScheme.onSurface),
    );
  }

  // ── Create area form ──────────────────────────────────────────

  Widget _buildCreateAreaForm(BuildContext context) {
    final List<FloorModel> floors = _projectViewModel.getAllFloors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionLabeledField(
          label: 'Listening Area Name',
          semanticId: 'new_listening_area_name_${widget.subzoneIndex ?? 'zone'}',
          child: FusionBorderedTextField(
            controller: _areaNameCtrl,
            semanticId: 'new_listening_area_name_input_${widget.subzoneIndex ?? 'zone'}',
            hintText: 'Enter area name',
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 20),

        FusionLabeledField(
          label: floors.isEmpty ? 'Floor Name' : 'Select Floor',
          semanticId: 'floor_${widget.subzoneIndex ?? 'zone'}',
          child:
              (floors.isEmpty || _isAddingNewFloor)
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FusionBorderedTextField(
                        controller: _newFloorNameCtrl,
                        semanticId: 'new_floor_name_input_${widget.subzoneIndex ?? 'zone'}',
                        hintText: 'Enter floor name',
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      if (_isAddingNewFloor) ...<Widget>[
                        const SizedBox(height: 8),
                        FusionIconTextButton(
                          icon: Icons.arrow_back_ios,
                          label: 'Cancel and Select from list',
                          semanticId: 'cancel_new_floor_${widget.subzoneIndex ?? 'zone'}',
                          iconSize: 16,
                          onTap:
                              () => setState(() {
                                _isAddingNewFloor = false;
                                _newFloorNameCtrl.clear();
                              }),
                          iconColor: context.colorScheme.iconDefault,
                          style: context.textTheme.l1SemiBold.copyWith(
                            color: context.colorScheme.textBody,
                          ),
                        ),
                      ],
                    ],
                  )
                  : InlineFloorDropdown(
                    floors: floors,
                    selectedFloor: _selectedFloor ?? floors.first,
                    onFloorSelected: (FloorModel f) => setState(() => _selectedFloor = f),
                    onAddNewFloor: () => setState(() => _isAddingNewFloor = true),
                  ),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerLeft,
          child: FusionAppButton(
            semanticId: 'save_listening_area_${widget.subzoneIndex ?? 'zone'}',
            height: 32,
            width: 140,
            text: 'Save Listening Area',
            color: context.colorScheme.elevation2,
            borderRadius: 8,
            textstyle: context.textTheme.l1Medium.copyWith(color: context.colorScheme.textPrimary),
            onPressed: () => _saveListeningArea(context),
            style: FusionAppButtonStyle.primary,
          ),
        ),
      ],
    );
  }
}
