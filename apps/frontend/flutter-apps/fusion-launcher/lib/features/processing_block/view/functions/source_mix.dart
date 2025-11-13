import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter, FilteringTextInputFormatter;
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_textfield.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../widgets/pb_button.dart';
import 'widgets.dart';

class SourceMixZoneControlPanel extends StatelessWidget {
  const SourceMixZoneControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.65;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth < 1200 ? controlScreenWidth : 1200,
        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
      ),

      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.black,
              child: const Column(
                mainAxisSize: MainAxisSize.min, // 👈 critical: let the column shrink to fit
                children: <Widget>[
                  SizedBox(height: 35),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 👈 make row fit its content
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Left scrollable section
                        Flexible(
                          fit: FlexFit.loose,
                          child: IndividualSourceMixWidget(),
                        ),

                        SourceMixMixScenes(),

                        // Right side (only one widget)
                        Flexible(
                          fit: FlexFit.loose,
                          child: ColoredBox(
                            color: Colors.white,
                            child: SourceMixSubZonesWidget(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              child: Container(
                height: 35,
                color: Colors.black,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "ZONE CONTROL PANEL - SOURCE MIX",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 0,
              child: Container(
                height: 35,
                color: Colors.black,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IndividualSourceMixWidget extends StatefulWidget {
  const IndividualSourceMixWidget({super.key});

  @override
  State<IndividualSourceMixWidget> createState() => _IndividualSourceMixWidgetState();
}

class _IndividualSourceMixWidgetState extends State<IndividualSourceMixWidget> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: ColoredBox(
          color: const Color(0xFFF5F5F5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(10, (int index) {
              return SizedBox(
                width: 150,
                child: Column(
                  spacing: 10,
                  children: <Widget>[
                    const SizedBox(height: 5),
                    FusionAppText(
                      text: "SOURCE MIX ${index + 1}",
                      textAlign: TextAlign.center,
                      maxLine: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    PBTextField(
                      hintText: "0db",
                      onSubmitted: (String? value) {},
                      width: 100,
                      height: 32,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.black12,
                            ),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SliderAndMeterWidget(
                                onSliderChanged: (num value) {},
                              ),
                            ),
                            NeumorphicAudioToggleButton(
                              isActive: index % 2 == 0,
                              width: 100,
                              height: 35,
                              onTap: () {},
                              backgroundColor: const Color(0xFFF5F5F5),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
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
      width: 150,
      color: const Color(0xFFF5F5F5),
      child: Column(
        spacing: 10,
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

class SourceMixSubZonesWidget extends StatefulWidget {
  const SourceMixSubZonesWidget({super.key});

  @override
  State<SourceMixSubZonesWidget> createState() => _SourceMixSubZonesWidgetState();
}

class _SourceMixSubZonesWidgetState extends State<SourceMixSubZonesWidget> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(10, (int index) {
            return Container(
              width: 150,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black12),
                ),
              ),
              child: Column(
                spacing: 10,
                children: <Widget>[
                  const SizedBox(height: 5),
                  FusionAppText(
                    text: "SUB ZONE ${index + 1}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  PBTextField(
                    hintText: "-20db",
                    onSubmitted: (String? value) {},
                    width: 100,
                    height: 32,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: SliderAndMeterWidget(
                              onSliderChanged: (num value) {},
                            ),
                          ),
                          NeumorphicAudioToggleButton(
                            isActive: true,
                            width: 100,
                            height: 35,
                            onTap: () {},
                            backgroundColor: const Color(0xFFF5F5F5),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
