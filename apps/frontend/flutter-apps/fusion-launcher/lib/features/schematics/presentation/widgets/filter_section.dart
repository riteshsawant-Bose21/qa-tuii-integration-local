import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../create_zone_popup/view/create_zone_popup.dart';

class FilterSection extends StatefulWidget {
  const FilterSection({super.key});

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  final Map<String, bool> _floorOpen = <String, bool>{};

  static const double _dotSize = 16.0;
  static const double _rowHPad = 2.0;
  static const double _dotCenterX = _rowHPad + (_dotSize / 2);

  List<FloorModel> get _floors => serviceLocator<ProjectViewModel>().getAllFloors();

  List<Zone> get _zones => serviceLocator<ProjectViewModel>().getAllZones();

  List<EquipLocation> get _equipLocations => serviceLocator<ProjectViewModel>().equipLocations;
  final Map<String, bool> _floorEditing = <String, bool>{};
  final Map<String, bool> _areaEditing = <String, bool>{};
  final Map<String, bool> _locationEditing = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
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
              _buildPanelHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      _buildFloorSection(context),
                      _buildZonesSection(context),
                      _buildEquipmentSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FusionAppText(
          underLine: true,
          text: 'Filter',
          style: context.textTheme.l1SemiBold.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: context.colorScheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String label,
    VoidCallback onAdd,
  ) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: label,
                style: context.textTheme.l1Regular.copyWith(
                  color: context.colorScheme.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: FusionAppButton(
                semanticId: '',
                style: FusionAppButtonStyle.tertiary,
                text: 'ADD',
                textstyle: context.textTheme.l1SemiBold.withColor(context.colorScheme.textPrimary),
                showPrefixIcon: true,
                prefixIcon: LucideIcons.plus,
                onPressed: onAdd,
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

  Widget _buildFloorSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(context, 'FLOORS', () {
            final FloorModel newFloor = FloorModel(
              name: 'Floor ${_floors.length + 1}',
              floorPlan: FloorPlanModel(
                imagePath: '', // ← empty string for no image
                position: Offset.zero, // ← or whatever Position/Offset type it expects
                size: Size.zero, // ← or whatever Size type it expects
              ),
            );
            serviceLocator<ProjectViewModel>().addFloor(floor: newFloor);
          }),
          const SizedBox(height: 6),
          for (final FloorModel floor in _floors) ...<Widget>[
            _buildFloorRow(context, floor),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildFloorRow(BuildContext context, FloorModel floor) {
    final bool isOpen = _floorOpen[floor.id] ?? false;
    final bool isEditing = _floorEditing[floor.id] ?? false;

    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(floorId: floor.id);

    final TextEditingController floorNameController = TextEditingController(text: floor.name);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: () => setState(() => _floorOpen[floor.id] = !isOpen),
              child: Icon(
                isOpen ? Icons.arrow_drop_down : Icons.arrow_right,
                size: 20,
                color: context.colorScheme.iconWhite,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child:
                  isEditing
                      ? PropertyTextField(
                        controller: floorNameController,
                        maxLength: 24,
                        autofocus: true,
                        onSubmitted: (String v) {
                          final String trimmedName = v.trim();
                          if (trimmedName.isNotEmpty) {
                            final FloorModel updated = floor.copyWith(name: trimmedName);
                            serviceLocator<ProjectViewModel>().updateFloor(floor: updated);
                          } else {
                            floorNameController.text = floor.name;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Floor name cannot be empty'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          setState(() => _floorEditing[floor.id] = false);
                        },
                      )
                      : FusionAppText(
                        text: floor.name,
                        style: context.textTheme.l1SemiBold,
                      ),
            ),
            FusionKebabPopup(
              semanticId: "",
              onEdit: () => setState(() => _floorEditing[floor.id] = true),
              onDelete: () {
                serviceLocator<ProjectViewModel>().removeFloor(floorId: floor.id);
              },
            ),
          ],
        ),
        if (isOpen && listeningAreas.isNotEmpty)
          for (int i = 0; i < listeningAreas.length; i++)
            if (_areaEditing[listeningAreas[i].id] ?? false)
              Row(
                children: <Widget>[
                  // match your existing indentation spacing
                  const SizedBox(width: 24),
                  Expanded(
                    child: PropertyTextField(
                      controller: TextEditingController(text: listeningAreas[i].name),
                      maxLength: 24,
                      autofocus: true,
                      onSubmitted: (String v) {
                        final String trimmedName = v.trim();
                        if (trimmedName.isNotEmpty) {
                          final ListeningArea updated = listeningAreas[i].copyWith(name: trimmedName);
                          serviceLocator<ProjectViewModel>().updateListeningArea(area: updated);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Area name cannot be empty'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        setState(() => _areaEditing[listeningAreas[i].id] = false);
                      },
                    ),
                  ),
                ],
              )
            else
              _buildChildRow(
                context: context,
                label: listeningAreas[i].name,
                isLast: i == listeningAreas.length - 1,
                items: <KebabMenuItem>[
                  KebabMenuItem(
                    label: 'Edit',
                    onTap: () => setState(() => _areaEditing[listeningAreas[i].id] = true),
                    icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                  ),
                  KebabMenuItem(
                    label: 'Delete',
                    onTap: () => serviceLocator<ProjectViewModel>().removeListeningArea(areaId: listeningAreas[i].id),
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

  Widget _buildZonesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(context, 'ZONES', () {
            CreateZonePopup.show(context, isFromBuildingPage: false);
          }),
          const SizedBox(height: 6),
          for (final Zone zone in _zones) ...<Widget>[
            _buildZoneRow(context, zone),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneRow(BuildContext context, Zone zone) {
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    return Column(
      children: <Widget>[
        Row(
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
                  onTap: () {},
                  icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                ),
                KebabMenuItem(
                  label: 'Delete',
                  onTap: () => serviceLocator<ProjectViewModel>().removeZone(zoneId: zone.id),
                  icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                ),
              ],
            ),
          ],
        ),
        for (int i = 0; i < subZones.length; i++)
          _buildChildRow(
            context: context,
            label: subZones[i].name,
            isLast: i == subZones.length - 1,
            items: <KebabMenuItem>[
              KebabMenuItem(
                label: 'Edit',
                onTap: () {},
                icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
              ),
              KebabMenuItem(
                label: 'Add SubZone',
                onTap: () {},
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

  Widget _buildEquipmentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(context, 'EQUIPMENT LOCATION', () {
            final EquipLocation newLocation = EquipLocation(
              name: 'Equipment Location ${_equipLocations.length + 1}',
            );
            serviceLocator<ProjectViewModel>().addEquipLocation(equipLocation: newLocation);
          }),
          const SizedBox(height: 6),
          for (final EquipLocation location in _equipLocations) ...<Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child:
                      (_locationEditing[location.id] ?? false)
                          ? PropertyTextField(
                            controller: TextEditingController(text: location.name),
                            maxLength: 24,
                            autofocus: true,
                            onSubmitted: (String v) {
                              final String trimmedName = v.trim();
                              if (trimmedName.isNotEmpty) {
                                final EquipLocation updated = location.copyWith(name: trimmedName);
                                serviceLocator<ProjectViewModel>().updateEquipLocation(equipLocation: updated);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Location name cannot be empty'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                              setState(() => _locationEditing[location.id] = false);
                            },
                          )
                          : FusionAppText(
                            text: location.name,
                            style: context.textTheme.l1Regular,
                          ),
                ),
                FusionKebabPopup(
                  semanticId: '',
                  items: <KebabMenuItem>[
                    KebabMenuItem(
                      label: 'Edit',
                      onTap: () => setState(() => _locationEditing[location.id] = true),
                      icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                    ),
                    KebabMenuItem(
                      label: 'Delete',
                      onTap: () => serviceLocator<ProjectViewModel>().removeEquipLocation(equipLocationId: location.id),
                      icon: 'packages/fusion_lib/lib/assets/svgs/edit.svg',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SHARED WIDGETS
  // ─────────────────────────────────────────────

  Widget _buildChildRow({required BuildContext context, required String label, required bool isLast, required List<KebabMenuItem> items}) {
    const double treeWidth = _dotCenterX + _dotSize + 4;

    return SizedBox(
      height: 34,
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
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: label,
                    style: context.textTheme.l1Regular,
                  ),
                ),
                FusionKebabPopup(
                  semanticId: '',
                  items: items,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kebab({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) => FusionKebabPopup(
    semanticId: '',
    onDelete: onDelete,
    onEdit: onEdit,
    onDuplicate: () {},
  );
}

// ─────────────────────────────────────────────
//  TREE LINE PAINTER (unchanged)
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
