import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_textfield.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../widgets/pb_button.dart';
import '../widgets/pb_meter.dart';
import '../widgets/pb_slider.dart';
import 'widgets.dart';

class SourceMixZoneControlPanel extends StatefulWidget {
  const SourceMixZoneControlPanel({super.key});

  @override
  State<SourceMixZoneControlPanel> createState() => _SourceMixZoneControlPanelState();
}

class _SourceMixZoneControlPanelState extends State<SourceMixZoneControlPanel> {
  ValueNotifier<num> valueNotifier = ValueNotifier<num>(0.0);

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.75;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth < 1200 ? controlScreenWidth : 1200,
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 32,
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: "ZONE CONTROL PANEL - SOURCE MIX",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: Navigator.of(context).pop,
                      borderRadius: BorderRadius.circular(30),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: Container(
                      color: const Color(0xFFF5F5F5),
                      child: Column(
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // ============= WIRELESS MIC =============
                              Expanded(
                                child: Column(
                                  spacing: 5,
                                  children: <Widget>[
                                    const SizedBox(height: 5),
                                    FusionAppText(
                                      text: "Wireless Mic",
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),

                                    const PBTextField(
                                      hintText: "-20db ",
                                      width: 100,
                                      height: 24,
                                    ),
                                  ],
                                ),
                              ),

                              // ============= LECTERN MIC =============
                              Expanded(
                                child: Column(
                                  spacing: 5,
                                  children: <Widget>[
                                    const SizedBox(height: 5),
                                    FusionAppText(
                                      text: "Lectern Mic",
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                    const PBTextField(
                                      hintText: "-20db ",
                                      width: 100,
                                      height: 24,
                                    ),
                                  ],
                                ),
                              ),

                              // ============= PULPIT =============
                              Expanded(
                                child: Column(
                                  spacing: 5,
                                  children: <Widget>[
                                    const SizedBox(height: 5),
                                    FusionAppText(
                                      text: "Pulpit",
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),

                                    const PBTextField(
                                      hintText: "-20db ",
                                      width: 100,
                                      height: 24,
                                    ),
                                  ],
                                ),
                              ),

                              // ============= ORGAN =============
                              Expanded(
                                child: Column(
                                  spacing: 5,
                                  children: <Widget>[
                                    const SizedBox(height: 5),
                                    FusionAppText(
                                      text: "Organ",
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),

                                    const PBTextField(
                                      hintText: "-20db ",
                                      width: 100,
                                      height: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Expanded(
                            child: Row(
                              children: <Widget>[
                                // ============= WIRELESS MIC =============
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      const Expanded(child: JustSliderAndMeterWidget()),
                                      SizedBox(
                                        width: 150,
                                        height: 50,
                                        child: NeumorphicAudioToggleButton(
                                          isActive: true,
                                          onTap: () {
                                            //
                                          },
                                          backgroundColor: const Color(0xFFF5F5F5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const VerticalDivider(width: 1, color: Colors.black12),
                                // ============= LECTERN MIC =============
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      const Expanded(child: JustSliderAndMeterWidget()),

                                      SizedBox(
                                        width: 150,
                                        height: 50,
                                        child: NeumorphicAudioToggleButton(
                                          isActive: false,
                                          onTap: () {
                                            //
                                          },
                                          backgroundColor: const Color(0xFFF5F5F5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const VerticalDivider(width: 1, color: Colors.black12),
                                // ============= PULPIT =============
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      const Expanded(child: JustSliderAndMeterWidget()),

                                      SizedBox(
                                        width: 150,
                                        height: 50,
                                        child: NeumorphicAudioToggleButton(
                                          onTap: () {
                                            //
                                          },
                                          isActive: false,
                                          backgroundColor: const Color(0xFFF5F5F5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const VerticalDivider(width: 1, color: Colors.black12),
                                // ============= ORGAN =============
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      const Expanded(child: JustSliderAndMeterWidget()),
                                      SizedBox(
                                        width: 150,
                                        height: 50,
                                        child: NeumorphicAudioToggleButton(
                                          onTap: () {
                                            //
                                          },
                                          isActive: true,
                                          backgroundColor: const Color(0xFFF5F5F5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.black12),
                  const Expanded(flex: 2, child: SourceMixMixScenes()),
                  const VerticalDivider(width: 1, color: Colors.black12),
                  const Expanded(
                    flex: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: SourceMixFrontRearWidget(
                            title: "FRONT",
                            dbValue: "-20db",
                            isAUdioToggleActive: true,
                          ),
                        ),
                        VerticalDivider(width: 1, color: Colors.black12),
                        Expanded(
                          child: SourceMixFrontRearWidget(
                            title: "REAR",
                            dbValue: "-20db",
                            isAUdioToggleActive: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SourceMixMixScenes extends StatelessWidget {
  const SourceMixMixScenes({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        spacing: 5,
        children: <Widget>[
          const SizedBox(height: 5),
          FusionAppText(
            text: "MIX SCENES",
            style: Theme.of(context).textTheme.labelMedium,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: NeumorphicPopupButton(
              height: 28,
              borderRadius: 8,
            ),
          ),

          const SizedBox(height: 10),
          PBButton(
            text: "STORE",
            width: 72,
            height: 24,
            borderRadius: 9,
            onTap: () {
              //
            },
          ),
          const SizedBox(height: 10),
          PBButton(
            text: "DELETE",
            width: 72,
            height: 24,
            borderRadius: 9,
            textColor: Colors.black12,
            onTap: () {
              //
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class SourceMixFrontRearWidget extends StatelessWidget {
  final String title;
  final String dbValue;
  final bool isAUdioToggleActive;

  const SourceMixFrontRearWidget({
    super.key,
    required this.title,
    required this.dbValue,
    this.isAUdioToggleActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: <Widget>[
        Container(
          height: 28,
          width: double.infinity,
          alignment: Alignment.center,
          color: const Color(0xFFF5F5F5),
          child: FusionAppText(
            text: title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),

        const PBTextField(
          borderRadius: 8,
          hintText: "-20db ",
          width: 100,
          height: 24,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                PBSlider(
                  item: PBItem(
                    id: '567567',
                    x: 20,
                    y: 10,
                    width: 50,
                    height: 50,
                    field: "slider",
                    type: "slider",
                    param: PBSliderParam(label: "Gain", min: 0, max: 1000),
                  ),
                  onChanged: (num value) {
                    //
                  },
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: PBMeter(
                    item: PBItem(
                      id: 'u8678',
                      x: 20,
                      y: 10,
                      width: 50,
                      height: 100,
                      field: "meter",
                      type: "meter",
                      param: PBMeterParam(label: "label", min: -50, max: 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(
          width: 150,
          height: 50,
          child: NeumorphicAudioToggleButton(
            isActive: isAUdioToggleActive,
            onTap: () {
              //
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
