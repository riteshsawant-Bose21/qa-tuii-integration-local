import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item_param.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_radio.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_slider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ProcessingBlockPage extends StatelessWidget {
  const ProcessingBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    // return DynamicGridView(
    //   layout: PBLayout.fromMap(SampleData.sampleData),
    // );

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const SourceMixZoneControlPanel();
              },
            );
          },
          child: const Text("data"),
        ),
      ),
    );
  }
}

class SourceMixZoneControlPanel extends StatefulWidget {
  const SourceMixZoneControlPanel({super.key});

  @override
  State<SourceMixZoneControlPanel> createState() => _SourceMixZoneControlPanelState();
}

class _SourceMixZoneControlPanelState extends State<SourceMixZoneControlPanel> {
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
              height: 50,
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: "ZONE CONTROL PANEL - SOURCE SELECT",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
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
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.all(12),
                          child: FusionAppText(
                            text: "SOURCE SELECT",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            spacing: 10,
                            children: <Widget>[
                              const Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.surround_sound,
                                    size: 16,
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
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.all(12),
                          child: FusionAppText(
                            text: "ZONE VOLUME",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),

                        SizedBox(
                          width: 150,
                          height: 50,
                          child: NeumorphicText(
                            "-20db",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: <Widget>[
                                const Spacer(),
                                Expanded(
                                  flex: 2,
                                  child: ValueListenableBuilder<num>(
                                    valueListenable: valueNotifier,
                                    builder: (BuildContext context, num value, Widget? child) {
                                      return PBSlider(
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
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
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
                                ),
                                const Spacer(),
                              ],
                            ),
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
              height: 50,
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: "ZONE CONTROL PANEL - SOURCE SELECT",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
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
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.all(12),
                          child: FusionAppText(
                            text: "SOURCE SELECT",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            spacing: 10,
                            children: <Widget>[
                              const Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.surround_sound,
                                    size: 16,
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
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.all(12),
                          child: FusionAppText(
                            text: "ZONE VOLUME",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),

                        SizedBox(
                          width: 150,
                          height: 50,
                          child: NeumorphicText(
                            "-20db",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: ValueListenableBuilder<num>(
                                    valueListenable: valueNotifier,
                                    builder: (BuildContext context, num value, Widget? child) {
                                      return PBSlider(
                                        item: PBItem(
                                          id: '12213',
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
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: PBMeter(
                                      item: PBItem(
                                        id: '4353',
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
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 150,
                          height: 50,
                          child: NeumorphicButton(
                            child: SvgPicture.asset(
                              'assets/svg/volume.svg',
                              height: 24,
                              width: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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

class NeumorphicText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? height;
  final double? width;

  const NeumorphicText(
    this.text, {
    this.style,
    super.key,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    const double bRadius = 12;
    const double blurRadius = 10;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(bRadius),
        child: Container(
          height: height ?? 50,
          width: width ?? double.infinity,
          color: const Color(0xFFF5F5F5),
          child: Container(
            height: double.infinity,
            width: double.infinity,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.black12, blurRadius: blurRadius, offset: Offset(0, -2)),
                BoxShadow(color: Colors.black12, blurRadius: blurRadius, offset: Offset(-2, 0)),
                BoxShadow(color: Colors.white, blurRadius: blurRadius),
                BoxShadow(color: Colors.white, blurRadius: blurRadius, offset: Offset(10, 0)),
                BoxShadow(color: Colors.white, blurRadius: blurRadius, offset: Offset(5, 5)),
              ],
            ),
            child: FusionAppText(
              text: text,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onTap,
    this.height,
    this.width,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    const double bRadius = 12;
    const double blurRadius = 10;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(bRadius),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            height: widget.height ?? 50,
            width: widget.width ?? double.infinity,
            color: const Color(0xFFF5F5F5),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  if (!_isPressed) ...<BoxShadow>[
                    const BoxShadow(color: Colors.black12, blurRadius: blurRadius, offset: Offset(0, -5)),
                    const BoxShadow(color: Colors.black12, blurRadius: blurRadius, offset: Offset(-5, 0)),
                    const BoxShadow(color: Colors.white, blurRadius: blurRadius),
                    const BoxShadow(color: Colors.white, blurRadius: blurRadius, offset: Offset(10, 0)),
                    const BoxShadow(color: Colors.white, blurRadius: blurRadius, offset: Offset(5, 5)),
                  ] else ...<BoxShadow>[
                    const BoxShadow(color: Colors.black12, blurRadius: blurRadius, offset: Offset(10, 0)),
                    const BoxShadow(color: Colors.black12, blurRadius: blurRadius, offset: Offset(5, 5)),
                    const BoxShadow(color: Colors.white, blurRadius: blurRadius),
                    const BoxShadow(color: Colors.white, blurRadius: blurRadius, offset: Offset(0, -2)),
                    const BoxShadow(color: Colors.white, blurRadius: blurRadius, offset: Offset(-2, 0)),
                  ],
                ],
              ),
              child: Center(
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
