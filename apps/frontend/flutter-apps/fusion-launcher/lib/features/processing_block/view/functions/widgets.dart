import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item_param.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_button.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_slider.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_textfield.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NeumorphicAudioToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double borderRadius;
  final double iconSize;

  const NeumorphicAudioToggleButton({
    super.key,
    required this.isActive,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius = 12,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(borderRadius),
        clipBehavior: isActive ? Clip.hardEdge : Clip.none,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          height: height ?? 50,
          width: width ?? double.infinity,
          child: Container(
            height: double.infinity,
            width: double.infinity,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            clipBehavior: isActive ? Clip.hardEdge : Clip.none,
            decoration: BoxDecoration(
              borderRadius: BorderRadiusGeometry.circular(borderRadius),
              boxShadow: getNeumorphismBoxShadows(
                inner: isActive,
                color: backgroundColor,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/volume.svg',
                height: iconSize,
                width: iconSize,
                // ignore: deprecated_member_use
                color: isActive ? Colors.black : const Color(0xFFE2E2E2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicPopupButton extends StatefulWidget {
  final String? hintText;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final List<String> options;
  final ValueChanged<String>? onChanged;
  final double borderRadius;

  const NeumorphicPopupButton({
    super.key,
    this.hintText,
    this.height,
    this.width,
    this.backgroundColor,
    this.options = const <String>[],
    this.onChanged,
    this.borderRadius = 8,
  });

  @override
  State<NeumorphicPopupButton> createState() => _NeumorphicPopupButtonState();
}

class _NeumorphicPopupButtonState extends State<NeumorphicPopupButton> {
  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width,
        height: widget.height ?? 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isFocused ? null : getNeumorphismBoxShadows(inner: true),
          border: isFocused ? Border.all(color: Colors.black12, width: 2) : null,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                // controller: widget.controller,
                textAlign: TextAlign.center,
                focusNode: _focusNode,
                style: Theme.of(context).textTheme.labelLarge,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText ?? 'preset name',
                  isDense: true,
                  hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
                  contentPadding: const EdgeInsets.all(0),
                ),
                onChanged: widget.onChanged,
              ),
            ),
            const VerticalDivider(color: Colors.black12, thickness: 1, width: 1),
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: const PopupMenuThemeData(
                  color: Color(0xFFF5F5F5),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                ),
                splashColor: Colors.transparent, // Disable ripple
                highlightColor: Colors.transparent, // Disable tap highlight
                hoverColor: Colors.transparent, // Disable hover color
              ),
              child: PopupMenuButton<String>(
                color: const Color(0xFFF5F5F5),
                shadowColor: Colors.transparent,
                position: PopupMenuPosition.under,
                tooltip: '',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
                offset: const Offset(0, 10),
                padding: EdgeInsets.zero,
                menuPadding: EdgeInsets.zero,
                clipBehavior: Clip.none,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: const EdgeInsets.all(8).copyWith(right: 0),
                      child: Builder(
                        builder: (BuildContext context) {
                          if (widget.options.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FusionAppText(
                                text: "No presets saved",
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ...widget.options.map(
                                (String value) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: FusionAppText(
                                    text: value,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ];
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0).copyWith(right: 8),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 16,
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

class SliderAndMeterWithNameAndValueWidget extends StatelessWidget {
  final String title;
  final String dbValue;
  final bool isAUdioToggleActive;

  const SliderAndMeterWithNameAndValueWidget({
    super.key,
    required this.title,
    required this.dbValue,
    this.isAUdioToggleActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        Container(
          height: 32,
          width: double.infinity,
          alignment: Alignment.center,
          color: const Color(0xFFF5F5F5),
          child: FusionAppText(
            text: title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),

        SizedBox(
          width: 100,
          height: 32,
          child: PBTextField(
            hintText: dbValue,
            borderRadius: 8,
            height: 32,
            width: 100,
            // style: Theme.of(context).textTheme.labelMedium,
          ),
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

class JustSliderAndMeterWidget extends StatelessWidget {
  const JustSliderAndMeterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
