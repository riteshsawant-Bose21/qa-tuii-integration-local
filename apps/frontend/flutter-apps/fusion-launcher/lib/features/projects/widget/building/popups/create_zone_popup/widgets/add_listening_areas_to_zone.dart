part of '../create_zone_popup.dart';

class AddListeningAreasToZone extends StatefulWidget {
  final List<String> selectedListeningAreaIds;
  final Function(List<String> selectedIds) onListeningAreaSelected;

  const AddListeningAreasToZone({
    super.key,
    required this.selectedListeningAreaIds,
    required this.onListeningAreaSelected,
  });

  @override
  State<AddListeningAreasToZone> createState() => _AddListeningAreasToZoneState();
}

class _AddListeningAreasToZoneState extends State<AddListeningAreasToZone> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  List<ListeningArea> get allListeningAreas => serviceLocator<ProjectViewModel>().getAllListeningAreas();

  late List<String> _selectedListeningAreaIds;

  @override
  void initState() {
    super.initState();
    _selectedListeningAreaIds = widget.selectedListeningAreaIds;
  }

  String? zoneName(String areaId) {
    String? zoneName = projectViewModel.getZonesForListeningArea(areaId: areaId)?.name;
    if (zoneName == null || zoneName.trim().isEmpty) {
      zoneName = projectViewModel.getSubZoneForListeningArea(areaId: areaId)?.name;
    }
    return null;
  }

  void onSelect(bool isSelected, ListeningArea area, StateSetter setPopupState) {
    isSelected ? _selectedListeningAreaIds.remove(area.id) : _selectedListeningAreaIds.add(area.id);
    widget.onListeningAreaSelected(_selectedListeningAreaIds);
    setPopupState(() {});
    setState(() {});
  }

   

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      showArrow: false,
      blurAmount: 0,
      backgroundColor: const Color(0xFF292826),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setPopupState) {
          return SizedBox(
            width: 280,
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: Navigator.of(context).pop,
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(LucideIcons.x200, size: 16),
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
                              ...allListeningAreas.map(
                                (ListeningArea area) {
                                  final FloorModel? floorName = projectViewModel.getFloorForListeningArea(areaId: area.id);

                                  /// Get available areas for the current zone/sub-zone
                                  final List<ListeningArea> availableListeningAreas = projectViewModel.getAvailableListeningAreasForZone();

                                  /// Check availability
                                  final bool isAvailable = availableListeningAreas.any((ListeningArea a) => a.id == area.id);

                                  /// Whether this area is selected
                                  final bool isSelected = _selectedListeningAreaIds.contains(area.id);

                                  return InkWell(
                                    onTap: isAvailable ? () => onSelect(isSelected, area, setPopupState) : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      color: isAvailable ? Colors.transparent : Colors.grey.withOpacity(0.05),
                                      child: Row(
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: isAvailable ? () => onSelect(isSelected, area, setPopupState) : null,
                                            child: Icon(
                                              (isAvailable ? isSelected : true) ? Icons.check_box : Icons.check_box_outline_blank,
                                              size: 14,
                                              color: isAvailable ? context.colorScheme.onSurface : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          /// Area and zone names
                                          Expanded(
                                            child: FusionAppText(
                                              text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Area',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10,
                                                color: isAvailable ? Theme.of(context).textTheme.bodySmall?.color : Colors.grey[400],
                                              ),
                                            ),
                                          ),

                                          /// Zone name
                                          FusionAppText(
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
                // const SizedBox(height: 10),
                // const Divider(thickness: 0.5, height: 0),

                /// Create New Location Section
                // _CreateNewLocationWidget(
                //   onListeningAreaCreated: (ListeningArea value) {
                // _selectedListeningAreaIds = <String>[value.id];
                //     setPopupState(() {});
                //     setState(() {});
                //   },
                // ),
              ],
            ),
          );
        },
      ),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: _selectedListeningAreaIds.isEmpty ? 'Select listening areas' : '${_selectedListeningAreaIds.length} listening areas selected',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    color: _selectedListeningAreaIds.isEmpty ? context.colorScheme.onSurface.withAlpha(155) : context.colorScheme.onSurface,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
