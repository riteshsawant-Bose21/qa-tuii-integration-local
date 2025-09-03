import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/widgets/color_selector_popup.dart';

class ZonePanelWidget extends StatefulWidget {
  final Zone zone;
  final FloorModel Function(String) getListeningAreaFloor;
  final void Function(Zone) onZoneChanged;
  final VoidCallback onDelete;
  final void Function(Zone) onAddListeningAreas;
  final List<ListeningArea> zoneListeningAreas;
  final Function(String) onAreaRemovedFromZone;

  const ZonePanelWidget({
    super.key,
    required this.zone,
    required this.onZoneChanged,
    required this.onDelete,
    required this.onAddListeningAreas,
    required this.zoneListeningAreas,
    required this.getListeningAreaFloor,
    required this.onAreaRemovedFromZone,
  });

  @override
  ZonePanelWidgetState createState() => ZonePanelWidgetState();
}

class ZonePanelWidgetState extends State<ZonePanelWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    _nameController.text = widget.zone.name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Card(
        color: AppColors.cardSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        elevation: 0,
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    // Container(
                    //   width: 24,
                    //   height: 24,
                    //   decoration: BoxDecoration(
                    //     color: FusionUtils.hexToColor(widget.zone.zoneColor).withValues(alpha: 0.6),
                    //     borderRadius: BorderRadius.circular(4),
                    //   ),
                    // ),
                    ColorSelector(
                      selectedColor: FusionUtils.hexToColor(widget.zone.zoneColor),
                      availableColors: Zone.zoneColors.map((String color) => FusionUtils.hexToColor(color)).toList(),
                      onColorChanged: (Color color) {
                        widget.onZoneChanged(widget.zone.copyWith(zoneColor: FusionUtils.colorToHex(color)));
                      },
                      width: 24,
                      height: 24,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        onFieldSubmitted: (String v) => widget.onZoneChanged(widget.zone.copyWith(name: v)),
                      ),
                    ),

                    if (_isExpanded)
                      IconButton(
                        icon: const Icon(Icons.add, size: 14, color: Colors.blueGrey),
                        onPressed: () {
                          widget.onAddListeningAreas(widget.zone);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'Add Listening Areas',
                      ),

                    const SizedBox(width: 4),

                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.errorSoft, size: 16),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded body
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // List of listening areas
                    if (widget.zoneListeningAreas.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            'Click + to add listening areas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children:
                            widget.zoneListeningAreas.map((ListeningArea area) {
                              final FloorModel areaFloor = widget.getListeningAreaFloor(area.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.crop_free,
                                        size: 14,
                                        color: AppColors.primarySoft,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "${areaFloor.name} / ${area.name}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: AppColors.errorSoft,
                                          size: 14,
                                        ),
                                        onPressed: () => _removeListeningArea(area.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _removeListeningArea(String areaId) {
    // final List<String> updatedAreaIds = List<String>.from(widget.zone.listeningAreasIds)..remove(areaId);
    widget.onAreaRemovedFromZone(areaId);
    // widget.onZoneChanged(
    //   widget.zone.copyWith(listeningAreaIds: updatedAreaIds),
    // );
  }
}
