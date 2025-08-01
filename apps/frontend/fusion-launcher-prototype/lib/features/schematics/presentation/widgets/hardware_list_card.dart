import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/models/hardware_component_entity.dart';

import '../../../../core/models/generic_hardware_component_entity.dart';
import '../../../../core/models/source_entity.dart';
import '../../../../core/models/speaker_entity.dart';

class HardwareListCard extends StatelessWidget {
  final String? title;
  final List<HardwareComponent> hardwareComponents;
  final double componentWidth;
  final double componentHeight;
  final bool showAddedBySystem;
  final Function(HardwareComponent)? onDelete;

  const HardwareListCard({
    super.key,
    this.title,
    required this.hardwareComponents,
    this.componentWidth = 52,
    this.componentHeight = 52,
    this.showAddedBySystem = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      spacing: 11,
      runSpacing: 11,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 11,
          children: <Widget>[
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.80),
                  fontSize: 13,
                  letterSpacing: -0.03,
                ),
              ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              clipBehavior: (title != null) ? Clip.antiAlias : Clip.none,
              decoration:
                  (title != null)
                      ? ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFFD5D5D5),
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      )
                      : null,
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.spaceAround,
                runSpacing: 20,
                spacing: 15,
                children: _buildHardwareWidgets(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildHardwareWidgets() {
    final List<Widget> widgets = <Widget>[];

    // Process Speakers - group by speakerSKU
    final Map<String, List<Speaker>> speakerGroups = <String, List<Speaker>>{};
    for (HardwareComponent component in hardwareComponents) {
      if (component is Speaker) {
        speakerGroups.putIfAbsent(component.speakerSKU, () => <Speaker>[]).add(component);
      }
    }

    for (MapEntry<String, List<Speaker>> entry in speakerGroups.entries) {
      final List<Speaker> speakers = entry.value;
      final int count = speakers.length;
      final Speaker speaker = speakers.first;

      widgets.add(
        _buildHardwareItem(
          component: speaker,
          count: count > 1 ? count : null,
          displayName: speaker.hardwareName,
        ),
      );
    }

    // Process Sources - group by sku
    final Map<String, List<Source>> sourceGroups = <String, List<Source>>{};
    for (HardwareComponent component in hardwareComponents) {
      if (component is Source) {
        sourceGroups.putIfAbsent(component.sku, () => <Source>[]).add(component);
      }
    }

    for (MapEntry<String, List<dynamic>> entry in sourceGroups.entries) {
      final List<dynamic> sources = entry.value;
      final int count = sources.length;
      final Source source = sources.first;

      widgets.add(
        _buildHardwareItem(
          component: source,
          count: count > 1 ? count : null,
          displayName: source.hardwareName,
        ),
      );
    }

    // Process Generic Hardware Components - no grouping, no badges
    final Map<String, List<HardwareComponent>> genericComponentsGroup = <String, List<GenericHardwareComponent>>{};
    for (HardwareComponent component in hardwareComponents) {
      if (component is GenericHardwareComponent) {
        genericComponentsGroup.putIfAbsent(component.sku, () => <GenericHardwareComponent>[]).add(component);
      }
    }

    for (MapEntry<String, List<dynamic>> entry in genericComponentsGroup.entries) {
      final List<dynamic> genericComponents = entry.value;
      final int count = genericComponents.length;
      final GenericHardwareComponent component = genericComponents.first;

      widgets.add(
        _buildHardwareItem(
          component: component,
          count: count > 1 ? count : null,
          displayName: component.hardwareName,
        ),
      );
    }
    //
    // for (HardwareComponent component in hardwareComponents) {
    //   if (component is GenericHardwareComponent) {
    //     widgets.add(
    //       _buildHardwareItem(
    //         component: component,
    //         count: null,
    //         displayName: component.hardwareName,
    //       ),
    //     );
    //   }
    // }

    return widgets;
  }

  Widget _buildHardwareItem({
    required HardwareComponent component,
    required int? count,
    required String displayName,
  }) {
    Widget imageWidget = Container(
      alignment: Alignment.center,
      width: componentWidth,
      height: componentHeight,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(component.assetImagePath),
          fit: BoxFit.fill,
          alignment: Alignment.center,
        ),
      ),
    );

    // Show badge only if count is greater than 1
    if (count != null && count > 1) {
      imageWidget = Badge(
        backgroundColor: const Color(0xFFD7D7D7),
        alignment: Alignment.bottomRight,
        offset: const Offset(0, -20),
        padding: const EdgeInsets.all(3),
        label: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
            height: 1.54,
          ),
        ),
        child: imageWidget,
      );
    }

    return Stack(
      children: <Widget>[
        SizedBox(
          height: (onDelete != null) ? 100 : null,
          width: (onDelete != null) ? 80 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              imageWidget,
              const SizedBox(
                height: 5,
              ),

              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 5,
              ),
              if (showAddedBySystem)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: const Text(
                    'Added by System',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                onDelete!(component);
              },
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}
