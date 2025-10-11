import 'package:flutter/material.dart';

import '../fusion_acoustic_calculation_engine/spl_calculation_data.dart';
import 'spl_range_controller.dart';

class SPLRangeSlider extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final void Function(double min, double max) onChanged;
  final void Function(double min, double max) onChangeEnd;
  final double width;
  final double height;
  final SplRangeController? controller;
  final bool invertedColors;

  const SPLRangeSlider({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    required this.onChangeEnd,
    required this.invertedColors,
    this.width = 60,
    this.height = 400,
    this.controller,
  });

  @override
  State<SPLRangeSlider> createState() => _SPLRangeSliderState();
}

class _SPLRangeSliderState extends State<SPLRangeSlider> {
  static const double minSPL = 36.0;
  static const double maxSPL = 132.0;

  late double _currentMin;
  late double _currentMax;
  bool _isDraggingMin = false;
  bool _isDraggingMax = false;
  bool _isDraggingRange = false;
  bool _isUpdatingFromController = false;

  @override
  void initState() {
    super.initState();

    // Initialize from controller if available, otherwise use widget values
    if (widget.controller != null) {
      _currentMin = widget.controller!.lowerLimit.clamp(minSPL, maxSPL);
      _currentMax = widget.controller!.upperLimit.clamp(minSPL, maxSPL);
      widget.controller!.addListener(_onControllerChanged);
    } else {
      _currentMin = widget.minValue.clamp(minSPL, maxSPL);
      _currentMax = widget.maxValue.clamp(minSPL, maxSPL);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller != null && !_isUpdatingFromController) {
      setState(() {
        _currentMin = widget.controller!.lowerLimit.clamp(minSPL, maxSPL);
        _currentMax = widget.controller!.upperLimit.clamp(minSPL, maxSPL);
      });
    }
  }

  void _updateController(double min, double max) {
    if (widget.controller != null) {
      _isUpdatingFromController = true;
      widget.controller!.setRange(min, max);
      _isUpdatingFromController = false;
    }
  }

  @override
  void didUpdateWidget(covariant SPLRangeSlider old) {
    super.didUpdateWidget(old);

    // Only update from widget values if no controller is being used
    if (widget.controller == null && (old.minValue != widget.minValue || old.maxValue != widget.maxValue)) {
      _currentMin = widget.minValue.clamp(minSPL, maxSPL);
      _currentMax = widget.maxValue.clamp(minSPL, maxSPL);
    }

    // Handle controller changes
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        widget.controller!.addListener(_onControllerChanged);
        _currentMin = widget.controller!.lowerLimit.clamp(minSPL, maxSPL);
        _currentMax = widget.controller!.upperLimit.clamp(minSPL, maxSPL);
      }
    }
  }

  double _getPositionFromValue(double value) => (maxSPL - value) / (maxSPL - minSPL); // 0 at top, 1 at bottom

  double _getValueFromPosition(double position) => maxSPL - position * (maxSPL - minSPL);

  double _getValueFromGlobalPosition(double globalY) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(Offset(0, globalY));
    final double sliderH = widget.height;
    final double y = local.dy.clamp(0, sliderH);
    return _getValueFromPosition(y / sliderH);
  }

  List<Color> _buildGradientColors() {
    final gradientColors = <Color>[
      SPLCalculationData.legendColors.last,
      ...SPLCalculationData.legendColors.reversed,
      SPLCalculationData.legendColors.first,
    ];

    if (widget.invertedColors) {
      return gradientColors.reversed.toList();
    }
    return gradientColors;
  }

  List<double> _buildGradientStops() {
    final double minPos = _getPositionFromValue(_currentMin);
    final double maxPos = _getPositionFromValue(_currentMax);

    final List<double> stops = <double>[maxPos];
    for (int i = 0; i < SPLCalculationData.legendColors.length; i++) {
      final double t = i / (SPLCalculationData.legendColors.length - 1);
      stops.add(maxPos + (minPos - maxPos) * t);
    }
    stops.add(minPos);
    return stops;
  }

  Widget _buildStaticSPLLabels() {
    final List<int> splValues = <int>[for (int spl = 36; spl <= 132; spl += 12) spl];

    final double sliderHeight = widget.height;
    const double labelHeight = 16;

    return SizedBox(
      width: 30,
      height: sliderHeight,
      child: Stack(
        children: splValues.map((int spl) {
          final double normalized = ((maxSPL - spl) / (maxSPL - minSPL)).clamp(0.0, 1.0);
          final double topPosition = normalized * (sliderHeight - labelHeight);

          return Positioned(
            top: topPosition,
            left: 0,
            right: 0,
            child: SizedBox(
              height: labelHeight,
              child: Center(
                child: Text(
                  '$spl',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(0.5, 0.5),
                        blurRadius: 1.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTooltip(double value, bool isMax) {
    final double sliderH = widget.height;
    final double pos = _getPositionFromValue(value);
    final double top = pos * sliderH;

    return Positioned(
      left: -widget.width * 2.25,
      top: (top - 12).clamp(0, widget.height - 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          '${value.round()} dB',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static const double handleHeight = 12.0;
  Widget _buildHandle(double value, bool isMax) {
    final double sliderH = widget.height - handleHeight;
    final double pos = _getPositionFromValue(value);
    final double top = pos * sliderH;

    return Positioned(
      left: 0,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {
          setState(() {
            _isDraggingMax = isMax;
            _isDraggingMin = !isMax;
            _isDraggingRange = false;
          });
        },
        onPanUpdate: (DragUpdateDetails details) {
          final double newVal = _getValueFromGlobalPosition(details.globalPosition.dy);
          setState(() {
            if (isMax) {
              _currentMax = newVal.clamp(_currentMin + 1, maxSPL);
            } else {
              _currentMin = newVal.clamp(minSPL, _currentMax - 1);
            }
          });

          // Update controller and notify parent
          _updateController(_currentMin, _currentMax);
          widget.onChanged(_currentMin, _currentMax);
        },
        onPanEnd: (_) {
          setState(() {
            _isDraggingMax = false;
            _isDraggingMin = false;
          });
          widget.onChangeEnd(_currentMin, _currentMax);
        },
        child: Container(
          width: widget.width,
          height: handleHeight,
          decoration: BoxDecoration(
            color: (isMax ? _isDraggingMax : _isDraggingMin) ? Colors.white : Colors.white70,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {
        if (!_isDraggingMin && !_isDraggingMax) {
          setState(() => _isDraggingRange = true);
        }
      },
      onPanUpdate: (DragUpdateDetails details) {
        if (_isDraggingRange && !_isDraggingMin && !_isDraggingMax) {
          final double deltaPixels = -details.delta.dy;
          final double deltaValue = deltaPixels * (maxSPL - minSPL) / widget.height;
          final double range = _currentMax - _currentMin;

          double newMin = _currentMin + deltaValue;
          double newMax = _currentMax + deltaValue;

          if (newMin < minSPL) {
            newMin = minSPL;
            newMax = newMin + range;
          }
          if (newMax > maxSPL) {
            newMax = maxSPL;
            newMin = newMax - range;
          }

          setState(() {
            _currentMin = newMin;
            _currentMax = newMax;
          });

          // Update controller and notify parent
          _updateController(_currentMin, _currentMax);
          widget.onChanged(_currentMin, _currentMax);
        }
      },
      onPanEnd: (_) {
        setState(() {
          _isDraggingRange = false;
        });
        widget.onChangeEnd(_currentMin, _currentMax);
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _buildGradientColors(),
                    stops: _buildGradientStops(),
                  ),
                ),
              ),
            ),

            Positioned(
              child: _buildStaticSPLLabels(),
            ),

            _buildHandle(_currentMax, true),
            _buildHandle(_currentMin, false),

            if (_isDraggingMax || _isDraggingRange) _buildTooltip(_currentMax, true),
            if (_isDraggingMin || _isDraggingRange) _buildTooltip(_currentMin, false),
          ],
        ),
      ),
    );
  }
}
