import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter, FilteringTextInputFormatter;
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_button.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';

/// Returns neumorphism box shadows
class NeumorphicActiveBlueButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double borderRadius;

  const NeumorphicActiveBlueButton({
    super.key,
    required this.text,
    required this.isActive,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTapUp: (_) {
          onTap?.call();
        },
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(borderRadius),
          clipBehavior: isActive ? Clip.hardEdge : Clip.none,
          child: Container(
            height: height ?? 50,
            width: width ?? double.infinity,
            clipBehavior: isActive ? Clip.hardEdge : Clip.none,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: getNeumorphismBoxShadows(inner: isActive),
            ),
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE2F2FB) : Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                border: isActive ? Border.all(color: const Color(0xFF4D9BC7), width: 1) : null,
              ),
              child: FusionAppText(
                text: text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns neumorphism box shadows
class NeumorphicAudioToggleButton extends StatefulWidget {
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
  State<NeumorphicAudioToggleButton> createState() => _NeumorphicAudioToggleButtonState();
}

class _NeumorphicAudioToggleButtonState extends State<NeumorphicAudioToggleButton> {
  bool get _effectiveIsActive => widget.isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTapUp: (_) {
          widget.onTap?.call();
        },
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(widget.borderRadius),
          clipBehavior: _effectiveIsActive ? Clip.hardEdge : Clip.none,
          child: Container(
            height: widget.height ?? 50,
            width: widget.width ?? double.infinity,
            clipBehavior: _effectiveIsActive ? Clip.hardEdge : Clip.none,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: getNeumorphismBoxShadows(inner: _effectiveIsActive),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/volume.svg',
                height: widget.iconSize,
                width: widget.iconSize,
                // ignore: deprecated_member_use
                color: widget.isActive ? Colors.black : const Color(0xFFE2E2E2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphic popup button with text field and dropdown options
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
        height: 32,
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
              child: Center(
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

// Neumorphic button with text field and popup menu slider
class NeumorphicWithPopupSliderButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double borderRadius;
  final double? controllerValue;
  final ValueChanged<double>? onValueChanged;

  const NeumorphicWithPopupSliderButton({
    super.key,
    required this.isActive,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius = 8,
    this.controllerValue,
    this.onValueChanged,
  });

  @override
  State<NeumorphicWithPopupSliderButton> createState() => _NeumorphicWithPopupSliderButtonState();
}

class _NeumorphicWithPopupSliderButtonState extends State<NeumorphicWithPopupSliderButton> {
  late final TextEditingController _textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final GlobalKey _menuKey = GlobalKey();
  bool _showTextField = false;

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(widget.borderRadius),
      clipBehavior: Clip.hardEdge,
      child: Container(
        height: widget.height ?? 32,
        width: widget.width ?? double.infinity,
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: getNeumorphismBoxShadows(inner: true, color: const Color(0xFFF9F7F6)),
        ),
        child: GestureDetector(
          key: _menuKey,
          onDoubleTapDown: (_) {
            if (!_showTextField) {
              setState(() => _showTextField = true);

              WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
            }
          },
          onTapUp: (_) async {
            final RenderBox button = _menuKey.currentContext!.findRenderObject() as RenderBox;
            final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
            final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

            await showMenu(
              context: context,
              color: const Color(0xFFF5F5F5),
              position: RelativeRect.fromLTRB(
                position.dx,
                position.dy + button.size.height,
                position.dx + button.size.width,
                0,
              ),
              items: <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  enabled: false,
                  padding: const EdgeInsets.all(8).copyWith(right: 0),
                  child: const SizedBox(
                    width: 80,
                    height: 300,
                    child: Center(
                      child: VerticalSlider(
                        value: 10,
                        min: 0,
                        max: 60,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },

          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: widget.height ?? 32,
            width: widget.width ?? double.infinity,
            child: Center(
              child: TextField(
                focusNode: focusNode,
                enabled: _showTextField,
                controller: _textController,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$'))],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "0.0",
                  hintStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onTapOutside: (PointerDownEvent event) {
                  setState(() => _showTextField = false);
                  if (widget.controllerValue != null) _textController.text = widget.controllerValue.toString();
                  focusNode.unfocus();
                },
                onSubmitted: (String value) {
                  setState(() => _showTextField = false);
                  final double? newValue = double.tryParse(value);
                  if (newValue != null) {
                    widget.onValueChanged?.call(newValue);
                    _textController.text = newValue.toString();
                  } else {
                    if (widget.controllerValue != null) _textController.text = widget.controllerValue.toString();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Slider and meter widget
class SliderAndMeterWidget extends StatelessWidget {
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final ValueChanged<num>? onSliderChanged;

  const SliderAndMeterWidget({
    super.key,
    this.onSliderChanged,
    this.sliderValue = 0.0,
    this.sliderMin = 0.0,
    this.sliderMax = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          VerticalSlider(
            onChanged: onSliderChanged,
            value: sliderValue,
            min: sliderMin,
            max: sliderMax,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: VerticalMeter(
              value: 0,
              min: -60,
              max: 12,
              intervalGap: 6,
              showIntervals: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical slider with intervals
class VerticalSlider extends StatefulWidget {
  const VerticalSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.showIntervals = true,
    this.activeColor = const Color(0xFF303030),
    this.inactiveColor = const Color(0xFFBABABA),
    this.thumbColor = Colors.black,
    this.thumbInnerColor = Colors.white,
    this.trackWidth = 4.0,
    this.thumbSize = 16.0,
    this.intervalSpacing = 50.0,
    this.intervalTickWidth = 10.0,
    this.intervalGap,
  });

  final num value;
  final num min;
  final num max;
  final ValueChanged<num>? onChanged;
  final bool showIntervals;

  // Styling
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final Color thumbInnerColor;
  final double trackWidth;
  final double thumbSize;
  final double intervalSpacing;
  final double intervalTickWidth;
  final num? intervalGap;

  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  late num _currentValue;
  num? _dragStartValue;
  double _dragStartDy = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(VerticalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value.clamp(widget.min, widget.max);
    }
  }

  double _toNormalized(num value) {
    final num range = widget.max - widget.min;
    if (range == 0) return 0.0;
    return ((value - widget.min) / range).clamp(0.0, 1.0).toDouble();
  }

  num _fromNormalized(double normalized) {
    return widget.min + normalized * (widget.max - widget.min);
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartValue = _currentValue;
    _dragStartDy = details.localPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details, double height) {
    if (_dragStartValue == null) return;

    final double trackRange = height - widget.thumbSize;
    final double delta = _dragStartDy - details.localPosition.dy;
    final double deltaNormalized = delta / trackRange;
    final double startNormalized = _toNormalized(_dragStartValue!);
    final double newNormalized = (startNormalized + deltaNormalized).clamp(0.0, 1.0);
    final num newValue = _fromNormalized(newNormalized);

    setState(() {
      _currentValue = num.parse(newValue.toStringAsFixed(2));
    });

    widget.onChanged?.call(_currentValue);
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartValue = null;
  }

  List<num> _generateIntervals(double height) {
    // If intervalGap is provided, use it to generate intervals
    if (widget.intervalGap != null) {
      final num range = widget.max - widget.min;
      final int tickCount = (range / widget.intervalGap!).floor() + 1;

      return List<num>.generate(
        tickCount,
        (int i) => widget.max - (i * widget.intervalGap!),
      ).where((num v) => v >= widget.min && v <= widget.max).toList();
    }

    // Otherwise, generate based on height
    final int tickCount = ((height / widget.intervalSpacing).floor()).clamp(3, 12);
    final double step = (widget.max - widget.min) / (tickCount - 1);

    return List<num>.generate(
      tickCount,
      (int i) => widget.max - (i * step),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight;
        final double normalizedValue = _toNormalized(_currentValue);

        // Thumb center travels from halfThumb to (height - halfThumb)
        // So it touches line ends perfectly
        final double halfThumb = widget.thumbSize / 2;
        final double trackHeight = height - widget.thumbSize;
        final double thumbCenter = halfThumb + (normalizedValue * trackHeight);
        final double thumbBottom = thumbCenter - halfThumb;

        // Track sections based on thumb center
        final double activeHeight = thumbCenter - (widget.thumbSize / 2);
        final double inactiveHeight = height - thumbCenter;

        final List<num> intervals = widget.showIntervals ? _generateIntervals(height) : <num>[];

        return Center(
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Intervals (if enabled)
                if (widget.showIntervals)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: widget.thumbSize / 4),
                    child: SizedBox(
                      height: height,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          ...intervals.map((num v) {
                            return Row(
                              spacing: 2,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  v.round().toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: widget.inactiveColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: widget.intervalTickWidth,
                                  decoration: BoxDecoration(
                                    color: widget.inactiveColor,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                // Slider area with track and thumb
                SizedBox(
                  width: widget.thumbSize,
                  height: height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // Track - centered
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: widget.trackWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // Inactive (top)
                                Container(
                                  width: widget.trackWidth,
                                  height: inactiveHeight,
                                  decoration: BoxDecoration(
                                    color: widget.inactiveColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(100),
                                    ),
                                  ),
                                ),
                                // Active (bottom)
                                Container(
                                  width: widget.trackWidth,
                                  height: activeHeight,
                                  decoration: BoxDecoration(
                                    color: widget.activeColor,
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Thumb - centered horizontally
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: thumbBottom,
                        child: Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _onPanStart,
                            onPanUpdate: (DragUpdateDetails details) => _onPanUpdate(details, height),
                            onPanEnd: _onPanEnd,
                            child: Container(
                              height: widget.thumbSize,
                              width: widget.thumbSize,
                              decoration: BoxDecoration(
                                color: widget.thumbColor,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  height: widget.thumbSize / 2,
                                  width: widget.thumbSize / 2,
                                  decoration: BoxDecoration(
                                    color: widget.thumbInnerColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Vertical meter with intervals
class VerticalMeter extends StatelessWidget {
  const VerticalMeter({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.showIntervals = true,
    this.meterWidth = 4.0,
    this.inactiveColor = const Color(0xFFBABABA),
    this.intervalSpacing = 50.0,
    this.intervalTickWidth = 10.0,
    this.intervalGap,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final num value;
  final num min;
  final num max;
  final bool showIntervals;

  // Styling
  final double meterWidth;
  final Color inactiveColor;
  final double intervalSpacing;
  final double intervalTickWidth;
  final num? intervalGap;
  final Duration animationDuration;

  static const double _borderRadius = 100;

  double _toNormalized(num value) {
    final num range = max - min;
    if (range == 0) return 0.0;
    return ((value - min) / range).clamp(0.0, 1.0).toDouble();
  }

  List<num> _generateIntervals(double height) {
    // If intervalGap is provided, use it to generate intervals
    if (intervalGap != null) {
      final num range = max - min;
      final int tickCount = (range / intervalGap!).floor() + 1;

      return List<num>.generate(
        tickCount,
        (int i) => max - (i * intervalGap!),
      ).where((num v) => v >= min && v <= max).toList();
    }

    // Otherwise, generate based on height
    final int tickCount = ((height / intervalSpacing).floor()).clamp(3, 12);
    final double step = (max - min) / (tickCount - 1);

    return List<num>.generate(
      tickCount,
      (int i) => max - (i * step),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight;
        final double normalized = _toNormalized(value);
        final double activeHeight = normalized * height;
        final List<num> intervals = showIntervals ? _generateIntervals(height) : <num>[];

        return Center(
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Meter area with gradient and overlay
                SizedBox(
                  width: meterWidth,
                  height: height,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_borderRadius),
                      bottom: Radius.circular(_borderRadius),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        // Gradient background (no internal borderRadius)
                        Container(
                          width: meterWidth,
                          height: height,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                              ],
                            ),
                          ),
                        ),

                        // Grey inactive overlay (clipped by parent)
                        Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedContainer(
                            duration: animationDuration,
                            curve: Curves.easeOut,
                            width: meterWidth,
                            height: height - activeHeight,
                            decoration: BoxDecoration(
                              color: inactiveColor,
                              // no need to set radius here — already clipped by parent
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Intervals (if enabled) - positioned to the right
                if (showIntervals)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SizedBox(
                      height: height,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ...intervals.map((num v) {
                            return Row(
                              spacing: 2,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  height: 2,
                                  width: intervalTickWidth,
                                  decoration: BoxDecoration(
                                    color: inactiveColor,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                Text(
                                  v.round().toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: inactiveColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Neumorphic text field with gain slider
class NeumorphicGainTextField extends StatefulWidget {
  final String? controllerValue;
  final ValueChanged<double>? onSubmitted;
  final double? height;
  final double? width;
  final double borderRadius;
  final double maxGain;
  final double minGain;

  const NeumorphicGainTextField({
    super.key,
    required this.maxGain,
    required this.minGain,
    this.onSubmitted,
    this.height,
    this.width,
    this.borderRadius = 10,
    this.controllerValue,
  });

  @override
  State<NeumorphicGainTextField> createState() => _NeumorphicGainTextFieldState();
}

class _NeumorphicGainTextFieldState extends State<NeumorphicGainTextField> {
  late final TextEditingController controller = TextEditingController();

  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    controller.text = widget.controllerValue ?? '';
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });

    controller.addListener(() {
      final String trimmedText = controller.text.trim();
      if (trimmedText.isEmpty || trimmedText.length == 1) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(NeumorphicGainTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllerValue != oldWidget.controllerValue) {
      controller.text = widget.controllerValue ?? '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get hasValue => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isFocused ? null : getNeumorphismBoxShadows(inner: true),
          border: isFocused ? Border.all(color: Colors.black12, width: 2) : null,
        ),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          focusNode: _focusNode,
          style: Theme.of(context).textTheme.labelLarge,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$'))],
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "0",
            suffixText: hasValue ? "db" : null,
            isDense: true,
            hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
            contentPadding: const EdgeInsets.all(0).copyWith(right: hasValue ? 6 : 0),
          ),
          onSubmitted: (String value) {
            final double? gain = double.tryParse(value);

            if (gain != null) {
              if (gain > widget.maxGain) {
                if (widget.controllerValue != null) controller.text = widget.controllerValue.toString();

                return FusionToast.error(context, message: "Gain cannot be greater than ${widget.maxGain}db");
              } else if (gain < widget.minGain) {
                if (widget.controllerValue != null) controller.text = widget.controllerValue.toString();
                return FusionToast.error(context, message: "Gain cannot be less than ${widget.minGain}db");
              } else {
                widget.onSubmitted?.call(gain);
              }
            }
          },
        ),
      ),
    );
  }
}

// Priority selection widget
class PrioritySelectionWidget extends StatefulWidget {
  final String zoneId;
  const PrioritySelectionWidget({super.key, required this.zoneId});

  @override
  State<PrioritySelectionWidget> createState() => _PrioritySelectionWidgetState();
}

class _PrioritySelectionWidgetState extends State<PrioritySelectionWidget> {
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();

  void onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    /// Handle the reordering logic - swap sources using reOrderPrioritySourcesInZone
    if (oldIndex != newIndex) {
      /// Get current source IDs directly from view model
      final List<String> prioritySources = _projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);
      final String? source1 = prioritySources.isNotEmpty ? prioritySources[0] : null;
      final String? source2 = prioritySources.length > 1 ? prioritySources[1] : null;

      /// Create new order list with swapped sources
      final List<String> newOrder = <String>[];
      if (oldIndex == 0 && newIndex == 1) {
        /// P1 moved to P2 position
        newOrder.add(source2 ?? '');
        newOrder.add(source1 ?? '');
      } else if (oldIndex == 1 && newIndex == 0) {
        /// P2 moved to P1 position
        newOrder.add(source2 ?? '');
        newOrder.add(source1 ?? '');
      }

      /// Use the new reOrderPrioritySourcesInZone method
      _projectViewModel.reOrderPrioritySourcesInZone(zoneId: widget.zoneId, newOrder: newOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ZoneFunctions? existingFunction = _projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 28,
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xFFF5F5F5),
            child: FusionAppText(
              text: "PRIORITY",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),

          _buildReorderablePriorityWidgets(),
        ],
      ),
    );
  }

  Widget _buildReorderablePriorityWidgets() {
    final ZoneFunctions? existingFunction = _projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: ReorderableListView.builder(
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return FadeTransition(
            opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
            child: Material(
              color: Colors.white,
              child: child,
            ),
          );
        },
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: 2,
        onReorder: onReorder,
        itemBuilder: (BuildContext context, int index) {
          final int priorityIndex = index + 1;

          String? selectedSourceId;
          String? selectedSourceName;
          final List<String> prioritySources = _projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);

          /// priority 1
          if (priorityIndex == 1) {
            if (prioritySources.isNotEmpty && prioritySources[0].isNotEmpty) {
              final HardwareComponent? sourceData = _projectViewModel.getHardware(hardwareId: prioritySources[0]);
              if (sourceData != null) {
                selectedSourceName = sourceData.name;
                selectedSourceId = prioritySources[0];
              }
            }
          } else {
            /// priority 2
            if (prioritySources.length > 1 && prioritySources[1].isNotEmpty) {
              final HardwareComponent? sourceData = _projectViewModel.getHardware(hardwareId: prioritySources[1]);
              if (sourceData != null) {
                selectedSourceName = sourceData.name;
                selectedSourceId = prioritySources[1];
              }
            }
          }

          // get zone by id
          final Color? zoneColor = _projectViewModel.getZone(zoneId: widget.zoneId)?.color;

          return ReorderableDragStartListener(
            key: ValueKey<String>('priority_widget_$index'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              // child: buildPriorityFunctionWidget(priorityIndex: priorityIndex),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: "Priority $priorityIndex",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 24,
                            width: double.infinity,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              spacing: 4,
                              children: <Widget>[
                                Container(
                                  height: 16,
                                  width: 16,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: zoneColor, // TODO: THIS IS ZONE COLOR
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FusionAppText(
                                    text: "P1",
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FusionAppText(
                                    text: selectedSourceName ?? "No source name",
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Icon(
                          Icons.circle,
                          color: Color(0xFFF4F4F4),
                          size: 16,
                        ),

                        NeumorphicActiveBlueButton(
                          text: "Active",
                          isActive: false,
                          width: 72,
                          height: 24,
                          onTap: () {
                            //
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Row(
                      spacing: 8,
                      children: <Widget>[
                        const Expanded(child: SizedBox()),

                        FusionAppText(
                          text: "Volume",
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: const Color(0xFF171717),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: NeumorphicWithPopupSliderButton(
                            isActive: false,
                            width: 72,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
