import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';

/// The default layout of Color Picker.
class ColorPicker extends StatefulWidget {
  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerHsvColor,
    this.onHsvColorChanged,
    this.paletteType = PaletteType.hsvWithHue,
    this.enableAlpha = true,
    @Deprecated('Use empty list in [labelTypes] to disable label.') this.showLabel = true,
    this.labelTypes = const <ColorLabelType>[ColorLabelType.rgb, ColorLabelType.hsv, ColorLabelType.hsl],
    @Deprecated('Use Theme.of(context).textTheme.bodyText1 & 2 to alter text style.') this.labelTextStyle,
    this.displayThumbColor = false,
    this.portraitOnly = false,
    this.colorPickerWidth = 300.0,
    this.pickerAreaHeightPercent = 1.0,
    this.pickerAreaBorderRadius = const BorderRadius.all(Radius.zero),
    this.hexInputBar = false,
    this.hexInputController,
    this.colorHistory,
    this.onHistoryChanged,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final HSVColor? pickerHsvColor;
  final ValueChanged<HSVColor>? onHsvColorChanged;
  final PaletteType paletteType;
  final bool enableAlpha;
  final bool showLabel;
  final List<ColorLabelType> labelTypes;
  final TextStyle? labelTextStyle;
  final bool displayThumbColor;
  final bool portraitOnly;
  final double colorPickerWidth;
  final double pickerAreaHeightPercent;
  final BorderRadius pickerAreaBorderRadius;
  final bool hexInputBar;

  final TextEditingController? hexInputController;
  final List<Color>? colorHistory;
  final ValueChanged<List<Color>>? onHistoryChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);
  List<Color> colorHistory = <Color>[];

  @override
  void initState() {
    currentHsvColor = (widget.pickerHsvColor != null) ? widget.pickerHsvColor as HSVColor : HSVColor.fromColor(widget.pickerColor);
    // If there's no initial text in `hexInputController`,
    if (widget.hexInputController?.text.isEmpty == true) {
      // set it to the current's color HEX value.
      widget.hexInputController?.text = colorToHex(
        currentHsvColor.toColor(),
        enableAlpha: widget.enableAlpha,
      );
    }
    // Listen to the text input, If there is an `hexInputController` provided.
    widget.hexInputController?.addListener(colorPickerTextInputListener);
    if (widget.colorHistory != null && widget.onHistoryChanged != null) {
      colorHistory = widget.colorHistory ?? <Color>[];
    }
    super.initState();
  }

  @override
  void didUpdateWidget(ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = (widget.pickerHsvColor != null) ? widget.pickerHsvColor as HSVColor : HSVColor.fromColor(widget.pickerColor);
  }

  void colorPickerTextInputListener() {
    // It can't be null really, since it's only listening if the controller
    // is provided, but it may help to calm the Dart analyzer in the future.
    if (widget.hexInputController == null) return;
    // If a user is inserting/typing any text — try to get the color value from it,
    // and interpret its transparency, dependent on the widget's settings.
    final Color? color = colorFromHex(widget.hexInputController!.text, enableAlpha: widget.enableAlpha);
    // If it's the valid color:
    if (color != null) {
      // set it as the current color and
      setState(() => currentHsvColor = HSVColor.fromColor(color));
      // notify with a callback.
      widget.onColorChanged(color);
      if (widget.onHsvColorChanged != null) widget.onHsvColorChanged!(currentHsvColor);
    }
  }

  @override
  void dispose() {
    widget.hexInputController?.removeListener(colorPickerTextInputListener);
    super.dispose();
  }

  Widget colorPickerSlider(TrackType trackType) {
    return ColorPickerSlider(
      trackType,
      currentHsvColor,
      (HSVColor color) {
        // Update text in `hexInputController` if provided.
        widget.hexInputController?.text = colorToHex(color.toColor(), enableAlpha: widget.enableAlpha);
        setState(() => currentHsvColor = color);
        widget.onColorChanged(currentHsvColor.toColor());
        if (widget.onHsvColorChanged != null) widget.onHsvColorChanged!(currentHsvColor);
      },
      displayThumbColor: widget.displayThumbColor,
    );
  }

  void onColorChanging(HSVColor color) {
    // Update text in `hexInputController` if provided.
    widget.hexInputController?.text = colorToHex(color.toColor(), enableAlpha: widget.enableAlpha);
    setState(() => currentHsvColor = color);
    widget.onColorChanged(currentHsvColor.toColor());
    if (widget.onHsvColorChanged != null) widget.onHsvColorChanged!(currentHsvColor);
  }

  Widget colorPicker() {
    return ClipRRect(
      borderRadius: widget.pickerAreaBorderRadius,
      child: Padding(
        padding: EdgeInsets.all(widget.paletteType == PaletteType.hueWheel ? 10 : 0),
        // child: ColorPickerArea(currentHsvColor, onColorChanging, widget.paletteType),
        child: ColorPicker(
          pickerColor: Colors.black,
          onColorChanged: (Color value) {
            //
          },
        ),
      ),
    );
  }

  Widget sliderByPaletteType() {
    switch (widget.paletteType) {
      case PaletteType.hsv:
      case PaletteType.hsvWithHue:
      case PaletteType.hsl:
      case PaletteType.hslWithHue:
        return colorPickerSlider(TrackType.hue);
      case PaletteType.hsvWithValue:
      case PaletteType.hueWheel:
        return colorPickerSlider(TrackType.value);
      case PaletteType.hsvWithSaturation:
        return colorPickerSlider(TrackType.saturation);
      case PaletteType.hslWithLightness:
        return colorPickerSlider(TrackType.lightness);
      case PaletteType.hslWithSaturation:
        return colorPickerSlider(TrackType.saturationForHSL);
      case PaletteType.rgbWithBlue:
        return colorPickerSlider(TrackType.blue);
      case PaletteType.rgbWithGreen:
        return colorPickerSlider(TrackType.green);
      case PaletteType.rgbWithRed:
        return colorPickerSlider(TrackType.red);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: widget.colorPickerWidth,
          height: widget.colorPickerWidth * widget.pickerAreaHeightPercent,
          child: colorPicker(),
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  ColorIndicator(currentHsvColor),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        sliderByPaletteType(),
                        if (widget.enableAlpha) colorPickerSlider(TrackType.alpha),
                      ],
                    ),
                  ),
                ],
              ),
              if (colorHistory.isNotEmpty)
                SizedBox(
                  width: widget.colorPickerWidth,
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (Color color in colorHistory)
                        Padding(
                          key: Key(color.hashCode.toString()),
                          padding: const EdgeInsets.fromLTRB(15, 18, 0, 0),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => onColorChanging(HSVColor.fromColor(color)),
                              onLongPress: () {
                                if (colorHistory.remove(color)) {
                                  widget.onHistoryChanged!(colorHistory);
                                  setState(() {});
                                }
                              },
                              child: ColorIndicator(HSVColor.fromColor(color), width: 30, height: 30),
                            ),
                          ),
                        ),
                      const SizedBox(width: 15),
                    ],
                  ),
                ),
              const SizedBox(height: 20.0),
              if (widget.showLabel && widget.labelTypes.isNotEmpty)
                FittedBox(
                  child: ColorPickerLabel(
                    currentHsvColor,
                    enableAlpha: widget.enableAlpha,
                    textStyle: widget.labelTextStyle,
                    colorLabelTypes: widget.labelTypes,
                  ),
                ),
              if (widget.hexInputBar)
                ColorPickerInput(
                  currentHsvColor.toColor(),
                  (Color color) {
                    setState(() => currentHsvColor = HSVColor.fromColor(color));
                    widget.onColorChanged(currentHsvColor.toColor());
                    if (widget.onHsvColorChanged != null) widget.onHsvColorChanged!(currentHsvColor);
                  },
                  enableAlpha: widget.enableAlpha,
                  embeddedText: false,
                ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Color Picker with sliders only. Support HSV, HSL and RGB color model.
class SlidePicker extends StatefulWidget {
  const SlidePicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.colorModel = ColorModel.rgb,
    this.enableAlpha = true,
    this.sliderSize = const Size(260, 40),
    this.showSliderText = true,
    @Deprecated('Use Theme.of(context).textTheme.bodyText1 & 2 to alter text style.') this.sliderTextStyle,
    this.showParams = true,
    @Deprecated('Use empty list in [labelTypes] to disable label.') this.showLabel = true,
    this.labelTypes = const <ColorLabelType>[],
    @Deprecated('Use Theme.of(context).textTheme.bodyText1 & 2 to alter text style.') this.labelTextStyle,
    this.showIndicator = true,
    this.indicatorSize = const Size(280, 50),
    this.indicatorAlignmentBegin = const Alignment(-1.0, -3.0),
    this.indicatorAlignmentEnd = const Alignment(1.0, 3.0),
    this.displayThumbColor = true,
    this.indicatorBorderRadius = const BorderRadius.all(Radius.zero),
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final ColorModel colorModel;
  final bool enableAlpha;
  final Size sliderSize;
  final bool showSliderText;
  final TextStyle? sliderTextStyle;
  final bool showLabel;
  final bool showParams;
  final List<ColorLabelType> labelTypes;
  final TextStyle? labelTextStyle;
  final bool showIndicator;
  final Size indicatorSize;
  final AlignmentGeometry indicatorAlignmentBegin;
  final AlignmentGeometry indicatorAlignmentEnd;
  final bool displayThumbColor;
  final BorderRadius indicatorBorderRadius;

  @override
  State<StatefulWidget> createState() => _SlidePickerState();
}

class _SlidePickerState extends State<SlidePicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    super.initState();
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  @override
  void didUpdateWidget(SlidePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  Widget colorPickerSlider(TrackType trackType) {
    return ColorPickerSlider(
      trackType,
      currentHsvColor,
      (HSVColor color) {
        setState(() => currentHsvColor = color);
        widget.onColorChanged(currentHsvColor.toColor());
      },
      displayThumbColor: widget.displayThumbColor,
      fullThumbColor: true,
    );
  }

  Widget indicator() {
    return ClipRRect(
      borderRadius: widget.indicatorBorderRadius,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GestureDetector(
        onTap: () {
          setState(() => currentHsvColor = HSVColor.fromColor(widget.pickerColor));
          widget.onColorChanged(currentHsvColor.toColor());
        },
        child: Container(
          width: widget.indicatorSize.width,
          height: widget.indicatorSize.height,
          margin: const EdgeInsets.only(bottom: 15.0),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                widget.pickerColor,
                widget.pickerColor,
                currentHsvColor.toColor(),
                currentHsvColor.toColor(),
              ],
              begin: widget.indicatorAlignmentBegin,
              end: widget.indicatorAlignmentEnd,
              stops: const <double>[0.0, 0.5, 0.5, 1.0],
            ),
          ),
          child: const CustomPaint(painter: CheckerPainter()),
        ),
      ),
    );
  }

  String getColorParams(int pos) {
    assert(pos >= 0 && pos < 4);
    if (widget.colorModel == ColorModel.rgb) {
      final Color color = currentHsvColor.toColor();
      return <String>[
        color.red.toString(),
        color.green.toString(),
        color.blue.toString(),
        '${(color.opacity * 100).round()}',
      ][pos];
    } else if (widget.colorModel == ColorModel.hsv) {
      return <String>[
        currentHsvColor.hue.round().toString(),
        (currentHsvColor.saturation * 100).round().toString(),
        (currentHsvColor.value * 100).round().toString(),
        (currentHsvColor.alpha * 100).round().toString(),
      ][pos];
    } else if (widget.colorModel == ColorModel.hsl) {
      final HSLColor hslColor = hsvToHsl(currentHsvColor);
      return <String>[
        hslColor.hue.round().toString(),
        (hslColor.saturation * 100).round().toString(),
        (hslColor.lightness * 100).round().toString(),
        (currentHsvColor.alpha * 100).round().toString(),
      ][pos];
    } else {
      return '??';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = widget.labelTextStyle?.fontSize ?? 14;

    final List<TrackType> trackTypes = <TrackType>[
      if (widget.colorModel == ColorModel.hsv) ...<TrackType>[TrackType.hue, TrackType.saturation, TrackType.value],
      if (widget.colorModel == ColorModel.hsl) ...<TrackType>[TrackType.hue, TrackType.saturationForHSL, TrackType.lightness],
      if (widget.colorModel == ColorModel.rgb) ...<TrackType>[TrackType.red, TrackType.green, TrackType.blue],
      if (widget.enableAlpha) ...<TrackType>[TrackType.alpha],
    ];
    final List<SizedBox> sliders = <SizedBox>[
      for (TrackType trackType in trackTypes)
        SizedBox(
          width: widget.sliderSize.width,
          height: widget.sliderSize.height,
          child: Row(
            children: <Widget>[
              if (widget.showSliderText)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    trackType.toString().split('.').last[0].toUpperCase(),
                    style: widget.sliderTextStyle ?? Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              Expanded(child: colorPickerSlider(trackType)),
              if (widget.showParams)
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: fontSize * 2 + 5),
                  child: Text(
                    getColorParams(trackTypes.indexOf(trackType)),
                    style: widget.sliderTextStyle ?? Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (widget.showIndicator) indicator(),
        if (!widget.showIndicator) const SizedBox(height: 20),
        ...sliders,
        const SizedBox(height: 20.0),
        if (widget.showLabel && widget.labelTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ColorPickerLabel(
              currentHsvColor,
              enableAlpha: widget.enableAlpha,
              textStyle: widget.labelTextStyle,
              colorLabelTypes: widget.labelTypes,
            ),
          ),
      ],
    );
  }
}

/// The Color Picker with HUE Ring & HSV model.
class HueRingPicker extends StatefulWidget {
  const HueRingPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.portraitOnly = false,
    this.colorPickerHeight = 250.0,
    this.hueRingStrokeWidth = 20.0,
    this.enableAlpha = false,
    this.displayThumbColor = true,
    this.pickerAreaBorderRadius = const BorderRadius.all(Radius.zero),
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool portraitOnly;
  final double colorPickerHeight;
  final double hueRingStrokeWidth;
  final bool enableAlpha;
  final bool displayThumbColor;
  final BorderRadius pickerAreaBorderRadius;

  @override
  State<HueRingPicker> createState() => _HueRingPickerState();
}

class _HueRingPickerState extends State<HueRingPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    super.initState();
  }

  @override
  void didUpdateWidget(HueRingPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  void onColorChanging(HSVColor color) {
    setState(() => currentHsvColor = color);
    widget.onColorChanged(currentHsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait || widget.portraitOnly) {
      return Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: widget.pickerAreaBorderRadius,
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  // SizedBox(
                  //   width: widget.colorPickerHeight,
                  //   height: widget.colorPickerHeight,
                  //   child: ColorPickerHueRing(
                  //     currentHsvColor,
                  //     onColorChanging,
                  //     displayThumbColor: widget.displayThumbColor,
                  //     strokeWidth: widget.hueRingStrokeWidth,
                  //   ),
                  // ),
                  // SizedBox(
                  //   width: widget.colorPickerHeight / 1.6,
                  //   height: widget.colorPickerHeight / 1.6,
                  //   child: ColorPickerArea(currentHsvColor, onColorChanging, PaletteType.hsv),
                  // ),
                ],
              ),
            ),
          ),
          if (widget.enableAlpha)
            SizedBox(
              height: 40.0,
              width: widget.colorPickerHeight,
              child: ColorPickerSlider(
                TrackType.alpha,
                currentHsvColor,
                onColorChanging,
                displayThumbColor: widget.displayThumbColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 5.0, 10.0, 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(width: 10),
                ColorIndicator(currentHsvColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                    child: ColorPickerInput(
                      currentHsvColor.toColor(),
                      (Color color) {
                        setState(() => currentHsvColor = HSVColor.fromColor(color));
                        widget.onColorChanged(currentHsvColor.toColor());
                      },
                      enableAlpha: widget.enableAlpha,
                      embeddedText: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: widget.pickerAreaBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                alignment: AlignmentDirectional.topCenter,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      SizedBox(height: widget.colorPickerHeight / 8.5),
                      ColorIndicator(currentHsvColor),
                      const SizedBox(height: 10),
                      ColorPickerInput(
                        currentHsvColor.toColor(),
                        (Color color) {
                          setState(() => currentHsvColor = HSVColor.fromColor(color));
                          widget.onColorChanged(currentHsvColor.toColor());
                        },
                        enableAlpha: widget.enableAlpha,
                        embeddedText: true,
                        disable: true,
                      ),
                      if (widget.enableAlpha) const SizedBox(height: 5),
                      if (widget.enableAlpha)
                        SizedBox(
                          height: 40.0,
                          width: (widget.colorPickerHeight - widget.hueRingStrokeWidth * 2) / 2,
                          child: ColorPickerSlider(
                            TrackType.alpha,
                            currentHsvColor,
                            onColorChanging,
                            displayThumbColor: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}

/// Check if is good condition to use white foreground color by passing
/// the background color, and optional bias.
///
/// Reference:
///
/// Old: https://www.w3.org/TR/WCAG20-TECHS/G18.html
///
/// New: https://github.com/mchome/flutter_statusbarcolor/issues/40
bool useWhiteForeground(Color backgroundColor, {double bias = 0.0}) {
  // Old:
  // return 1.05 / (color.computeLuminance() + 0.05) > 4.5;

  // New:
  final int v = sqrt(pow(backgroundColor.red, 2) * 0.299 + pow(backgroundColor.green, 2) * 0.587 + pow(backgroundColor.blue, 2) * 0.114).round();
  return v < 130 + bias ? true : false;
}

/// Convert HSV to HSL
///
/// Reference: https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_HSL
HSLColor hsvToHsl(HSVColor color) {
  double s = 0.0;
  double l = 0.0;
  l = (2 - color.saturation) * color.value / 2;
  if (l != 0) {
    if (l == 1) {
      s = 0.0;
    } else if (l < 0.5) {
      s = color.saturation * color.value / (l * 2);
    } else {
      s = color.saturation * color.value / (2 - l * 2);
    }
  }
  return HSLColor.fromAHSL(
    color.alpha,
    color.hue,
    s.clamp(0.0, 1.0),
    l.clamp(0.0, 1.0),
  );
}

/// Convert HSL to HSV
///
/// Reference: https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_HSV
HSVColor hslToHsv(HSLColor color) {
  double s = 0.0;
  double v = 0.0;

  v = color.lightness + color.saturation * (color.lightness < 0.5 ? color.lightness : 1 - color.lightness);
  if (v != 0) s = 2 - 2 * color.lightness / v;

  return HSVColor.fromAHSV(
    color.alpha,
    color.hue,
    s.clamp(0.0, 1.0),
    v.clamp(0.0, 1.0),
  );
}

/// [RegExp] pattern for validation HEX color [String] inputs, allows only:
///
/// * exactly 1 to 8 digits in HEX format,
/// * only Latin A-F characters, case insensitive,
/// * and integer numbers 0,1,2,3,4,5,6,7,8,9,
/// * with optional hash (`#`) symbol at the beginning (not calculated in length).
///
/// ```dart
/// final RegExp hexInputValidator = RegExp(kValidHexPattern);
/// if (hexInputValidator.hasMatch(hex)) print('$hex might be a valid HEX color');
/// ```
/// Reference: https://en.wikipedia.org/wiki/Web_colors#Hex_triplet
const String kValidHexPattern = r'^#?[0-9a-fA-F]{1,8}';

/// [RegExp] pattern for validation complete HEX color [String], allows only:
///
/// * exactly 6 or 8 digits in HEX format,
/// * only Latin A-F characters, case insensitive,
/// * and integer numbers 0,1,2,3,4,5,6,7,8,9,
/// * with optional hash (`#`) symbol at the beginning (not calculated in length).
///
/// ```dart
/// final RegExp hexCompleteValidator = RegExp(kCompleteValidHexPattern);
/// if (hexCompleteValidator.hasMatch(hex)) print('$hex is valid HEX color');
/// ```
/// Reference: https://en.wikipedia.org/wiki/Web_colors#Hex_triplet
const String kCompleteValidHexPattern = r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$';

/// Try to convert text input or any [String] to valid [Color].
/// The [String] must be provided in one of those formats:
///
/// * RGB
/// * #RGB
/// * RRGGBB
/// * #RRGGBB
/// * AARRGGBB
/// * #AARRGGBB
///
/// Where: A stands for Alpha, R for Red, G for Green, and B for blue color.
/// It will only accept 3/6/8 long HEXs with an optional hash (`#`) at the beginning.
/// Allowed characters are Latin A-F case insensitive and numbers 0-9.
/// Optional [enableAlpha] can be provided (it's `true` by default). If it's set
/// to `false` transparency information (alpha channel) will be removed.
/// ```dart
/// /// // Valid 3 digit HEXs:
/// colorFromHex('abc') == Color(0xffaabbcc)
/// colorFromHex('ABc') == Color(0xffaabbcc)
/// colorFromHex('ABC') == Color(0xffaabbcc)
/// colorFromHex('#Abc') == Color(0xffaabbcc)
/// colorFromHex('#abc') == Color(0xffaabbcc)
/// colorFromHex('#ABC') == Color(0xffaabbcc)
/// // Valid 6 digit HEXs:
/// colorFromHex('aabbcc') == Color(0xffaabbcc)
/// colorFromHex('AABbcc') == Color(0xffaabbcc)
/// colorFromHex('AABBCC') == Color(0xffaabbcc)
/// colorFromHex('#AABbcc') == Color(0xffaabbcc)
/// colorFromHex('#aabbcc') == Color(0xffaabbcc)
/// colorFromHex('#AABBCC') == Color(0xffaabbcc)
/// // Valid 8 digit HEXs:
/// colorFromHex('ffaabbcc') == Color(0xffaabbcc)
/// colorFromHex('ffAABbcc') == Color(0xffaabbcc)
/// colorFromHex('ffAABBCC') == Color(0xffaabbcc)
/// colorFromHex('ffaabbcc', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('FFAAbbcc', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('ffAABBCC', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('FFaabbcc', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('#ffaabbcc') == Color(0xffaabbcc)
/// colorFromHex('#ffAABbcc') == Color(0xffaabbcc)
/// colorFromHex('#FFAABBCC') == Color(0xffaabbcc)
/// colorFromHex('#ffaabbcc', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('#FFAAbbcc', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('#ffAABBCC', enableAlpha: true) == Color(0xffaabbcc)
/// colorFromHex('#FFaabbcc', enableAlpha: true) == Color(0xffaabbcc)
/// // Invalid HEXs:
/// colorFromHex('bc') == null // length 2
/// colorFromHex('aabbc') == null // length 5
/// colorFromHex('#ffaabbccd') == null // length 9 (+#)
/// colorFromHex('aabbcx') == null // x character
/// colorFromHex('#aabbвв') == null // в non-latin character
/// colorFromHex('') == null // empty
/// ```
/// Reference: https://en.wikipedia.org/wiki/Web_colors#Hex_triplet
Color? colorFromHex(String inputString, {bool enableAlpha = true}) {
  // Registers validator for exactly 6 or 8 digits long HEX (with optional #).
  final RegExp hexValidator = RegExp(kCompleteValidHexPattern);
  // Validating input, if it does not match — it's not proper HEX.
  if (!hexValidator.hasMatch(inputString)) return null;
  // Remove optional hash if exists and convert HEX to UPPER CASE.
  String hexToParse = inputString.replaceFirst('#', '').toUpperCase();
  // It may allow HEXs with transparency information even if alpha is disabled,
  if (!enableAlpha && hexToParse.length == 8) {
    // but it will replace this info with 100% non-transparent value (FF).
    hexToParse = 'FF${hexToParse.substring(2)}';
  }
  // HEX may be provided in 3-digits format, let's just duplicate each letter.
  if (hexToParse.length == 3) {
    hexToParse = hexToParse.split('').expand((String i) => <String>[i * 2]).join();
  }
  // We will need 8 digits to parse the color, let's add missing digits.
  if (hexToParse.length == 6) hexToParse = 'FF$hexToParse';
  // HEX must be valid now, but as a precaution, it will just "try" to parse it.
  final int? intColorValue = int.tryParse(hexToParse, radix: 16);
  // If for some reason HEX is not valid — abort the operation, return nothing.
  if (intColorValue == null) return null;
  // Register output color for the last step.
  final Color color = Color(intColorValue);
  // Decide to return color with transparency information or not.
  return enableAlpha ? color : color.withAlpha(255);
}

/// Converts `dart:ui` [Color] to the 6/8 digits HEX [String].
///
/// Prefixes a hash (`#`) sign if [includeHashSign] is set to `true`.
/// The result will be provided as UPPER CASE, it can be changed via [toUpperCase]
/// flag set to `false` (default is `true`). Hex can be returned without alpha
/// channel information (transparency), with the [enableAlpha] flag set to `false`.
String colorToHex(
  Color color, {
  bool includeHashSign = false,
  bool enableAlpha = true,
  bool toUpperCase = true,
}) {
  final String hex =
      (includeHashSign ? '#' : '') + (enableAlpha ? _padRadix(color.alpha) : '') + _padRadix(color.red) + _padRadix(color.green) + _padRadix(color.blue);
  return toUpperCase ? hex.toUpperCase() : hex;
}

// Shorthand for padLeft of RadixString, DRY.
String _padRadix(int value) => value.toRadixString(16).padLeft(2, '0');

// Extension for String
extension ColorExtension1 on String {
  Color? toColor() {
    final Color? color = colorFromName(this);
    if (color != null) return color;
    return colorFromHex(this);
  }
}

// Extension from Color
extension ColorExtension2 on Color {
  String toHexString({
    bool includeHashSign = false,
    bool enableAlpha = true,
    bool toUpperCase = true,
  }) {
    return colorToHex(
      this,
      includeHashSign: includeHashSign,
      enableAlpha: enableAlpha,
      toUpperCase: toUpperCase,
    );
  }
}

/// Palette types for color picker area widget.
enum PaletteType {
  hsv,
  hsvWithHue,
  hsvWithValue,
  hsvWithSaturation,
  hsl,
  hslWithHue,
  hslWithLightness,
  hslWithSaturation,
  rgbWithBlue,
  rgbWithGreen,
  rgbWithRed,
  hueWheel,
}

/// Track types for slider picker.
enum TrackType {
  hue,
  saturation,
  saturationForHSL,
  value,
  lightness,
  red,
  green,
  blue,
  alpha,
}

/// Color information label type.
enum ColorLabelType { hex, rgb, hsv, hsl }

/// Types for slider picker widget.
enum ColorModel { rgb, hsv, hsl }
// enum ColorSpace { rgb, hsv, hsl, hsp, okhsv, okhsl, xyz, yuv, lab, lch, cmyk }

/// Painter for SV mixture.
class HSVWithHueColorPainter extends CustomPainter {
  const HSVWithHueColorPainter(this.hsvColor, {this.pointerColor});

  final HSVColor hsvColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Colors.white, Colors.black],
    );
    final Gradient gradientH = LinearGradient(
      colors: <Color>[
        Colors.white,
        HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = gradientH.createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * hsvColor.saturation, size.height * (1 - hsvColor.value)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hsvColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..blendMode = BlendMode.luminosity
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for HV mixture.
class HSVWithSaturationColorPainter extends CustomPainter {
  const HSVWithSaturationColorPainter(this.hsvColor, {this.pointerColor});

  final HSVColor hsvColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Colors.transparent, Colors.black],
    );
    final List<Color> colors = <Color>[
      HSVColor.fromAHSV(1.0, 0.0, hsvColor.saturation, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, 60.0, hsvColor.saturation, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, 120.0, hsvColor.saturation, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, 180.0, hsvColor.saturation, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, 240.0, hsvColor.saturation, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, 300.0, hsvColor.saturation, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, 360.0, hsvColor.saturation, 1.0).toColor(),
    ];
    final Gradient gradientH = LinearGradient(colors: colors);
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));

    canvas.drawCircle(
      Offset(
        size.width * hsvColor.hue / 360,
        size.height * (1 - hsvColor.value),
      ),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hsvColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for HS mixture.
class HSVWithValueColorPainter extends CustomPainter {
  const HSVWithValueColorPainter(this.hsvColor, {this.pointerColor});

  final HSVColor hsvColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Colors.transparent, Colors.white],
    );
    final List<Color> colors = <Color>[
      const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 60.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 120.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 180.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 240.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 300.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0).toColor(),
    ];
    final Gradient gradientH = LinearGradient(colors: colors);
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withOpacity(1 - hsvColor.value),
    );

    canvas.drawCircle(
      Offset(
        size.width * hsvColor.hue / 360,
        size.height * (1 - hsvColor.saturation),
      ),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hsvColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for SL mixture.
class HSLWithHueColorPainter extends CustomPainter {
  const HSLWithHueColorPainter(this.hslColor, {this.pointerColor});

  final HSLColor hslColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Gradient gradientH = LinearGradient(
      colors: <Color>[
        const Color(0xff808080),
        HSLColor.fromAHSL(1.0, hslColor.hue, 1.0, 0.5).toColor(),
      ],
    );
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: <double>[0.0, 0.5, 0.5, 1],
      colors: <Color>[
        Colors.white,
        Color(0x00ffffff),
        Colors.transparent,
        Colors.black,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));

    canvas.drawCircle(
      Offset(size.width * hslColor.saturation, size.height * (1 - hslColor.lightness)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hslColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for HL mixture.
class HSLWithSaturationColorPainter extends CustomPainter {
  const HSLWithSaturationColorPainter(this.hslColor, {this.pointerColor});

  final HSLColor hslColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final List<Color> colors = <Color>[
      HSLColor.fromAHSL(1.0, 0.0, hslColor.saturation, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, 60.0, hslColor.saturation, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, 120.0, hslColor.saturation, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, 180.0, hslColor.saturation, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, 240.0, hslColor.saturation, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, 300.0, hslColor.saturation, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, 360.0, hslColor.saturation, 0.5).toColor(),
    ];
    final Gradient gradientH = LinearGradient(colors: colors);
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: <double>[0.0, 0.5, 0.5, 1],
      colors: <Color>[
        Colors.white,
        Color(0x00ffffff),
        Colors.transparent,
        Colors.black,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));

    canvas.drawCircle(
      Offset(size.width * hslColor.hue / 360, size.height * (1 - hslColor.lightness)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hslColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for HS mixture.
class HSLWithLightnessColorPainter extends CustomPainter {
  const HSLWithLightnessColorPainter(this.hslColor, {this.pointerColor});

  final HSLColor hslColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final List<Color> colors = <Color>[
      const HSLColor.fromAHSL(1.0, 0.0, 1.0, 0.5).toColor(),
      const HSLColor.fromAHSL(1.0, 60.0, 1.0, 0.5).toColor(),
      const HSLColor.fromAHSL(1.0, 120.0, 1.0, 0.5).toColor(),
      const HSLColor.fromAHSL(1.0, 180.0, 1.0, 0.5).toColor(),
      const HSLColor.fromAHSL(1.0, 240.0, 1.0, 0.5).toColor(),
      const HSLColor.fromAHSL(1.0, 300.0, 1.0, 0.5).toColor(),
      const HSLColor.fromAHSL(1.0, 360.0, 1.0, 0.5).toColor(),
    ];
    final Gradient gradientH = LinearGradient(colors: colors);
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Colors.transparent,
        Color(0xFF808080),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withOpacity((1 - hslColor.lightness * 2).clamp(0, 1)),
    );
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white.withOpacity(((hslColor.lightness - 0.5) * 2).clamp(0, 1)),
    );

    canvas.drawCircle(
      Offset(size.width * hslColor.hue / 360, size.height * (1 - hslColor.saturation)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hslColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for GB mixture.
class RGBWithRedColorPainter extends CustomPainter {
  const RGBWithRedColorPainter(this.color, {this.pointerColor});

  final Color color;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Gradient gradientH = LinearGradient(
      colors: <Color>[
        Color.fromRGBO(color.red, 255, 0, 1.0),
        Color.fromRGBO(color.red, 255, 255, 1.0),
      ],
    );
    final Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.fromRGBO(color.red, 255, 255, 1.0),
        Color.fromRGBO(color.red, 0, 255, 1.0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = gradientV.createShader(rect)
        ..blendMode = BlendMode.multiply,
    );

    canvas.drawCircle(
      Offset(size.width * color.blue / 255, size.height * (1 - color.green / 255)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(color) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for RB mixture.
class RGBWithGreenColorPainter extends CustomPainter {
  const RGBWithGreenColorPainter(this.color, {this.pointerColor});

  final Color color;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Gradient gradientH = LinearGradient(
      colors: <Color>[
        Color.fromRGBO(255, color.green, 0, 1.0),
        Color.fromRGBO(255, color.green, 255, 1.0),
      ],
    );
    final Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.fromRGBO(255, color.green, 255, 1.0),
        Color.fromRGBO(0, color.green, 255, 1.0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = gradientV.createShader(rect)
        ..blendMode = BlendMode.multiply,
    );

    canvas.drawCircle(
      Offset(size.width * color.blue / 255, size.height * (1 - color.red / 255)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(color) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for RG mixture.
class RGBWithBlueColorPainter extends CustomPainter {
  const RGBWithBlueColorPainter(this.color, {this.pointerColor});

  final Color color;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Gradient gradientH = LinearGradient(
      colors: <Color>[
        Color.fromRGBO(0, 255, color.blue, 1.0),
        Color.fromRGBO(255, 255, color.blue, 1.0),
      ],
    );
    final Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.fromRGBO(255, 255, color.blue, 1.0),
        Color.fromRGBO(255, 0, color.blue, 1.0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = gradientV.createShader(rect)
        ..blendMode = BlendMode.multiply,
    );

    canvas.drawCircle(
      Offset(size.width * color.red / 255, size.height * (1 - color.green / 255)),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(color) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for hue color wheel.
class HUEColorWheelPainter extends CustomPainter {
  const HUEColorWheelPainter(this.hsvColor, {this.pointerColor});

  final HSVColor hsvColor;
  final Color? pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radio = size.width <= size.height ? size.width / 2 : size.height / 2;

    final List<Color> colors = <Color>[
      const HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 300.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 240.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 180.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 120.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 60.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0).toColor(),
    ];
    final Gradient gradientS = SweepGradient(colors: colors);
    const Gradient gradientR = RadialGradient(
      colors: <Color>[
        Colors.white,
        Color(0x00FFFFFF),
      ],
    );
    canvas.drawCircle(center, radio, Paint()..shader = gradientS.createShader(rect));
    canvas.drawCircle(center, radio, Paint()..shader = gradientR.createShader(rect));
    canvas.drawCircle(center, radio, Paint()..color = Colors.black.withOpacity(1 - hsvColor.value));

    canvas.drawCircle(
      Offset(
        center.dx + hsvColor.saturation * radio * cos((hsvColor.hue * pi / 180)),
        center.dy - hsvColor.saturation * radio * sin((hsvColor.hue * pi / 180)),
      ),
      size.height * 0.04,
      Paint()
        ..color = pointerColor ?? (useWhiteForeground(hsvColor.toColor()) ? Colors.white : Colors.black)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for hue ring.
class HueRingPainter extends CustomPainter {
  const HueRingPainter(this.hsvColor, {this.displayThumbColor = true, this.strokeWidth = 5});

  final HSVColor hsvColor;
  final bool displayThumbColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radio = size.width <= size.height ? size.width / 2 : size.height / 2;

    final List<Color> colors = <Color>[
      const HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 300.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 240.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 180.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 120.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 60.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0).toColor(),
    ];
    canvas.drawCircle(
      center,
      radio,
      Paint()
        ..shader = SweepGradient(colors: colors).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final Offset offset = Offset(
      center.dx + radio * cos((hsvColor.hue * pi / 180)),
      center.dy - radio * sin((hsvColor.hue * pi / 180)),
    );
    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: offset, radius: 12)), Colors.black, 3.0, true);
    canvas.drawCircle(
      offset,
      size.height * 0.04,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    if (displayThumbColor) {
      canvas.drawCircle(
        offset,
        size.height * 0.03,
        Paint()
          ..color = hsvColor.toColor()
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SliderLayout extends MultiChildLayoutDelegate {
  static const String track = 'track';
  static const String thumb = 'thumb';
  static const String gestureContainer = 'gesturecontainer';

  @override
  void performLayout(Size size) {
    layoutChild(
      track,
      BoxConstraints.tightFor(
        width: size.width - 30.0,
        height: size.height / 5,
      ),
    );
    positionChild(track, Offset(15.0, size.height * 0.4));
    layoutChild(
      thumb,
      BoxConstraints.tightFor(width: 5.0, height: size.height / 4),
    );
    positionChild(thumb, Offset(0.0, size.height * 0.4));
    layoutChild(
      gestureContainer,
      BoxConstraints.tightFor(width: size.width, height: size.height),
    );
    positionChild(gestureContainer, Offset.zero);
  }

  @override
  bool shouldRelayout(_SliderLayout oldDelegate) => false;
}

/// Painter for all kinds of track types.
class TrackPainter extends CustomPainter {
  const TrackPainter(this.trackType, this.hsvColor);

  final TrackType trackType;
  final HSVColor hsvColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    if (trackType == TrackType.alpha) {
      final Size chessSize = Size(size.height / 2, size.height / 2);
      final Paint chessPaintB = Paint()..color = const Color(0xffcccccc);
      final Paint chessPaintW = Paint()..color = Colors.white;
      List<void>.generate((size.height / chessSize.height).round(), (int y) {
        List<void>.generate((size.width / chessSize.width).round(), (int x) {
          canvas.drawRect(
            Offset(chessSize.width * x, chessSize.width * y) & chessSize,
            (x + y) % 2 != 0 ? chessPaintW : chessPaintB,
          );
        });
      });
    }

    switch (trackType) {
      case TrackType.hue:
        final List<Color> colors = <Color>[
          const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0).toColor(),
          const HSVColor.fromAHSV(1.0, 60.0, 1.0, 1.0).toColor(),
          const HSVColor.fromAHSV(1.0, 120.0, 1.0, 1.0).toColor(),
          const HSVColor.fromAHSV(1.0, 180.0, 1.0, 1.0).toColor(),
          const HSVColor.fromAHSV(1.0, 240.0, 1.0, 1.0).toColor(),
          const HSVColor.fromAHSV(1.0, 300.0, 1.0, 1.0).toColor(),
          const HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0).toColor(),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.saturation:
        final List<Color> colors = <Color>[
          HSVColor.fromAHSV(1.0, hsvColor.hue, 0.0, 1.0).toColor(),
          HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.saturationForHSL:
        final List<Color> colors = <Color>[
          HSLColor.fromAHSL(1.0, hsvColor.hue, 0.0, 0.5).toColor(),
          HSLColor.fromAHSL(1.0, hsvColor.hue, 1.0, 0.5).toColor(),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.value:
        final List<Color> colors = <Color>[
          HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 0.0).toColor(),
          HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.lightness:
        final List<Color> colors = <Color>[
          HSLColor.fromAHSL(1.0, hsvColor.hue, 1.0, 0.0).toColor(),
          HSLColor.fromAHSL(1.0, hsvColor.hue, 1.0, 0.5).toColor(),
          HSLColor.fromAHSL(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.red:
        final List<Color> colors = <Color>[
          hsvColor.toColor().withRed(0).withOpacity(1.0),
          hsvColor.toColor().withRed(255).withOpacity(1.0),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.green:
        final List<Color> colors = <Color>[
          hsvColor.toColor().withGreen(0).withOpacity(1.0),
          hsvColor.toColor().withGreen(255).withOpacity(1.0),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.blue:
        final List<Color> colors = <Color>[
          hsvColor.toColor().withBlue(0).withOpacity(1.0),
          hsvColor.toColor().withBlue(255).withOpacity(1.0),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
      case TrackType.alpha:
        final List<Color> colors = <Color>[
          hsvColor.toColor().withOpacity(0.0),
          hsvColor.toColor().withOpacity(1.0),
        ];
        final Gradient gradient = LinearGradient(colors: colors);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for thumb of slider.
class ThumbPainter extends CustomPainter {
  const ThumbPainter({this.thumbColor, this.fullThumbColor = false});

  final Color? thumbColor;
  final bool fullThumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      Path()..addOval(
        Rect.fromCircle(center: const Offset(0.5, 2.0), radius: size.width * 1.8),
      ),
      Colors.black,
      3.0,
      true,
    );
    canvas.drawCircle(
      Offset(0.0, size.height * 0.4),
      size.height,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    if (thumbColor != null) {
      canvas.drawCircle(
        Offset(0.0, size.height * 0.4),
        size.height * (fullThumbColor ? 1.0 : 0.65),
        Paint()
          ..color = thumbColor!
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for chess type alpha background in color indicator widget.
class IndicatorPainter extends CustomPainter {
  const IndicatorPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Size chessSize = Size(size.width / 10, size.height / 10);
    final Paint chessPaintB = Paint()..color = const Color(0xFFCCCCCC);
    final Paint chessPaintW = Paint()..color = Colors.white;
    List<void>.generate((size.height / chessSize.height).round(), (int y) {
      List<void>.generate((size.width / chessSize.width).round(), (int x) {
        canvas.drawRect(
          Offset(chessSize.width * x, chessSize.height * y) & chessSize,
          (x + y) % 2 != 0 ? chessPaintW : chessPaintB,
        );
      });
    });

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Painter for chess type alpha background in slider track widget.
class CheckerPainter extends CustomPainter {
  const CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Size chessSize = Size(size.height / 6, size.height / 6);
    final Paint chessPaintB = Paint()..color = const Color(0xffcccccc);
    final Paint chessPaintW = Paint()..color = Colors.white;
    List<void>.generate((size.height / chessSize.height).round(), (int y) {
      List<void>.generate((size.width / chessSize.width).round(), (int x) {
        canvas.drawRect(
          Offset(chessSize.width * x, chessSize.width * y) & chessSize,
          (x + y) % 2 != 0 ? chessPaintW : chessPaintB,
        );
      });
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Provide label for color information.
class ColorPickerLabel extends StatefulWidget {
  const ColorPickerLabel(
    this.hsvColor, {
    super.key,
    this.enableAlpha = true,
    this.colorLabelTypes = const <ColorLabelType>[ColorLabelType.rgb, ColorLabelType.hsv, ColorLabelType.hsl],
    this.textStyle,
  }) : assert(colorLabelTypes.length > 0);

  final HSVColor hsvColor;
  final bool enableAlpha;
  final TextStyle? textStyle;
  final List<ColorLabelType> colorLabelTypes;

  @override
  State<ColorPickerLabel> createState() => _ColorPickerLabelState();
}

class _ColorPickerLabelState extends State<ColorPickerLabel> {
  final Map<ColorLabelType, List<String>> _colorTypes = const <ColorLabelType, List<String>>{
    ColorLabelType.hex: <String>['R', 'G', 'B', 'A'],
    ColorLabelType.rgb: <String>['R', 'G', 'B', 'A'],
    ColorLabelType.hsv: <String>['H', 'S', 'V', 'A'],
    ColorLabelType.hsl: <String>['H', 'S', 'L', 'A'],
  };

  late ColorLabelType _colorType;

  @override
  void initState() {
    super.initState();
    _colorType = widget.colorLabelTypes[0];
  }

  List<String> colorValue(HSVColor hsvColor, ColorLabelType colorLabelType) {
    if (colorLabelType == ColorLabelType.hex) {
      final Color color = hsvColor.toColor();
      return <String>[
        color.red.toRadixString(16).toUpperCase().padLeft(2, '0'),
        color.green.toRadixString(16).toUpperCase().padLeft(2, '0'),
        color.blue.toRadixString(16).toUpperCase().padLeft(2, '0'),
        color.alpha.toRadixString(16).toUpperCase().padLeft(2, '0'),
      ];
    } else if (colorLabelType == ColorLabelType.rgb) {
      final Color color = hsvColor.toColor();
      return <String>[
        color.red.toString(),
        color.green.toString(),
        color.blue.toString(),
        '${(color.opacity * 100).round()}%',
      ];
    } else if (colorLabelType == ColorLabelType.hsv) {
      return <String>[
        '${hsvColor.hue.round()}°',
        '${(hsvColor.saturation * 100).round()}%',
        '${(hsvColor.value * 100).round()}%',
        '${(hsvColor.alpha * 100).round()}%',
      ];
    } else if (colorLabelType == ColorLabelType.hsl) {
      final HSLColor hslColor = hsvToHsl(hsvColor);
      return <String>[
        '${hslColor.hue.round()}°',
        '${(hslColor.saturation * 100).round()}%',
        '${(hslColor.lightness * 100).round()}%',
        '${(hsvColor.alpha * 100).round()}%',
      ];
    } else {
      return <String>['??', '??', '??', '??'];
    }
  }

  List<Widget> colorValueLabels() {
    double fontSize = 14;
    if (widget.textStyle != null && widget.textStyle?.fontSize != null) fontSize = widget.textStyle?.fontSize ?? 14;

    return <Widget>[
      for (String item in _colorTypes[_colorType] ?? <String>[])
        if (widget.enableAlpha || item != 'A')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: fontSize * 2),
              child: IntrinsicHeight(
                child: Column(
                  children: <Widget>[
                    Text(
                      item,
                      style: widget.textStyle ?? Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10.0),
                    Expanded(
                      child: Text(
                        colorValue(widget.hsvColor, _colorType)[_colorTypes[_colorType]!.indexOf(item)],
                        overflow: TextOverflow.ellipsis,
                        style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        DropdownButton<ColorLabelType>(
          value: _colorType,
          onChanged: (ColorLabelType? type) {
            if (type != null) setState(() => _colorType = type);
          },
          items: <DropdownMenuItem<ColorLabelType>>[
            for (ColorLabelType type in widget.colorLabelTypes)
              DropdownMenuItem<ColorLabelType>(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              ),
          ],
        ),
        const SizedBox(width: 10.0),
        ...colorValueLabels(),
      ],
    );
  }
}

/// Provide hex input wiget for 3/6/8 digits.
class ColorPickerInput extends StatefulWidget {
  const ColorPickerInput(
    this.color,
    this.onColorChanged, {
    super.key,
    this.enableAlpha = true,
    this.embeddedText = false,
    this.disable = false,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final bool enableAlpha;
  final bool embeddedText;
  final bool disable;

  @override
  State<ColorPickerInput> createState() => _ColorPickerInputState();
}

class _ColorPickerInputState extends State<ColorPickerInput> {
  TextEditingController textEditingController = TextEditingController();
  int inputColor = 0;

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (inputColor != widget.color.value) {
      // ignore: prefer_interpolation_to_compose_strings
      textEditingController.text =
          '#${widget.color.red.toRadixString(16).toUpperCase().padLeft(2, '0')}${widget.color.green.toRadixString(16).toUpperCase().padLeft(2, '0')}${widget.color.blue.toRadixString(16).toUpperCase().padLeft(2, '0')}${widget.enableAlpha ? widget.color.alpha.toRadixString(16).toUpperCase().padLeft(2, '0') : ''}';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!widget.embeddedText) Text('Hex', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 10),
          SizedBox(
            width: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * 10,
            child: TextField(
              enabled: !widget.disable,
              controller: textEditingController,
              inputFormatters: <TextInputFormatter>[
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
              ],
              decoration: InputDecoration(
                isDense: true,
                label: widget.embeddedText ? const Text('Hex') : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
              ),
              onChanged: (String value) {
                String input = value;
                if (value.length == 9) {
                  input = value.split('').getRange(7, 9).join() + value.split('').getRange(1, 7).join();
                }
                final Color? color = colorFromHex(input);
                if (color != null) {
                  widget.onColorChanged(color);
                  inputColor = color.value;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 9 track types for slider picker widget.
class ColorPickerSlider extends StatelessWidget {
  const ColorPickerSlider(
    this.trackType,
    this.hsvColor,
    this.onColorChanged, {
    super.key,
    this.displayThumbColor = false,
    this.fullThumbColor = false,
  });

  final TrackType trackType;
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onColorChanged;
  final bool displayThumbColor;
  final bool fullThumbColor;

  void slideEvent(RenderBox getBox, BoxConstraints box, Offset globalPosition) {
    final double localDx = getBox.globalToLocal(globalPosition).dx - 15.0;
    final double progress = localDx.clamp(0.0, box.maxWidth - 30.0) / (box.maxWidth - 30.0);
    switch (trackType) {
      case TrackType.hue:
        // 360 is the same as zero
        // if set to 360, sliding to end goes to zero
        onColorChanged(hsvColor.withHue(progress * 359));
        break;
      case TrackType.saturation:
        onColorChanged(hsvColor.withSaturation(progress));
        break;
      case TrackType.saturationForHSL:
        onColorChanged(hslToHsv(hsvToHsl(hsvColor).withSaturation(progress)));
        break;
      case TrackType.value:
        onColorChanged(hsvColor.withValue(progress));
        break;
      case TrackType.lightness:
        onColorChanged(hslToHsv(hsvToHsl(hsvColor).withLightness(progress)));
        break;
      case TrackType.red:
        onColorChanged(HSVColor.fromColor(hsvColor.toColor().withRed((progress * 0xff).round())));
        break;
      case TrackType.green:
        onColorChanged(HSVColor.fromColor(hsvColor.toColor().withGreen((progress * 0xff).round())));
        break;
      case TrackType.blue:
        onColorChanged(HSVColor.fromColor(hsvColor.toColor().withBlue((progress * 0xff).round())));
        break;
      case TrackType.alpha:
        onColorChanged(hsvColor.withAlpha(localDx.clamp(0.0, box.maxWidth - 30.0) / (box.maxWidth - 30.0)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        double thumbOffset = 15.0;
        Color thumbColor;
        switch (trackType) {
          case TrackType.hue:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.hue / 360;
            thumbColor = HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor();
            break;
          case TrackType.saturation:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.saturation;
            thumbColor = HSVColor.fromAHSV(1.0, hsvColor.hue, hsvColor.saturation, 1.0).toColor();
            break;
          case TrackType.saturationForHSL:
            thumbOffset += (box.maxWidth - 30.0) * hsvToHsl(hsvColor).saturation;
            thumbColor = HSLColor.fromAHSL(1.0, hsvColor.hue, hsvToHsl(hsvColor).saturation, 0.5).toColor();
            break;
          case TrackType.value:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.value;
            thumbColor = HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, hsvColor.value).toColor();
            break;
          case TrackType.lightness:
            thumbOffset += (box.maxWidth - 30.0) * hsvToHsl(hsvColor).lightness;
            thumbColor = HSLColor.fromAHSL(1.0, hsvColor.hue, 1.0, hsvToHsl(hsvColor).lightness).toColor();
            break;
          case TrackType.red:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.toColor().red / 0xff;
            thumbColor = hsvColor.toColor().withOpacity(1.0);
            break;
          case TrackType.green:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.toColor().green / 0xff;
            thumbColor = hsvColor.toColor().withOpacity(1.0);
            break;
          case TrackType.blue:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.toColor().blue / 0xff;
            thumbColor = hsvColor.toColor().withOpacity(1.0);
            break;
          case TrackType.alpha:
            thumbOffset += (box.maxWidth - 30.0) * hsvColor.toColor().opacity;
            thumbColor = hsvColor.toColor().withOpacity(hsvColor.alpha);
            break;
        }

        return CustomMultiChildLayout(
          delegate: _SliderLayout(),
          children: <Widget>[
            LayoutId(
              id: _SliderLayout.track,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                child: CustomPaint(
                  painter: TrackPainter(
                    trackType,
                    hsvColor,
                  ),
                ),
              ),
            ),
            LayoutId(
              id: _SliderLayout.thumb,
              child: Transform.translate(
                offset: Offset(thumbOffset, 0.0),
                child: CustomPaint(
                  painter: ThumbPainter(
                    thumbColor: displayThumbColor ? thumbColor : null,
                    fullThumbColor: fullThumbColor,
                  ),
                ),
              ),
            ),
            LayoutId(
              id: _SliderLayout.gestureContainer,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final RenderBox? getBox = context.findRenderObject() as RenderBox?;
                  return GestureDetector(
                    onPanDown: (DragDownDetails details) => getBox != null ? slideEvent(getBox, box, details.globalPosition) : null,
                    onPanUpdate: (DragUpdateDetails details) => getBox != null ? slideEvent(getBox, box, details.globalPosition) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Simple round color indicator.
class ColorIndicator extends StatelessWidget {
  const ColorIndicator(
    this.hsvColor, {
    super.key,
    this.width = 50.0,
    this.height = 50.0,
  });

  final HSVColor hsvColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xffdddddd)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(1000.0)),
        child: CustomPaint(painter: IndicatorPainter(hsvColor.toColor())),
      ),
    );
  }
}

/// Uppercase text formater
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
}

const Map<String, Color> x11Colors = <String, Color>{
  'aliceblue': Color(0xfff0f8ff),
  'antiquewhite': Color(0xfffaebd7),
  'aqua': Color(0xff00ffff),
  'aquamarine': Color(0xff7fffd4),
  'azure': Color(0xfff0ffff),
  'beige': Color(0xfff5f5dc),
  'bisque': Color(0xffffe4c4),
  'black': Color(0xff000000),
  'blanchedalmond': Color(0xffffebcd),
  'blue': Color(0xff0000ff),
  'blueviolet': Color(0xff8a2be2),
  'brown': Color(0xffa52a2a),
  'burlywood': Color(0xffdeb887),
  'cadetblue': Color(0xff5f9ea0),
  'chartreuse': Color(0xff7fff00),
  'chocolate': Color(0xffd2691e),
  'coral': Color(0xffff7f50),
  'cornflower': Color(0xff6495ed),
  'cornflowerblue': Color(0xff6495ed),
  'cornsilk': Color(0xfffff8dc),
  'crimson': Color(0xffdc143c),
  'cyan': Color(0xff00ffff),
  'darkblue': Color(0xff00008b),
  'darkcyan': Color(0xff008b8b),
  'darkgoldenrod': Color(0xffb8860b),
  'darkgray': Color(0xffa9a9a9),
  'darkgreen': Color(0xff006400),
  'darkgrey': Color(0xffa9a9a9),
  'darkkhaki': Color(0xffbdb76b),
  'darkmagenta': Color(0xff8b008b),
  'darkolivegreen': Color(0xff556b2f),
  'darkorange': Color(0xffff8c00),
  'darkorchid': Color(0xff9932cc),
  'darkred': Color(0xff8b0000),
  'darksalmon': Color(0xffe9967a),
  'darkseagreen': Color(0xff8fbc8f),
  'darkslateblue': Color(0xff483d8b),
  'darkslategray': Color(0xff2f4f4f),
  'darkslategrey': Color(0xff2f4f4f),
  'darkturquoise': Color(0xff00ced1),
  'darkviolet': Color(0xff9400d3),
  'deeppink': Color(0xffff1493),
  'deepskyblue': Color(0xff00bfff),
  'dimgray': Color(0xff696969),
  'dimgrey': Color(0xff696969),
  'dodgerblue': Color(0xff1e90ff),
  'firebrick': Color(0xffb22222),
  'floralwhite': Color(0xfffffaf0),
  'forestgreen': Color(0xff228b22),
  'fuchsia': Color(0xffff00ff),
  'gainsboro': Color(0xffdcdcdc),
  'ghostwhite': Color(0xfff8f8ff),
  'gold': Color(0xffffd700),
  'goldenrod': Color(0xffdaa520),
  'gray': Color(0xff808080),
  'green': Color(0xff008000),
  'greenyellow': Color(0xffadff2f),
  'grey': Color(0xff808080),
  'honeydew': Color(0xfff0fff0),
  'hotpink': Color(0xffff69b4),
  'indianred': Color(0xffcd5c5c),
  'indigo': Color(0xff4b0082),
  'ivory': Color(0xfffffff0),
  'khaki': Color(0xfff0e68c),
  'laserlemon': Color(0xffffff54),
  'lavender': Color(0xffe6e6fa),
  'lavenderblush': Color(0xfffff0f5),
  'lawngreen': Color(0xff7cfc00),
  'lemonchiffon': Color(0xfffffacd),
  'lightblue': Color(0xffadd8e6),
  'lightcoral': Color(0xfff08080),
  'lightcyan': Color(0xffe0ffff),
  'lightgoldenrod': Color(0xfffafad2),
  'lightgoldenrodyellow': Color(0xfffafad2),
  'lightgray': Color(0xffd3d3d3),
  'lightgreen': Color(0xff90ee90),
  'lightgrey': Color(0xffd3d3d3),
  'lightpink': Color(0xffffb6c1),
  'lightsalmon': Color(0xffffa07a),
  'lightseagreen': Color(0xff20b2aa),
  'lightskyblue': Color(0xff87cefa),
  'lightslategray': Color(0xff778899),
  'lightslategrey': Color(0xff778899),
  'lightsteelblue': Color(0xffb0c4de),
  'lightyellow': Color(0xffffffe0),
  'lime': Color(0xff00ff00),
  'limegreen': Color(0xff32cd32),
  'linen': Color(0xfffaf0e6),
  'magenta': Color(0xffff00ff),
  'maroon': Color(0xff800000),
  'maroon2': Color(0xff7f0000),
  'maroon3': Color(0xffb03060),
  'mediumaquamarine': Color(0xff66cdaa),
  'mediumblue': Color(0xff0000cd),
  'mediumorchid': Color(0xffba55d3),
  'mediumpurple': Color(0xff9370db),
  'mediumseagreen': Color(0xff3cb371),
  'mediumslateblue': Color(0xff7b68ee),
  'mediumspringgreen': Color(0xff00fa9a),
  'mediumturquoise': Color(0xff48d1cc),
  'mediumvioletred': Color(0xffc71585),
  'midnightblue': Color(0xff191970),
  'mintcream': Color(0xfff5fffa),
  'mistyrose': Color(0xffffe4e1),
  'moccasin': Color(0xffffe4b5),
  'navajowhite': Color(0xffffdead),
  'navy': Color(0xff000080),
  'oldlace': Color(0xfffdf5e6),
  'olive': Color(0xff808000),
  'olivedrab': Color(0xff6b8e23),
  'orange': Color(0xffffa500),
  'orangered': Color(0xffff4500),
  'orchid': Color(0xffda70d6),
  'palegoldenrod': Color(0xffeee8aa),
  'palegreen': Color(0xff98fb98),
  'paleturquoise': Color(0xffafeeee),
  'palevioletred': Color(0xffdb7093),
  'papayawhip': Color(0xffffefd5),
  'peachpuff': Color(0xffffdab9),
  'peru': Color(0xffcd853f),
  'pink': Color(0xffffc0cb),
  'plum': Color(0xffdda0dd),
  'powderblue': Color(0xffb0e0e6),
  'purple': Color(0xff800080),
  'purple2': Color(0xff7f007f),
  'purple3': Color(0xffa020f0),
  'rebeccapurple': Color(0xff663399),
  'red': Color(0xffff0000),
  'rosybrown': Color(0xffbc8f8f),
  'royalblue': Color(0xff4169e1),
  'saddlebrown': Color(0xff8b4513),
  'salmon': Color(0xfffa8072),
  'sandybrown': Color(0xfff4a460),
  'seagreen': Color(0xff2e8b57),
  'seashell': Color(0xfffff5ee),
  'sienna': Color(0xffa0522d),
  'silver': Color(0xffc0c0c0),
  'skyblue': Color(0xff87ceeb),
  'slateblue': Color(0xff6a5acd),
  'slategray': Color(0xff708090),
  'slategrey': Color(0xff708090),
  'snow': Color(0xfffffafa),
  'springgreen': Color(0xff00ff7f),
  'steelblue': Color(0xff4682b4),
  'tan': Color(0xffd2b48c),
  'teal': Color(0xff008080),
  'thistle': Color(0xffd8bfd8),
  'tomato': Color(0xffff6347),
  'turquoise': Color(0xff40e0d0),
  'violet': Color(0xffee82ee),
  'wheat': Color(0xfff5deb3),
  'white': Color(0xffffffff),
  'whitesmoke': Color(0xfff5f5f5),
  'yellow': Color(0xffffff00),
  'yellowgreen': Color(0xff9acd32),
};

Color? colorFromName(String val) => x11Colors[val.trim().replaceAll(' ', '').toLowerCase()];

extension ColorExtension on String {
  Color? toColor() => colorFromName(this);
}
