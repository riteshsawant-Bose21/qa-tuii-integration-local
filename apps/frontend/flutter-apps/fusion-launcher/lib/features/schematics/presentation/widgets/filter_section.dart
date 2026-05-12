import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../create_zone_popup/view/create_zone_popup.dart';
import '../../state/filter_state.dart';
import '../../viewmodel/filter_view_model.dart';

// ─────────────────────────────────────────────
//  LAYOUT CONSTANTS
// ─────────────────────────────────────────────

const double _dotSize = 16.0;
const double _rowHPad = 2.0;
const double _dotCenterX = _rowHPad + (_dotSize / 2);

const double _itemGap = 4.0;
const double _headerGap = 4.0;
const double _childHeight = 32.0;
const double _trailingSize = 32.0;

class FilterSection extends StatefulWidget {
  const FilterSection({super.key});

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  // ── ViewModel accessor ─────────────────────────────────────────────────────
  FilterViewModel get _vm => context.read<FilterViewModel>();

  // ── Project data accessors ─────────────────────────────────────────────────
  List<FloorModel> get _floors => serviceLocator<ProjectViewModel>().getAllFloors();
  List<Zone> get _zones => serviceLocator<ProjectViewModel>().getAllZones();
  List<EquipLocation> get _equipLocations => serviceLocator<ProjectViewModel>().equipLocations;

  bool _hovered = false;
  bool _selectedcthovered = false;
  String? _hoveredAddSection;

  Widget _trailingCheckbox({
    required bool value,
    required VoidCallback onToggle,
  }) {
    return SizedBox(
      width: _trailingSize,
      height: _trailingSize,
      child: Center(
        child: FusionCheckbox(
          semanticId: '',
          value: value,
          onChanged: onToggle,
        ),
      ),
    );
  }

  Widget _trailingKebab(Widget kebab) {
    return SizedBox(
      width: _trailingSize,
      height: _trailingSize,
      child: Center(child: kebab),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState projectState) {
        return BlocBuilder<FilterViewModel, FilterViewModelState>(
          builder: (BuildContext context, FilterViewModelState filterState) {
            return Container(
              width: 212,
              height: 864,
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colorScheme.elevation2, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildPanelHeader(context, filterState),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _buildFloorSection(context, filterState),
                          _buildZonesSection(context, filterState),
                          _buildEquipmentSection(context, filterState),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Panel header ───────────────────────────────────────────────────────────

  Widget _buildPanelHeader(BuildContext context, FilterViewModelState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => _vm.toggleFilterMode(),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: FusionAppText(
                  text: state.filterMode ? 'Done' : 'Filter',
                  style: context.textTheme.l1SemiBold.copyWith(
                    color: _hovered ? context.colorScheme.textSecondary : context.colorScheme.textPrimary,
                    decoration: TextDecoration.underline,
                    decorationColor: _hovered ? context.colorScheme.textSecondary : context.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (state.filterMode)
            Builder(
              builder: (BuildContext context) {
                final List<FloorModel> floors = _floors;
                final List<Zone> zones = _zones;
                final List<EquipLocation> locations = _equipLocations;
                final bool allSelected = _vm.areAllSelected(floors, zones, locations);
                return MouseRegion(
                  onEnter: (_) => setState(() => _selectedcthovered = true),
                  onExit: (_) => setState(() => _selectedcthovered = false),
                  child: GestureDetector(
                    onTap: () {
                      if (allSelected) {
                        _vm.deselectAll();
                      } else {
                        _vm.selectAll(
                          floors: floors,
                          zones: zones,
                          locations: locations,
                        );
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        FusionAppText(
                          text: 'Select All',
                          style: context.textTheme.l1SemiBold.withColor(
                            _selectedcthovered ? context.colorScheme.textSecondary : context.colorScheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FusionCheckbox(
                          semanticId: 'select_all',
                          value: allSelected,
                          onChanged: () {
                            if (allSelected) {
                              _vm.deselectAll();
                            } else {
                              _vm.selectAll(
                                floors: floors,
                                zones: zones,
                                locations: locations,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context,
    FilterViewModelState state,
    String label,
    VoidCallback onAdd,
  ) {
    final bool isAddHovered = _hoveredAddSection == label;

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: label,
                maxLine: 1,
                style: context.textTheme.l1Regular.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
            ),
            if (!state.filterMode)
              MouseRegion(
                onEnter: (_) => setState(() => _hoveredAddSection = label),
                onExit: (_) => setState(() => _hoveredAddSection = null),
                child: GestureDetector(
                  onTap: onAdd,
                  child: FusionAppButton(
                    semanticId: '',
                    style: FusionAppButtonStyle.tertiary,
                    text: 'ADD',
                    textstyle: context.textTheme.l1SemiBold.withColor(
                      isAddHovered ? context.colorScheme.textSecondary : context.colorScheme.textPrimary,
                    ),
                    showPrefixIcon: true,
                    prefixIcon: LucideIcons.plus,
                    onPressed: onAdd,
                  ),
                ),
              ),
          ],
        ),
        Divider(
          color: context.colorScheme.strokeLight,
          thickness: 1,
          height: 12,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  FLOORS
  // ─────────────────────────────────────────────

  Widget _buildFloorSection(BuildContext context, FilterViewModelState state) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: context.colorScheme.elevation2, width: 1)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(context, state, 'FLOORS', () {
            serviceLocator<ProjectViewModel>().addFloor(
              floor: FloorModel(
                name: 'Floor ${_floors.length + 1}',
                floorPlan: FloorPlanModel(
                  imagePath: '',
                  position: Offset.zero,
                  size: Size.zero,
                ),
              ),
            );
          }),
          const SizedBox(height: _headerGap),
          for (int i = 0; i < _floors.length; i++) ...<Widget>[
            _buildFloorRow(context, state, _floors[i]),
            if (i < _floors.length - 1) const SizedBox(height: _itemGap),
          ],
        ],
      ),
    );
  }

  Widget _buildFloorRow(BuildContext context, FilterViewModelState state, FloorModel floor) {
    final bool isOpen = state.isFloorOpen(floor.id);
    final bool isEditing = state.isFloorEditing(floor.id);
    final TextEditingController nameCtrl = _vm.getOrCreateFloorController(floor.id, floor.name);

    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(floorId: floor.id);

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            InkWell(
              onTap: () => _vm.toggleFloorOpen(floor.id),
              child: Icon(
                isOpen ? Icons.arrow_drop_down : Icons.arrow_right,
                size: 20,
                color: context.colorScheme.iconWhite,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child:
                  isEditing && !state.filterMode
                      ? PropertyTextField(
                        controller: nameCtrl,
                        maxLength: 24,
                        autofocus: true,
                        onSubmitted: (String v) {
                          final String trimmed = v.trim();
                          if (trimmed.isNotEmpty) {
                            serviceLocator<ProjectViewModel>().updateFloor(floor: floor.copyWith(name: trimmed));
                          } else {
                            nameCtrl.text = floor.name;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Floor name cannot be empty'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          _vm.toggleFloorEditMode(floor.id);
                        },
                      )
                      : FusionAppText(
                        text: floor.name,
                        style: context.textTheme.l1SemiBold,
                      ),
            ),
            if (state.filterMode)
              _trailingCheckbox(
                value: state.isFloorChecked(floor.id),
                onToggle: () => _vm.toggleFloor(floor.id),
              )
            else
              _trailingKebab(
                FusionKebabPopup(
                  semanticId: '',
                  onEdit: () => _vm.toggleFloorEditMode(floor.id),
                  onDelete: () {
                    _vm.cleanupFloorController(floor.id);
                    serviceLocator<ProjectViewModel>().removeFloor(floorId: floor.id);
                  },
                ),
              ),
          ],
        ),
        if (isOpen && listeningAreas.isNotEmpty)
          for (int i = 0; i < listeningAreas.length; i++)
            if (!state.filterMode && state.isAreaEditing(listeningAreas[i].id))
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: PropertyTextField(
                  controller: _vm.getOrCreateAreaController(listeningAreas[i].id, listeningAreas[i].name),
                  maxLength: 24,
                  autofocus: true,
                  onSubmitted: (String v) {
                    final String trimmed = v.trim();
                    if (trimmed.isNotEmpty) {
                      serviceLocator<ProjectViewModel>().updateListeningArea(area: listeningAreas[i].copyWith(name: trimmed));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Area name cannot be empty'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    _vm.toggleAreaEditMode(listeningAreas[i].id);
                  },
                ),
              )
            else
              _buildChildRow(
                context: context,
                state: state,
                id: listeningAreas[i].id,
                label: listeningAreas[i].name,
                isLast: i == listeningAreas.length - 1,
                isChecked: state.isAreaChecked(listeningAreas[i].id),
                onToggle: () => _vm.toggleArea(listeningAreas[i].id),
                items: <KebabMenuItem>[
                  KebabMenuItem(
                    label: 'Edit',
                    onTap: () => _vm.toggleAreaEditMode(listeningAreas[i].id),
                    icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                  ),
                  KebabMenuItem(
                    label: 'Delete',
                    onTap: () {
                      _vm.cleanupAreaController(listeningAreas[i].id);
                      serviceLocator<ProjectViewModel>().removeListeningArea(areaId: listeningAreas[i].id);
                    },
                    icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                  ),
                ],
              ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  ZONES
  // ─────────────────────────────────────────────

  Widget _buildZonesSection(BuildContext context, FilterViewModelState state) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: context.colorScheme.elevation2, width: 1)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(context, state, 'ZONES', () {
            CreateZonePopup.show(context, isFromBuildingPage: false);
          }),
          const SizedBox(height: _headerGap),
          for (final Zone zone in _zones) ...<Widget>[
            _buildZoneRow(context, state, zone),
            if (_zones.indexOf(zone) < _floors.length - 1) const SizedBox(height: _itemGap),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneRow(BuildContext context, FilterViewModelState state, Zone zone) {
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: zone.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FusionAppText(
                text: zone.name,
                style: context.textTheme.l1Regular,
              ),
            ),
            if (state.filterMode)
              _trailingCheckbox(
                value: state.isZoneChecked(zone.id),
                onToggle: () => _vm.toggleZone(zone.id),
              )
            else
              _trailingKebab(
                FusionKebabPopup(
                  semanticId: '',
                  items: <KebabMenuItem>[
                    KebabMenuItem(
                      label: 'Edit',
                      onTap: () => CreateZonePopup.showEdit(context, zone: zone, isFromBuildingPage: false),
                      icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                    ),
                    KebabMenuItem(
                      label: 'Add SubZone',
                      onTap: () => CreateZonePopup.showEdit(context, zone: zone, isFromBuildingPage: false, autoOpenSubzone: true),
                      icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                    ),
                    KebabMenuItem(
                      label: 'Delete',
                      onTap: () => serviceLocator<ProjectViewModel>().removeZone(zoneId: zone.id),
                      icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (int i = 0; i < subZones.length; i++)
          _buildChildRow(
            context: context,
            state: state,
            id: subZones[i].id,
            label: subZones[i].name,
            isLast: i == subZones.length - 1,
            isChecked: state.isSubZoneChecked(subZones[i].id),
            onToggle: () => _vm.toggleSubZone(subZones[i].id),
            items: <KebabMenuItem>[
              KebabMenuItem(
                label: 'Edit',
                onTap: () => CreateZonePopup.showEdit(context, zone: zone, isFromBuildingPage: false, autoOpenSubzone: true),
                icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
              ),
              KebabMenuItem(
                label: 'Delete',
                onTap: () => serviceLocator<ProjectViewModel>().removeSubZoneFromZone(subZoneId: subZones[i].id, parentZoneId: zone.id),
                icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
              ),
            ],
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  EQUIPMENT LOCATIONS
  // ─────────────────────────────────────────────

  Widget _buildEquipmentSection(BuildContext context, FilterViewModelState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(context, state, 'EQUIPMENT LOCATION', () {
            serviceLocator<ProjectViewModel>().addEquipLocation(
              equipLocation: EquipLocation(
                name: 'Equipment Location ${_equipLocations.length + 1}',
              ),
            );
          }),
          const SizedBox(height: _headerGap),
          for (int i = 0; i < _equipLocations.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child:
                      (!state.filterMode && state.isLocationEditing(_equipLocations[i].id))
                          ? PropertyTextField(
                            controller: _vm.getOrCreateLocationController(_equipLocations[i].id, _equipLocations[i].name),
                            maxLength: 24,
                            autofocus: true,
                            onSubmitted: (String v) {
                              final String trimmed = v.trim();
                              if (trimmed.isNotEmpty) {
                                serviceLocator<ProjectViewModel>().updateEquipLocation(equipLocation: _equipLocations[i].copyWith(name: trimmed));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Location name cannot be empty'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                              _vm.toggleLocationEditMode(_equipLocations[i].id);
                            },
                          )
                          : FusionAppText(
                            text: _equipLocations[i].name,
                            style: context.textTheme.l1Regular,
                          ),
                ),
                if (state.filterMode)
                  _trailingCheckbox(
                    value: state.isLocationChecked(_equipLocations[i].id),
                    onToggle: () => _vm.toggleLocation(_equipLocations[i].id),
                  )
                else
                  _trailingKebab(
                    FusionKebabPopup(
                      semanticId: '',
                      items: <KebabMenuItem>[
                        KebabMenuItem(
                          label: 'Edit',
                          onTap: () => _vm.toggleLocationEditMode(_equipLocations[i].id),
                          icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                        ),
                        KebabMenuItem(
                          label: 'Delete',
                          onTap: () {
                            _vm.cleanupLocationController(_equipLocations[i].id);
                            serviceLocator<ProjectViewModel>().removeEquipLocation(equipLocationId: _equipLocations[i].id);
                          },
                          icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (i < _equipLocations.length - 1) const SizedBox(height: _itemGap),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SHARED CHILD ROW
  // ─────────────────────────────────────────────

  Widget _buildChildRow({
    required BuildContext context,
    required FilterViewModelState state,
    required String id,
    required String label,
    required bool isLast,
    required bool isChecked,
    required VoidCallback onToggle,
    required List<KebabMenuItem> items,
  }) {
    const double treeWidth = _dotCenterX + _dotSize + 4;

    return SizedBox(
      height: _childHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: treeWidth,
            child: CustomPaint(
              painter: _TreeLinePainter(
                color: context.colorScheme.strokeDark,
                isLast: isLast,
                lineX: _dotCenterX,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: label,
                    style: context.textTheme.l1Regular,
                  ),
                ),
                if (state.filterMode)
                  _trailingCheckbox(value: isChecked, onToggle: onToggle)
                else
                  _trailingKebab(FusionKebabPopup(semanticId: 'section_child', items: items)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TREE LINE PAINTER
// ─────────────────────────────────────────────

class _TreeLinePainter extends CustomPainter {
  final Color color;
  final bool isLast;
  final double lineX;

  const _TreeLinePainter({
    required this.color,
    required this.isLast,
    required this.lineX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    const double cornerRadius = 8.0;
    final double midY = size.height / 2;

    canvas.drawLine(
      Offset(lineX, 0),
      isLast ? Offset(lineX, midY - cornerRadius) : Offset(lineX, size.height),
      paint,
    );

    final Path path =
        Path()
          ..moveTo(lineX, midY - cornerRadius)
          ..quadraticBezierTo(lineX, midY, lineX + cornerRadius, midY)
          ..lineTo(size.width, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) => old.color != color || old.isLast != isLast || old.lineX != lineX;
}
