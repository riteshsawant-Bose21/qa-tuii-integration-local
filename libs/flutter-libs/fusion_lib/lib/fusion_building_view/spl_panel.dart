import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_widgets/others/hover_dropdown.dart';

import 'spl_range_controller.dart';

/// Enums for SPL (Sound Pressure Level) mapping attributes panel
/// These enums define the available options for various SPL configuration parameters

/// Weighting options for SPL measurements
enum SplWeighting {
  aWeighted('A-Weighted'),
  zWeighted('Z-Weighted'),
  cWeighted('C-Weighted');

  const SplWeighting(this.displayName);
  final String displayName;

  static SplWeighting fromString(String value) {
    return values.firstWhere(
      (SplWeighting e) => e.displayName == value,
      orElse: () => SplWeighting.aWeighted,
    );
  }
}

/// Center frequency options for SPL measurements (in Hz)
/// Center frequency options for SPL measurements (ISO within 31.5–16k Hz)
enum SplFrequency {
  hz31_5('31.5 Hz'),
  hz40('40 Hz'),
  hz50('50 Hz'),
  hz63('63 Hz'),
  hz80('80 Hz'),
  hz100('100 Hz'),
  hz125('125 Hz'),
  hz160('160 Hz'),
  hz200('200 Hz'),
  hz250('250 Hz'),
  hz315('315 Hz'),
  hz400('400 Hz'),
  hz500('500 Hz'),
  hz630('630 Hz'),
  hz800('800 Hz'),
  hz1000('1 kHz'),
  hz1250('1.25 kHz'),
  hz1600('1.6 kHz'),
  hz2000('2 kHz'),
  hz2500('2.5 kHz'),
  hz3150('3.15 kHz'),
  hz4000('4 kHz'),
  hz5000('5 kHz'),
  hz6300('6.3 kHz'),
  hz8000('8 kHz'),
  hz10000('10 kHz'),
  hz12500('12.5 kHz'),
  hz16000('16 kHz');

  const SplFrequency(this.displayName);
  final String displayName;

  static SplFrequency fromString(String value) {
    return values.firstWhere(
      (SplFrequency e) => e.displayName == value,
      orElse: () => SplFrequency.hz2000,
    );
  }

  /// Get frequency value as integer Hz (round if decimal)
  int get frequencyValue {
    if (displayName.contains('kHz')) {
      final numericPart = displayName.replaceAll(' kHz', '').replaceAll(' ', '');
      return (double.parse(numericPart) * 1000).round();
    } else if (displayName.contains('Hz')) {
      final numericPart = displayName.replaceAll(' Hz', '').replaceAll(' ', '');
      return double.parse(numericPart).round(); // handles 31.5 Hz etc.
    }
    return double.parse(displayName).round();
  }
}

/// Bandwidth options for SPL measurements
enum SplBandwidth {
  oneOctave('1 Octave'),
  oneThirdOctave('1/3 Octave'),
  allBands('All Bands'),
  vocal('Vocal Bands');

  const SplBandwidth(this.displayName);
  final String displayName;

  static SplBandwidth fromString(String value) {
    return values.firstWhere(
      (SplBandwidth e) => e.displayName == value,
      orElse: () => SplBandwidth.vocal,
    );
  }
}

/// Mapping resolution options for SPL measurements
enum SplResolution {
  low('Low'),
  medium('Medium'),
  high('High');

  const SplResolution(this.displayName);
  final String displayName;

  static SplResolution fromString(String value) {
    return values.firstWhere(
      (SplResolution e) => e.displayName == value,
      orElse: () => SplResolution.medium,
    );
  }
}

/// Extension methods to get lists of display names for dropdowns
/// Note: This extension is now deprecated since we use enums directly
extension SplEnumExtensions on Object {
  static List<String> get weightingOptions => SplWeighting.values.map((SplWeighting e) => e.displayName).toList();

  static List<String> get frequencyOptions => SplFrequency.values.map((SplFrequency e) => e.displayName).toList();

  static List<String> get bandwidthOptions => SplBandwidth.values.map((SplBandwidth e) => e.displayName).toList();

  static List<String> get resolutionOptions => SplResolution.values.map((SplResolution e) => e.displayName).toList();
}

/// Panel widget for configuring SPL mapping attributes
class SplPanel extends StatefulWidget {
  final ValueChanged<SplPanelData>? onChanged;
  final SplRangeController? controller;
  final SplPanelData initialData;

  const SplPanel({
    super.key,
    this.onChanged,
    this.controller,
    required this.initialData,
  });

  @override
  State<SplPanel> createState() => _SplPanelState();
}

class _SplPanelState extends State<SplPanel> {
  // Top selections - using enums directly instead of strings
  SplWeighting _weighting = SplWeighting.aWeighted;
  SplFrequency _frequency = SplFrequency.hz2000;
  SplBandwidth _bandwidth = SplBandwidth.oneThirdOctave;
  SplResolution _resolution = SplResolution.low;

  // SPL Range
  bool _splAutoScale = false;
  bool _splInvert = false;
  bool _relativeDb = false;
  final TextEditingController _splUpper = TextEditingController();
  final TextEditingController _splLower = TextEditingController();
  final FocusNode _splUpperFocusNode = FocusNode();
  final FocusNode _splLowerFocusNode = FocusNode();
  bool _isUpdatingFromController = false;

  static final List<TextInputFormatter> _numFmt = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[-]?\d*\.?\d*')),
  ];

  bool get _needsFrequency => _bandwidth == SplBandwidth.oneThirdOctave || _bandwidth == SplBandwidth.oneOctave;

  /// Allowed ISO centers by bandwidth
  List<SplFrequency> _allowedFrequenciesFor(SplBandwidth bw) {
    if (bw == SplBandwidth.oneOctave) {
      // Octave centers within 31.5–16k
      return <SplFrequency>[
        SplFrequency.hz31_5,
        SplFrequency.hz63,
        SplFrequency.hz125,
        SplFrequency.hz250,
        SplFrequency.hz500,
        SplFrequency.hz1000,
        SplFrequency.hz2000,
        SplFrequency.hz4000,
        SplFrequency.hz8000,
        SplFrequency.hz16000,
      ];
    }
    if (bw == SplBandwidth.oneThirdOctave) {
      // Full 1/3-oct ISO list already declared in enum
      return <SplFrequency>[
        SplFrequency.hz31_5,
        SplFrequency.hz40,
        SplFrequency.hz50,
        SplFrequency.hz63,
        SplFrequency.hz80,
        SplFrequency.hz100,
        SplFrequency.hz125,
        SplFrequency.hz160,
        SplFrequency.hz200,
        SplFrequency.hz250,
        SplFrequency.hz315,
        SplFrequency.hz400,
        SplFrequency.hz500,
        SplFrequency.hz630,
        SplFrequency.hz800,
        SplFrequency.hz1000,
        SplFrequency.hz1250,
        SplFrequency.hz1600,
        SplFrequency.hz2000,
        SplFrequency.hz2500,
        SplFrequency.hz3150,
        SplFrequency.hz4000,
        SplFrequency.hz5000,
        SplFrequency.hz6300,
        SplFrequency.hz8000,
        SplFrequency.hz10000,
        SplFrequency.hz12500,
        SplFrequency.hz16000,
      ];
    }
    // Vocal/All Bands/Broadband don't use frequency
    return const <SplFrequency>[];
  }

  /// Ensure _frequency is valid for the new bandwidth
  void _coerceFrequencyForBandwidth(SplBandwidth bw) {
    if (!_needsFrequency) return;
    final allowed = _allowedFrequenciesFor(bw);
    if (!allowed.contains(_frequency)) {
      // Snap to closest by absolute Hz distance
      final int currentHz = _frequency.frequencyValue;
      SplFrequency best = allowed.first;
      int bestErr = (best.frequencyValue - currentHz).abs();
      for (final f in allowed.skip(1)) {
        final int err = (f.frequencyValue - currentHz).abs();
        if (err < bestErr) {
          best = f;
          bestErr = err;
        }
      }
      _frequency = best;
    }
  }

  @override
  void initState() {
    super.initState();
    final SplPanelData i = widget.initialData;
    _weighting = i.weighting;
    _frequency = i.frequency;
    _bandwidth = i.bandwidth;
    _resolution = i.resolution;

    _splAutoScale = i.splAutoScale;
    _splInvert = i.splInvertColor;
    _relativeDb = i.relative;

    // Initialize text fields with controller values if available, otherwise use initial data
    if (widget.controller != null) {
      _updateTextFieldsFromController();
      widget.controller!.addListener(_onControllerChanged);
    } else {
      _splUpper.text = _numOrEmpty(i.splUpperDb);
      _splLower.text = _numOrEmpty(i.splLowerDb);
    }

    // _splUpper.addListener(_onTextFieldChanged);
    // _splLower.addListener(_onTextFieldChanged);
    _splUpperFocusNode.addListener(_onFocusChanged);
    _splLowerFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    // _splUpper.removeListener(_onTextFieldChanged);
    // _splLower.removeListener(_onTextFieldChanged);
    _splUpperFocusNode.removeListener(_onFocusChanged);
    _splLowerFocusNode.removeListener(_onFocusChanged);
    _splUpper.dispose();
    _splLower.dispose();
    _splUpperFocusNode.dispose();
    _splLowerFocusNode.dispose();
    super.dispose();
  }

  void _updateTextFieldsFromController() {
    if (widget.controller != null && !_isUpdatingFromController) {
      final String upperText = widget.controller!.upperLimit.round().toString();
      final String lowerText = widget.controller!.lowerLimit.round().toString();
      if (_splUpper.text != upperText) _splUpper.text = upperText;
      if (_splLower.text != lowerText) _splLower.text = lowerText;
    }
  }

  void _submitSpl({required bool isUpper}) {
    const double minDb = 36.0, maxDb = 132.0;

    // Current values from controller (fallbacks keep things sane)
    double upper = widget.controller?.upperLimit ?? maxDb;
    double lower = widget.controller?.lowerLimit ?? minDb;

    // Parse user input
    final double? typedUpper = double.tryParse(_splUpper.text);
    final double? typedLower = double.tryParse(_splLower.text);

    if (isUpper) {
      // If invalid, snap back to current
      if (typedUpper == null) {
        _splUpper.text = upper.round().toString();
        return;
      }
      upper = typedUpper.clamp(minDb, maxDb);
      // Enforce strict relation
      if (upper <= lower) upper = (lower + 1).clamp(minDb, maxDb);
    } else {
      if (typedLower == null) {
        _splLower.text = lower.round().toString();
        return;
      }
      lower = typedLower.clamp(minDb, maxDb);
      if (lower >= upper) lower = (upper - 1).clamp(minDb, maxDb);
    }

    // Final safety: if still crossed due to clamping edges, adjust the opposite by 1 dB
    if (upper <= lower) {
      if (isUpper) {
        lower = (upper - 1).clamp(minDb, maxDb);
      } else {
        upper = (lower + 1).clamp(minDb, maxDb);
      }
    }

    // Push to range controller
    if (widget.controller != null) {
      _isUpdatingFromController = true;
      widget.controller!.setRange(lower, upper);
      _isUpdatingFromController = false;
    }

    // Reflect normalized values
    _splUpper.text = upper.round().toString();
    _splLower.text = lower.round().toString();
    _emit();
    setState(() {});
  }

  void _onControllerChanged() {
    // Update text fields when controller values change (from slider)
    if (!_isUpdatingFromController) {
      _updateTextFieldsFromController();
    }
  }

  void _onFocusChanged() {
    if (!_splUpperFocusNode.hasFocus) {
      _validateAndClampTextFields(isUpper: true);
      _updateTextFieldsFromController(); // resync after losing focus
    }
    if (!_splLowerFocusNode.hasFocus) {
      _validateAndClampTextFields(isUpper: false);
      _updateTextFieldsFromController(); // resync after losing focus
    }
  }

  void _validateAndClampTextFields({bool? isUpper}) {
    final double? upperInput = double.tryParse(_splUpper.text);
    final double? lowerInput = double.tryParse(_splLower.text);

    // Get current controller values or use defaults
    double currentUpper = widget.controller?.upperLimit ?? 132.0;
    double currentLower = widget.controller?.lowerLimit ?? 36.0;

    bool needsUpdate = false;
    double newUpper = currentUpper;
    double newLower = currentLower;

    if (isUpper == true && upperInput != null) {
      // Clamp to min/max range
      final double clampedUpper = upperInput.clamp(36.0, 132.0);

      // Check if it violates the lower limit constraint
      if (clampedUpper >= currentLower) {
        newUpper = clampedUpper;
        needsUpdate = true;
      } else {
        // Invalid: upper would be less than lower, revert to previous valid value
        _splUpper.text = currentUpper.round().toString();
        return; // Don't update controller with invalid value
      }
    } else if (isUpper == false && lowerInput != null) {
      // Clamp to min/max range
      final double clampedLower = lowerInput.clamp(36.0, 132.0);

      // Check if it violates the upper limit constraint
      if (clampedLower <= currentUpper) {
        newLower = clampedLower;
        needsUpdate = true;
      } else {
        // Invalid: lower would be greater than upper, revert to previous valid value
        _splLower.text = currentLower.round().toString();
        return; // Don't update controller with invalid value
      }
    }

    // Only update controller if we have valid changes
    if (needsUpdate && widget.controller != null) {
      _isUpdatingFromController = true;
      widget.controller!.setRange(newLower, newUpper);
      _isUpdatingFromController = false;
    }
  }

  @override
  void didUpdateWidget(covariant SplPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        widget.controller!.addListener(_onControllerChanged);
        _updateTextFieldsFromController();
      }
    }
  }

  void _emit() {
    widget.onChanged?.call(
      SplPanelData(
        weighting: _weighting,
        frequency: _frequency,
        bandwidth: _bandwidth,
        resolution: _resolution,
        splAutoScale: _splAutoScale,
        splInvertColor: _splInvert,
        splUpperDb: double.parse(_splUpper.text).clamp(36.0, 132.0),
        splLowerDb: double.parse(_splLower.text).clamp(36.0, 132.0),
        relative: _relativeDb,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData base = Theme.of(context);
    final TextStyle? labelStyle = base.textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade600,
      fontSize: 12,
    );
    final ThemeData theme = base.copyWith(
      visualDensity: VisualDensity.compact,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 12),
      ),
      dividerColor: Colors.grey.shade300,
    );

    return Theme(
      data: theme,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Two-column layout: labels auto-size, controls flex to fill remaining width
          const IntrinsicColumnWidth col0 = IntrinsicColumnWidth();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Top selectors (Weighting/Frequency/Bandwidth/Resolution)
                Table(
                  columnWidths: const <int, TableColumnWidth>{0: col0, 1: FlexColumnWidth()},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: <TableRow>[
                    _row(
                      label: 'Weighting',
                      labelStyle: labelStyle,
                      control: _enumDropdown<SplWeighting>(
                        value: _weighting,
                        items: SplWeighting.values,
                        onChanged: (SplWeighting? v) {
                          setState(() => _weighting = v!);
                          _emit();
                        },
                      ),
                    ),
                    _row(
                      label: 'Bandwidth',
                      labelStyle: labelStyle,
                      control: _enumDropdown<SplBandwidth>(
                        value: _bandwidth,
                        items: SplBandwidth.values,
                        onChanged: (SplBandwidth? v) {
                          setState(() {
                            _bandwidth = v!;
                            if (_needsFrequency) {
                              _coerceFrequencyForBandwidth(_bandwidth);
                            }
                          });
                          _emit();
                        },
                      ),
                    ),
                    if (_needsFrequency)
                      _row(
                        label: 'Frequency',
                        labelStyle: labelStyle,
                        control: SizedBox(
                          height: 40,
                          child: HoverDropdownButtonFormField<SplFrequency>(
                            itemHeight: 48, // or null to use default
                            isDense: true,
                            isExpanded: true,
                            value: _allowedFrequenciesFor(_bandwidth).contains(_frequency)
                                ? _frequency
                                : (_allowedFrequenciesFor(_bandwidth).isNotEmpty ? _allowedFrequenciesFor(_bandwidth).first : null),
                            items: _allowedFrequenciesFor(_bandwidth)
                                .map(
                                  (SplFrequency e) => DropdownMenuItem<SplFrequency>(
                                    value: e,
                                    child: Text(e.displayName, style: const TextStyle(fontSize: 12)),
                                  ),
                                )
                                .toList(),
                            onChanged: (SplFrequency? v) {
                              if (v == null) return;
                              setState(() => _frequency = v);
                              _emit();
                            },
                            onHover: (value, index) {
                              if (value == null) return;
                              setState(() => _frequency = value);
                              _emit();
                            },
                            onSaved: (newValue) {
                              if (newValue == null) return;
                              setState(() => _frequency = newValue);
                              _emit();
                            },
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 16),
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ),
                      ),
                    _row(
                      label: 'Resolution',
                      labelStyle: labelStyle,
                      control: _enumDropdown<SplResolution>(
                        value: _resolution,
                        items: SplResolution.values,
                        onChanged: (SplResolution? v) {
                          setState(() => _resolution = v!);
                          _emit();
                        },
                      ),
                    ),
                  ],
                ),

                // _toggleRow(
                //   label: 'Relative (±6 dB)',
                //   value: _relativeDb,
                //   onChanged: (bool v) {
                //     setState(() => _relativeDb = v);
                //     _emit();
                //   },
                // ),
                const SizedBox(height: 6),

                Table(
                  columnWidths: const <int, TableColumnWidth>{0: col0, 1: FlexColumnWidth()},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: <TableRow>[
                    _row(
                      label: 'Upper Limit (dB)',
                      labelStyle: labelStyle,
                      control: _tf(
                        controller: _splUpper,
                        focusNode: _splUpperFocusNode,
                        hint: 'Value',
                        enabled: !_splAutoScale,
                        onSubmitted: (value) {
                          _submitSpl(isUpper: true);
                        },
                      ),
                    ),
                    _row(
                      label: 'Lower Limit (dB)',
                      labelStyle: labelStyle,
                      control: _tf(
                        controller: _splLower,
                        focusNode: _splLowerFocusNode,
                        hint: 'Value',
                        enabled: !_splAutoScale,
                        onSubmitted: (value) {
                          _submitSpl(isUpper: false);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // _toggleRow(
                //   label: 'Scale Automatically',
                //   value: _splAutoScale,
                //   onChanged: (bool v) {
                //     setState(() => _splAutoScale = v);
                //     _emit();
                //   },
                // ),
                _toggleRow(
                  label: 'Invert Color Scale',
                  value: _splInvert,
                  onChanged: (bool v) {
                    setState(() => _splInvert = v);
                    _emit();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper methods for creating UI components
  TableRow _row({
    required String label,
    TextStyle? labelStyle,
    required Widget control,
  }) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
          child: Text(label, style: labelStyle),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: control,
        ),
      ],
    );
  }

  // New generic enum dropdown method
  Widget _enumDropdown<T extends Enum>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      height: 32,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        style: const TextStyle(fontSize: 12, color: Colors.black),
        items: items
            .map(
              (T e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  (e as dynamic).displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
        icon: const Icon(Icons.arrow_drop_down, size: 16),
      ),
    );
  }

  Widget _tf({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool enabled,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 12),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: _numFmt,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: <Widget>[
        Transform.scale(
          scale: 0.7,
          alignment: Alignment.centerLeft,
          child: Switch.adaptive(value: value, onChanged: onChanged),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _numOrEmpty(double? v) => v == null ? '' : v.toString();
}

/// Immutable values emitted by the panel.
class SplPanelData {
  final SplWeighting weighting;
  final SplFrequency frequency;
  final SplBandwidth bandwidth;
  final SplResolution resolution;

  final bool splAutoScale;
  final bool splInvertColor;
  final double splUpperDb;
  final double splLowerDb;
  final bool relative;

  const SplPanelData({
    this.weighting = SplWeighting.zWeighted,
    this.frequency = SplFrequency.hz2000,
    this.bandwidth = SplBandwidth.allBands,
    this.resolution = SplResolution.medium,
    this.splAutoScale = false,
    this.splInvertColor = false,
    this.splUpperDb = 63,
    this.splLowerDb = 36,
    this.relative = false,
  });

  SplPanelData copyWith({
    SplWeighting? weighting,
    SplFrequency? frequency,
    SplBandwidth? bandwidth,
    SplResolution? resolution,
    bool? splAutoScale,
    bool? splInvertColor,
    double? splUpperDb,
    double? splLowerDb,
    bool? relativeDb,
  }) {
    return SplPanelData(
      weighting: weighting ?? this.weighting,
      frequency: frequency ?? this.frequency,
      bandwidth: bandwidth ?? this.bandwidth,
      resolution: resolution ?? this.resolution,
      splAutoScale: splAutoScale ?? this.splAutoScale,
      splInvertColor: splInvertColor ?? this.splInvertColor,
      splUpperDb: splUpperDb ?? this.splUpperDb,
      splLowerDb: splLowerDb ?? this.splLowerDb,
      relative: relativeDb ?? relative,
    );
  }

  double getResolutionSpacing() {
    switch (resolution) {
      case SplResolution.low:
        return 40;
      case SplResolution.medium:
        return 20;
      case SplResolution.high:
        return 10;
    }
  }

  @override
  String toString() =>
      'SplPanelData(weighting:${weighting.displayName}, frequency:${frequency.displayName}, bandwidth:${bandwidth.displayName}, resolution:${resolution.displayName}, '
      'splAuto:$splAutoScale, splInv:$splInvertColor, '
      'splU:$splUpperDb, splL:$splLowerDb, relativeDb:$relative)';
}

/// Collapsible section widget for organizing content
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: const ExpansionTileThemeData(
          tilePadding: EdgeInsets.zero,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        iconColor: Colors.grey.shade600,
        collapsedIconColor: Colors.grey.shade600,
        children: <Widget>[child],
      ),
    );
  }
}
