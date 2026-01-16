import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/utils/fusion_utils.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'hardware_list_card.dart';

class ZoneSchematicCard extends StatelessWidget {
  final Zone zone;
  final List<HardwareComponent> hardwareComponents;
  final Function(SpeakerData) onSpeakerAdded;
  final Function(ControllerData) onControllerAdded;

  const ZoneSchematicCard({
    super.key,
    required this.zone,
    required this.hardwareComponents,
    required this.onSpeakerAdded,
    required this.onControllerAdded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(left: 15),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: ShapeDecoration(
              color: FusionUiUtils.hexToColor(zone.zoneColor).withValues(alpha: 0.6),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ),
            child: Text(
              zone.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
            ),
          ),
          DragTarget<DeviceComponent>(
            onAcceptWithDetails: (DragTargetDetails<DeviceComponent> details) {
              final DeviceComponent component = details.data;
              if (component is SpeakerData) {
                onSpeakerAdded(component);
              } else if (component is ControllerData) {
                onControllerAdded(component);
              }
            },
            builder: (BuildContext context, List<DeviceComponent?> candidateItems, List<dynamic> rejectedItems) {
              final bool hasIncomingData = candidateItems.isNotEmpty && (candidateItems.last is SpeakerData || candidateItems.last is ControllerData);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                decoration: ShapeDecoration(
                  color: hasIncomingData ? const Color(0xFF80C7FF) : Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 2,
                      color: FusionUiUtils.hexToColor(zone.zoneColor).withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        if (hardwareComponents.isEmpty && !hasIncomingData)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No Components added.',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ),

                        if (hardwareComponents.whereType<Speaker>().toList().isNotEmpty)
                          HardwareListCard(
                            title: "Speakers",
                            hardwareComponents: hardwareComponents.whereType<Speaker>().toList(),
                            onDelete: (HardwareComponent component) {
                              serviceLocator<ProjectViewModel>().removeHardware(hardwareId: component.id);
                            },
                          ),
                        if (hardwareComponents.whereType<GenericHardwareComponent>().toList().isNotEmpty)
                          HardwareListCard(
                            title: "Controllers",
                            hardwareComponents: hardwareComponents.whereType<GenericHardwareComponent>().toList(),
                            onDelete: (HardwareComponent component) {
                              serviceLocator<ProjectViewModel>().removeHardware(hardwareId: component.id);
                            },
                          ),
                      ],
                    ),
                    if (hasIncomingData)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Drop Here',
                            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primaryColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
