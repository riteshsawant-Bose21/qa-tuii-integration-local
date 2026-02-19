import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_slider.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/horizontal_scroll_effect_wrapper.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class ZoneSubZoneBuilderWidget extends StatefulWidget {
  final String zoneID;

  final bool Function(String zoneOrSubzoneID) isAllowMute;
  final double Function(String zoneOrSubzoneID) getLowerGain;
  final double Function(String zoneOrSubzoneID) getUpperGain;

  final void Function(String zoneOrSubzoneID, num value) onLowerRangeChanged;
  final void Function(String zoneOrSubzoneID, num value) onUpperRangeChanged;

  final void Function(String zoneOrSubzoneID, bool value) onAllowMuteChanged;

  const ZoneSubZoneBuilderWidget({
    super.key,
    required this.zoneID,
    required this.isAllowMute,
    required this.getLowerGain,
    required this.getUpperGain,
    required this.onLowerRangeChanged,
    required this.onUpperRangeChanged,
    required this.onAllowMuteChanged,
  });

  @override
  State<ZoneSubZoneBuilderWidget> createState() => _ZoneSubZoneSettingBuilderState();
}

class _ZoneSubZoneSettingBuilderState extends State<ZoneSubZoneBuilderWidget> {
  late final ScrollController _scrollController = ScrollController();
  late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  late List<SubZone> subZones;
  late Zone? zone;
  late bool isSubZonesAvailable;

  @override
  void initState() {
    super.initState();
    subZones = projectViewModel.getSubZonesForZone(parentZoneId: widget.zoneID);
    if (subZones.isEmpty) zone = projectViewModel.getZone(zoneId: widget.zoneID);
    isSubZonesAvailable = subZones.isNotEmpty;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProjectViewModel>();

    return Column(
      children: <Widget>[
        if (isSubZonesAvailable) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FusionAppText(
              text: "SUB ZONE VOLUME",
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium,
            ),
          ),
        ],

        /// SUBZONE VOLUME
        Expanded(
          child: HorizontalScrollWithShadows(
            controller: _scrollController,
            child: ListView.separated(
              itemCount: isSubZonesAvailable ? subZones.length : 1,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
              itemBuilder: (BuildContext context, int index) {
                final SubZone? subZone = isSubZonesAvailable ? subZones[index] : null;

                final String? title = isSubZonesAvailable ? subZone!.name : zone?.name;
                if (title == null) return const SizedBox.shrink();

                final String zoneOrSubzoneID = isSubZonesAvailable ? subZone!.id : zone!.id;

                final bool isAllowMute = widget.isAllowMute(zoneOrSubzoneID);

                return Container(
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.colorScheme.strokeLight),
                      right: BorderSide(color: context.colorScheme.strokeLight),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: FusionAppText(
                          text: title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Divider(color: context.colorScheme.strokeLight, height: 0),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: VerticalRangeSelectionSlider(
                                min: -60,
                                max: 12,
                                lowerValue: widget.getLowerGain(zoneOrSubzoneID),
                                upperValue: widget.getUpperGain(zoneOrSubzoneID),
                                onLowerChanged: (num value) => widget.onLowerRangeChanged(zoneOrSubzoneID, value),
                                onUpperChanged: (num value) => widget.onUpperRangeChanged(zoneOrSubzoneID, value),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: context.colorScheme.strokeLight, height: 0),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Flexible(
                                    child: FusionAppText(
                                      text: "Allow mute",
                                      style: context.textTheme.labelMedium?.copyWith(
                                        color: context.colorScheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  FusionCheckbox(
                                    value: isAllowMute,
                                    onChanged: () => widget.onAllowMuteChanged(zoneOrSubzoneID, !isAllowMute),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
