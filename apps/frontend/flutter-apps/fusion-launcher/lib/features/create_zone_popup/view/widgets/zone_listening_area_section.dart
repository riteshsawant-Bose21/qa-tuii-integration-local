part of '../create_zone_content.dart';

// ─────────────────────────────────────────────────────────────
// Inline Listening Area Section
//
// Rules:
//   • One listening area can only be assigned to one zone/subzone.
//   • Areas already used elsewhere are shown disabled with a
//     "Used in <name>" tag — not hidden.
//   • If no listening areas exist → show create form directly.
//   • If areas exist → show dropdown + optional create form.
// ─────────────────────────────────────────────────────────────

class _ZoneListeningAreaSection extends StatefulWidget {
  /// null = zone-level; non-null = subzone at that index.
  final int? subzoneIndex;
  final bool isFromBuildingPage;

  const _ZoneListeningAreaSection({
    required this.subzoneIndex,
    this.isFromBuildingPage = false,
  });

  @override
  State<_ZoneListeningAreaSection> createState() => _ZoneListeningAreaSectionState();
}

class _ZoneListeningAreaSectionState extends State<_ZoneListeningAreaSection> {
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();

  bool _isDropdownOpen = false;
  bool _isAddingArea = false;
  FloorModel? _selectedFloor;
  bool _isAddingNewFloor = false;

  final TextEditingController _areaNameCtrl = TextEditingController();
  final TextEditingController _newFloorNameCtrl = TextEditingController();

  bool get _isSubzone => widget.subzoneIndex != null;

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

  /// Returns "Zone" or "SubZone N" if the area is assigned somewhere
  /// other than the current context, otherwise null (= free to select).
  String? _usedElsewhereLabel(CreateZoneViewModel vm, CreateZoneViewModelState state, String areaId) {
    // Used at zone level (only matters when we're inside a subzone)
    if (_isSubzone && vm.isListeningAreaSelectedForZone(areaId)) {
      return 'Zone';
    }

    // Used in another subzone
    for (int i = 0; i < state.subzones.length; i++) {
      if (_isSubzone && i == widget.subzoneIndex) continue; // skip self
      final bool usedHere = state.subzones[i].listeningAreas?.any((ListeningArea a) => a.id == areaId) ?? false;
      if (usedHere) return 'SubZone ${i + 1}';
    }

    return null;
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
      _selectedFloor = null;
      _isAddingArea = false;
      _isAddingNewFloor = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final List<ListeningArea> allAreas = _projectViewModel.getAllListeningAreas();

    return BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
      builder: (BuildContext context, CreateZoneViewModelState state) {
        final CreateZoneViewModel vm = context.read<CreateZoneViewModel>();
        final int selectedCount = _selectedCount(vm);

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
                      color: context.colorScheme.elevation2, // dark background
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

              // ── Areas exist: dropdown ─────────────────────
              if (allAreas.isNotEmpty && !_isAddingArea) ...<Widget>[
                TapRegion(
                  onTapOutside: (_) => setState(() => _isDropdownOpen = false),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildDropdownTrigger(context, selectedCount),
                      if (_isDropdownOpen) ...<Widget>[
                        const SizedBox(height: 4),
                        _buildAreaList(context, vm, state, allAreas),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildAddAreaButton(context),
              ],

              // ── No areas yet OR adding: create form ────────
              if (allAreas.isEmpty || _isAddingArea) ...<Widget>[
                if (allAreas.isNotEmpty) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Add listening area',
                          style: context.textTheme.b3Medium.withColor(context.colorScheme.textPrimary),
                        ),
                      ),
                      FusionHoverTextButton(
                        label: 'Cancel',
                        semanticId: 'listening_area_cancel_${widget.subzoneIndex ?? 'zone'}',
                        onTap: _resetAddForm,
                        style: context.textTheme.b3SemiBold.copyWith(color: context.colorScheme.textPrimary),
                      ),
                    ],
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

  // ── Dropdown trigger ──────────────────────────────────────────

  Widget _buildDropdownTrigger(BuildContext context, int selectedCount) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        'listening_area_dropdown_${widget.subzoneIndex ?? 'zone'}',
      ),
      child: GestureDetector(
        onTap: () => setState(() => _isDropdownOpen = !_isDropdownOpen),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: selectedCount == 0 ? 'Select Listening Area' : '$selectedCount Listening Area${selectedCount == 1 ? '' : 's'} Selected',
                  style: context.textTheme.b3Medium.copyWith(
                    color: selectedCount == 0 ? context.colorScheme.onSurface.withAlpha(155) : context.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: context.colorScheme.iconDefault,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Area list ─────────────────────────────────────────────────

  Widget _buildAreaList(
    BuildContext context,
    CreateZoneViewModel vm,
    CreateZoneViewModelState state,
    List<ListeningArea> allAreas,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
        color: context.colorScheme.elevation2,
      ),
      child: Column(
        children:
            allAreas.map((ListeningArea area) {
              final FloorModel? floor = _projectViewModel.getFloorForListeningArea(areaId: area.id);
              final bool isSelected = _isSelectedHere(vm, area.id);

              // Compute once per row — null means free to pick
              final String? usedIn = _usedElsewhereLabel(vm, state, area.id);
              final bool isAvailable = usedIn == null;

              return GestureDetector(
                onTap: isAvailable ? () => _toggleArea(vm, area) : null,
                child: SemanticHelper.container(
                  testId: SemanticHelper.createTestId(
                    SemanticTypes.container,
                    'listening_area_item_${area.id}',
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: isAvailable ? Colors.transparent : Colors.grey.withOpacity(0.05),
                    child: Row(
                      children: <Widget>[
                        SemanticHelper.toggle(
                          testId: SemanticHelper.createTestId(
                            SemanticTypes.toggle,
                            'listening_area_checkbox_${area.id}',
                          ),
                          value: isSelected,
                          child: FusionCheckbox(
                            semanticId: '_area_${area.id}',
                            value: isSelected,
                            enabled: isAvailable,
                            onChanged: isAvailable ? () => _toggleArea(vm, area) : () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FusionAppText(
                                text: '${floor?.name ?? ''}/${area.name.isNotEmpty ? area.name : 'Unnamed'}',
                                style: context.textTheme.b3Regular.copyWith(
                                  color: isAvailable ? context.colorScheme.onSurface : context.colorScheme.onSurface.withAlpha(100),
                                ),
                              ),
                              // "Used in SubZone 1" badge — only when taken elsewhere
                              if (usedIn != null) ...<Widget>[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.elevation3,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FusionAppText(
                                    text: 'Used in $usedIn',
                                    style: context.textTheme.b3Regular.copyWith(
                                      fontSize: 9,
                                      color: context.colorScheme.onSurface.withAlpha(150),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ── "+ Add New Listening Area" button ─────────────────────────

  Widget _buildAddAreaButton(BuildContext context) {
    return FusionIconTextButton(
      icon: LucideIcons.plus200,
      label: 'Add New Listening Area',
      semanticId: 'add_listening_area_btn_${widget.subzoneIndex ?? 'zone'}',
      iconSize: 16,
      onTap:
          () => setState(() {
            _isAddingArea = true;
            _isDropdownOpen = false;
          }),
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
                          style: context.textTheme.l1SemiBold.copyWith(color: context.colorScheme.textBody),
                        ),
                      ],
                    ],
                  )
                  : InlineFloorDropdown(
                    floors: floors,
                    selectedFloor: _selectedFloor,
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
