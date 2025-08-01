import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/constants/spl_calculation_data.dart';

class SPLRangeSlider extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final void Function(double min, double max) onChanged;
  final void Function(double min, double max) onChangeEnd;
  final double width;
  final double height;

  const SPLRangeSlider({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    required this.onChangeEnd,
    this.width = 60,
    this.height = 400,
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

  @override
  void initState() {
    super.initState();
    _currentMin = widget.minValue.clamp(minSPL, maxSPL);
    _currentMax = widget.maxValue.clamp(minSPL, maxSPL);
  }

  @override
  void didUpdateWidget(covariant SPLRangeSlider old) {
    super.didUpdateWidget(old);
    if (old.minValue != widget.minValue || old.maxValue != widget.maxValue) {
      _currentMin = widget.minValue.clamp(minSPL, maxSPL);
      _currentMax = widget.maxValue.clamp(minSPL, maxSPL);
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
    return <Color>[
      SPLCalculationData.legendColors.last,
      ...SPLCalculationData.legendColors.reversed,
      SPLCalculationData.legendColors.first,
    ];
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
        children:
            splValues.map((int spl) {
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
