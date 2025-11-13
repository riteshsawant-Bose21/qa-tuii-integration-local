import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_textfield.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../widgets/pb_button.dart';
import '../widgets/pb_meter.dart';
import '../widgets/pb_slider.dart';
import 'widgets.dart';

class MiniMatrixZoneControlPanel extends StatefulWidget {
  const MiniMatrixZoneControlPanel({super.key});

  @override
  State<MiniMatrixZoneControlPanel> createState() => _MiniMatrixZoneControlPanelState();
}

class _MiniMatrixZoneControlPanelState extends State<MiniMatrixZoneControlPanel> {
  late final ScrollController _controlsController;
  late final ScrollController _leftController;
  late final ScrollController _rightController;
  bool _isSyncingScroll = false; // 👈 prevents infinite loop

  @override
  void initState() {
    super.initState();

    _controlsController = ScrollController();
    _leftController = ScrollController();
    _rightController = ScrollController();

    _controlsController.addListener(() => _syncScroll(_controlsController));
    _leftController.addListener(() => _syncScroll(_leftController));
    _rightController.addListener(() => _syncScroll(_rightController));
  }

  void _syncScroll(ScrollController source) {
    if (_isSyncingScroll) return; // prevent re-entrant calls
    _isSyncingScroll = true;

    final double offset = source.offset;
    final List<ScrollController> controllers = <ScrollController>[_controlsController, _leftController, _rightController];

    for (final ScrollController controller in controllers) {
      if (controller == source) continue;
      if (controller.hasClients) {
        controller.jumpTo(
          offset.clamp(
            controller.position.minScrollExtent,
            controller.position.maxScrollExtent,
          ),
        );
      }
    }

    _isSyncingScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.65;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth < 800 ? controlScreenWidth : 800,
        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
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
                      text: "ZONE CONTROL PANEL - MINI MATRIX",
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
            const Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: MiniMatrixControls(),
                  ),
                  // Expanded(
                  //   flex: 5,
                  //   child: Column(
                  //     children: <Widget>[
                  //       Container(
                  //         height: 32,
                  //         width: double.infinity,
                  //         alignment: Alignment.center,
                  //         color: const Color(0xFFF5F5F5),
                  //         child: FusionAppText(
                  //           text: "CONTROLS",
                  //           style: Theme.of(context).textTheme.labelMedium,
                  //         ),
                  //       ),

                  //       const SizedBox(height: 48),

                  //       Flexible(
                  //         child: Container(
                  //           margin: const EdgeInsets.all(8),
                  //           decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E5E5), width: 1)),
                  //           child: SingleChildScrollView(
                  //             controller: _controlsController,
                  //             physics: const ClampingScrollPhysics(),
                  //             padding: EdgeInsets.zero,
                  //             child: Column(
                  //               children: <Widget>[
                  //                 ...List<Widget>.generate(20, (int index) {
                  //                   return Container(
                  //                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  //                     decoration: const BoxDecoration(
                  //                       border: Border(
                  //                         bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                  //                       ),
                  //                     ),
                  //                     child: Row(
                  //                       spacing: 6,
                  //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //                       children: <Widget>[
                  //                         Expanded(
                  //                           flex: 4,
                  //                           child: Container(
                  //                             height: 28,
                  //                             width: double.infinity,
                  //                             alignment: Alignment.center,
                  //                             padding: const EdgeInsets.all(2),
                  //                             decoration: BoxDecoration(
                  //                               color: const Color(0xFFF5F5F5),
                  //                               border: Border.all(color: const Color(0xFFE5E5E5)),
                  //                               borderRadius: const BorderRadius.all(Radius.circular(4)),
                  //                             ),
                  //                             child: Center(
                  //                               child: FusionAppText(
                  //                                 text: "Music _0$index",
                  //                                 maxLine: 1,
                  //                                 style: Theme.of(context).textTheme.labelSmall,
                  //                               ),
                  //                             ),
                  //                           ),
                  //                         ),
                  //                         Container(
                  //                           height: 28,
                  //                           width: 28,
                  //                           alignment: Alignment.center,
                  //                           // padding: padding ?? EdgeInsets.all(outerPadding),
                  //                           decoration: BoxDecoration(
                  //                             color: const Color(0xFFF5F5F5),
                  //                             borderRadius: BorderRadius.circular(4),
                  //                             border: Border.all(color: inactiveColor),
                  //                           ),
                  //                           child: SvgPicture.asset(
                  //                             'assets/svg/volume.svg',
                  //                             width: 16,
                  //                             height: 16,
                  //                           ),
                  //                         ),
                  //                         const PBTextField(
                  //                           hintText: "0.0",
                  //                           borderRadius: 8,
                  //                           width: 54,
                  //                           height: 28,
                  //                         ),
                  //                         const SizedBox(),
                  //                       ],
                  //                     ),
                  //                   );
                  //                 }),
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const VerticalDivider(width: 1, color: Colors.black12),

                  // Expanded(
                  //   flex: 2,
                  //   child: Column(
                  //     children: <Widget>[
                  //       Container(
                  //         height: 32,
                  //         width: double.infinity,
                  //         alignment: Alignment.center,
                  //         color: const Color(0xFFF5F5F5),
                  //         child: FusionAppText(
                  //           text: "LEFT",
                  //           style: Theme.of(context).textTheme.labelMedium,
                  //         ),
                  //       ),

                  //       const NeumorphicAudioToggleButton(
                  //         isActive: false,
                  //         width: 72,
                  //         height: 28,
                  //         borderRadius: 8,
                  //         iconSize: 16,
                  //       ),

                  //       Flexible(
                  //         child: Container(
                  //           margin: const EdgeInsets.all(8),
                  //           decoration: BoxDecoration(
                  //             // color: const Color(0xFFF5F5F5),
                  //             border: Border.all(color: Colors.black12, width: 1),
                  //           ),
                  //           child: SingleChildScrollView(
                  //             controller: _leftController,
                  //             physics: const ClampingScrollPhysics(),
                  //             padding: EdgeInsets.zero,
                  //             child: Column(
                  //               children: <Widget>[
                  //                 ...List<Widget>.generate(20, (int index) {
                  //                   return Container(
                  //                     height: 40,
                  //                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  //                     decoration: const BoxDecoration(
                  //                       border: Border(
                  //                         bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                  //                       ),
                  //                     ),
                  //                     child: const PBTextField(
                  //                       hintText: "0.0",
                  //                       borderRadius: 8,
                  //                       height: 24,
                  //                     ),
                  //                   );
                  //                 }),
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const VerticalDivider(width: 1, color: Colors.black12),

                  // Expanded(
                  //   flex: 2,
                  //   child: Column(
                  //     children: <Widget>[
                  //       Container(
                  //         height: 32,
                  //         width: double.infinity,
                  //         alignment: Alignment.center,
                  //         color: const Color(0xFFF5F5F5),
                  //         child: FusionAppText(
                  //           text: "RIGHT",
                  //           style: Theme.of(context).textTheme.labelMedium,
                  //         ),
                  //       ),

                  //       const NeumorphicAudioToggleButton(
                  //         isActive: true,
                  //         width: 72,
                  //         height: 28,
                  //         borderRadius: 8,
                  //         iconSize: 16,
                  //       ),

                  //       Flexible(
                  //         child: Container(
                  //           margin: const EdgeInsets.all(8),
                  //           decoration: BoxDecoration(
                  //             // color: const Color(0xFFF5F5F5),
                  //             border: Border.all(color: Colors.black12, width: 1),
                  //           ),
                  //           child: SingleChildScrollView(
                  //             controller: _rightController,
                  //             physics: const ClampingScrollPhysics(),
                  //             padding: EdgeInsets.zero,
                  //             child: Column(
                  //               children: <Widget>[
                  //                 ...List<Widget>.generate(5, (int index) {
                  //                   return Container(
                  //                     height: 40,
                  //                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  //                     decoration: const BoxDecoration(
                  //                       border: Border(
                  //                         bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                  //                       ),
                  //                     ),
                  //                     child: const PBTextField(
                  //                       hintText: "0.0",
                  //                       borderRadius: 8,
                  //                       height: 24,
                  //                     ),
                  //                   );
                  //                 }),
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // VerticalDivider(width: 1, color: Colors.black12),

                  // MiniMatrixMixScenes(),
                  // VerticalDivider(width: 1, color: Colors.black12),
                  // Expanded(flex: 3, child: MiniMatrixVolumneControl()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniMatrixControls extends StatelessWidget {
  const MiniMatrixControls({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // HEADING
        Expanded(
          flex: 5,
          child: Container(
            height: 32,
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xFFF5F5F5),
            child: FusionAppText(
              text: "CONTROLS",
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 32,
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xFFF5F5F5),
            child: FusionAppText(
              text: "LEFT",
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 32,
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xFFF5F5F5),
            child: FusionAppText(
              text: "LEFT",
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class MiniMatrixMixScenes extends StatelessWidget {
  const MiniMatrixMixScenes({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: const Color(0xFFF5F5F5),
      child: Column(
        spacing: 10,
        children: <Widget>[
          const SizedBox(),
          FusionAppText(
            text: "MIX SCENES",
            style: Theme.of(context).textTheme.labelMedium,
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[
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
            ),
          ),
        ],
      ),
    );
  }
}

class MiniMatrixVolumneControl extends StatelessWidget {
  const MiniMatrixVolumneControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 32,
          width: double.infinity,
          alignment: Alignment.center,
          color: const Color(0xFFF5F5F5),
          child: FusionAppText(
            text: "ZONE VOLUME",
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),

        const SizedBox(height: 10),
        const PBTextField(
          hintText: "0.0",
          borderRadius: 8,
          height: 28,
          width: 100,
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

        const NeumorphicAudioToggleButton(
          isActive: false,
          width: 72,
          height: 28,
          borderRadius: 8,
          iconSize: 16,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
