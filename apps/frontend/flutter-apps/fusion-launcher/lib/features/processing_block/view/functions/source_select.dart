import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/features/processing_block/view/common/neumorphic_text_field.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_radio.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'widgets.dart';

class SourceSelectZoneControlPanel extends StatefulWidget {
  const SourceSelectZoneControlPanel({super.key});

  @override
  State<SourceSelectZoneControlPanel> createState() => _SourceSelectZoneControlPanelState();
}

class _SourceSelectZoneControlPanelState extends State<SourceSelectZoneControlPanel> {
  ValueNotifier<num> valueNotifier = ValueNotifier<num>(0.0);

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.5;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth < 800 ? controlScreenWidth : 800,
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
                      text: "ZONE CONTROL PANEL - SOURCE SELECT",
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 32,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF5F5F5),
                          child: FusionAppText(
                            text: "SOURCE SELECT",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            spacing: 10,
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/svg/broadcast.svg',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: FusionAppText(
                                    text: "Channels",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: FusionAppText(
                                    text: "Out",
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              children: <Widget>[
                                ...List<Widget>.generate(50, (int index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      spacing: 10,
                                      children: <Widget>[
                                        const Expanded(
                                          child: Center(
                                            child: Icon(
                                              Icons.circle,
                                              color: Color(0xFF92D04F),
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            height: 24,
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              border: Border.all(color: const Color(0xFFE5E5E5)),
                                              borderRadius: const BorderRadius.all(Radius.circular(4)),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Center(
                                                    child: FusionAppText(
                                                      text: "Music _0$index",
                                                      maxLine: 1,
                                                      style: Theme.of(context).textTheme.labelSmall,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 16,
                                                  width: 16,
                                                  alignment: Alignment.center,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF92D04F),
                                                    borderRadius: BorderRadius.all(Radius.circular(2)),
                                                  ),
                                                  child: FusionAppText(
                                                    text: "1",
                                                    style: Theme.of(context).textTheme.labelSmall,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              PBRadio(
                                                value: index % 2 == 0,
                                                size: const Size(24, 24),
                                                padding: const EdgeInsets.all(2),
                                                onChanged: (bool value) {
                                                  //
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.black12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 32,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF5F5F5),
                          child: FusionAppText(
                            text: "ZONE VOLUME",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const NeumorphicTextField(
                          width: 72,
                          height: 28,
                          hintText: "-20db ",
                          borderRadius: 8,
                        ),

                        const Expanded(child: JustSliderAndMeterWidget()),

                        const NeumorphicAudioToggleButton(
                          isActive: true,
                          width: 100,
                          height: 35,
                          borderRadius: 8,
                          iconSize: 18,
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
