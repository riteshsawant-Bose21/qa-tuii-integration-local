import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_button.dart';
import 'package:fusion_lib/fusion_lib.dart';

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
  bool _isPressed = false;

  bool get _effectiveIsActive => widget.isActive || _isPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) {
          setState(() => _isPressed = false);
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

class SliderAndMeterWidget extends StatelessWidget {
  final ValueChanged<num>? onSliderChanged;

  const SliderAndMeterWidget({
    super.key,
    this.onSliderChanged,
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
            value: 0,
            min: 0,
            max: 100,
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
