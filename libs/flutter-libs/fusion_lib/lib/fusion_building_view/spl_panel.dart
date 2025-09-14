import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'spl_range_controller.dart';

/// Enums for SPL (Sound Pressure Level) mapping attributes panel
/// These enums define the available options for various SPL configuration parameters

/// Weighting options for SPL measurements
enum SplWeighting {
  aWeighted('A-Weighted'),
  cWeighted('C-Weighted'),
  zWeighted('Z-Weighted');

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
enum SplFrequency {
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
  hz10000('10 kHz');

  const SplFrequency(this.displayName);
  final String displayName;

  static SplFrequency fromString(String value) {
    return values.firstWhere(
      (SplFrequency e) => e.displayName == value,
      orElse: () => SplFrequency.hz2000,
    );
  }

  /// Get frequency value as integer (in Hz)
  int get frequencyValue {
    if (displayName.contains('kHz')) {
      final numericPart = displayName.replaceAll(' kHz', '');
      return (double.parse(numericPart) * 1000).round();
    } else if (displayName.contains('Hz')) {
      final numericPart = displayName.replaceAll(' Hz', '');
      return int.parse(numericPart);
    }
    return int.parse(displayName);
  }
}

/// Bandwidth options for SPL measurements
enum SplBandwidth {
  oneThirdOctave('1/3 Octave'),
  oneOctave('1 Octave'),
  threeOctaves('3 Octaves'),
  broadband('Broadband');

  const SplBandwidth(this.displayName);
  final String displayName;

  static SplBandwidth fromString(String value) {
    return values.firstWhere(
      (SplBandwidth e) => e.displayName == value,
      orElse: () => SplBandwidth.threeOctaves,
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
extension SplEnumExtensions on Object {
  static List<String> get weightingOptions => SplWeighting.values.map((SplWeighting e) => e.displayName).toList();

  static List<String> get frequencyOptions => SplFrequency.values.map((SplFrequency e) => e.displayName).toList();

  static List<String> get bandwidthOptions => SplBandwidth.values.map((SplBandwidth e) => e.displayName).toList();

  static List<String> get resolutionOptions => SplResolution.values.map((SplResolution e) => e.displayName).toList();
}

/// Panel widget for configuring SPL mapping attributes
class SplPanel extends StatefulWidget {
  const SplPanel({
    super.key,
    this.initial = const SplPanelData(),
    this.onChanged,
    this.controller,
  });

  final SplPanelData initial;
  final ValueChanged<SplPanelData>? onChanged;
  final SplRangeController? controller;

  @override
  State<SplPanel> createState() => _SplPanelState();
}

class _SplPanelState extends State<SplPanel> {
  // Top selections
  String _weighting = 'A-Weighted';
  String _frequency = '2 kHz';
  String _bandwidth = '3 Octaves';
  String _resolution = 'Medium';

  // SPL Range
  bool _splExpanded = true;
  bool _splAutoScale = false;
  bool _splInvert = false;
  final TextEditingController _splUpper = TextEditingController();
  final TextEditingController _splLower = TextEditingController();
  bool _isUpdatingFromController = false;

  static final List<TextInputFormatter> _numFmt = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[-]?\d*\.?\d*')),
  ];

  @override
  void initState() {
    super.initState();
    final SplPanelData i = widget.initial;
    _weighting = i.weighting;
    _frequency = i.frequency;
    _bandwidth = i.bandwidth;
    _resolution = i.resolution;

    _splAutoScale = i.splAutoScale;
    _splInvert = i.splInvertColor;

    // Initialize text fields with controller values if available, otherwise use initial data
    if (widget.controller != null) {
      _updateTextFieldsFromController();
      widget.controller!.addListener(_onControllerChanged);
    } else {
      _splUpper.text = _numOrEmpty(i.splUpperDb);
      _splLower.text = _numOrEmpty(i.splLowerDb);
    }

    _splUpper.addListener(_onTextFieldChanged);
    _splLower.addListener(_onTextFieldChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _splUpper.removeListener(_onTextFieldChanged);
    _splLower.removeListener(_onTextFieldChanged);
    _splUpper.dispose();
    _splLower.dispose();
    super.dispose();
  }

  void _updateTextFieldsFromController() {
    if (widget.controller != null && !_isUpdatingFromController) {
      final String upperText = widget.controller!.upperLimit.round().toString();
      final String lowerText = widget.controller!.lowerLimit.round().toString();

      // Only update if the text has actually changed to avoid cursor issues
      if (_splUpper.text != upperText) {
        _splUpper.text = upperText;
      }
      if (_splLower.text != lowerText) {
        _splLower.text = lowerText;
      }
    }
  }

  void _onControllerChanged() {
    // Update text fields when controller values change (from slider)
    if (!_isUpdatingFromController) {
      _updateTextFieldsFromController();
    }
  }

  void _onTextFieldChanged() {
    // Update controller when text fields change (from user typing)
    if (widget.controller != null && !_isUpdatingFromController) {
      final double? upper = double.tryParse(_splUpper.text);
      final double? lower = double.tryParse(_splLower.text);

      if (upper != null && lower != null) {
        // Validate SPL ranges (36-132 dB)
        final double validatedUpper = upper.clamp(36.0, 132.0);
        final double validatedLower = lower.clamp(36.0, 132.0);

        // Ensure upper >= lower
        final double finalLower = validatedLower;
        final double finalUpper = validatedUpper < finalLower ? finalLower : validatedUpper;

        // Only update text fields if values were actually clamped and different
        // This prevents interrupting user typing
        if (upper != finalUpper && !_splUpper.selection.isValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _splUpper.text = finalUpper.round().toString();
            }
          });
        }
        if (lower != finalLower && !_splLower.selection.isValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _splLower.text = finalLower.round().toString();
            }
          });
        }

        _isUpdatingFromController = true;
        widget.controller!.setRange(finalLower, finalUpper);
        _isUpdatingFromController = false;
      }
    }

    _emit();
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
        splUpperDb: double.tryParse(_splUpper.text),
        splLowerDb: double.tryParse(_splLower.text),
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
                      control: _dd(
                        value: _weighting,
                        items: SplEnumExtensions.weightingOptions,
                        onChanged: (String? v) {
                          setState(() => _weighting = v!);
                          _emit();
                        },
                      ),
                    ),
                    _row(
                      label: 'Frequency',
                      labelStyle: labelStyle,
                      control: _dd(
                        value: _frequency,
                        items: SplEnumExtensions.frequencyOptions,
                        onChanged: (String? v) {
                          setState(() => _frequency = v!);
                          _emit();
                        },
                      ),
                    ),
                    _row(
                      label: 'Bandwidth',
                      labelStyle: labelStyle,
                      control: _dd(
                        value: _bandwidth,
                        items: SplEnumExtensions.bandwidthOptions,
                        onChanged: (String? v) {
                          setState(() => _bandwidth = v!);
                          _emit();
                        },
                      ),
                    ),
                    _row(
                      label: 'Resolution',
                      labelStyle: labelStyle,
                      control: _dd(
                        value: _resolution,
                        items: SplEnumExtensions.resolutionOptions,
                        onChanged: (String? v) {
                          setState(() => _resolution = v!);
                          _emit();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Light divider after top selectors
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),

                Text(
                  'Scaling for Mapping',
                  style: labelStyle?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),

                // SPL Range section
                _Section(
                  title: 'SPL Range',
                  initiallyExpanded: _splExpanded,
                  onExpansionChanged: (bool v) => setState(() => _splExpanded = v),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _toggleRow(
                        label: 'Scale Automatically',
                        value: _splAutoScale,
                        onChanged: (bool v) {
                          setState(() => _splAutoScale = v);
                          _emit();
                        },
                      ),
                      const SizedBox(height: 8),
                      Table(
                        columnWidths: const <int, TableColumnWidth>{0: col0, 1: FlexColumnWidth()},
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: <TableRow>[
                          _row(
                            label: 'Upper Limit (dB)',
                            labelStyle: labelStyle,
                            control: _tf(
                              controller: _splUpper,
                              hint: 'Value',
                              enabled: !_splAutoScale,
                            ),
                          ),
                          _row(
                            label: 'Lower Limit (dB)',
                            labelStyle: labelStyle,
                            control: _tf(
                              controller: _splLower,
                              hint: 'Value',
                              enabled: !_splAutoScale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper methods for creating UI components
  static TableRow _row({
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

  static Widget _dd({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 32,
      child: DropdownButtonFormField<String>(
        initialValue: value, // Fix deprecation warning: use initialValue instead of value
        isExpanded: true,
        style: const TextStyle(fontSize: 12, color: Colors.black),
        items: items
            .map(
              (String e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 12)),
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
    required String hint,
    required bool enabled,
  }) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        enabled: enabled,
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

  static String _numOrEmpty(double? v) => v == null ? '' : v.toString();
}

/// Immutable values emitted by the panel.
class SplPanelData {
  final String weighting;
  final String frequency;
  final String bandwidth;
  final String resolution;

  final bool splAutoScale;
  final bool splInvertColor;
  final double? splUpperDb;
  final double? splLowerDb;

  const SplPanelData({
    this.weighting = 'A-Weighted',
    this.frequency = '2 kHz',
    this.bandwidth = '3 Octaves',
    this.resolution = 'Medium',
    this.splAutoScale = false,
    this.splInvertColor = false,
    this.splUpperDb,
    this.splLowerDb,
  });

  @override
  String toString() =>
      'SplPanelData(weighting:$weighting, frequency:$frequency, bandwidth:$bandwidth, resolution:$resolution, '
      'splAuto:$splAutoScale, splInv:$splInvertColor, '
      'splU:$splUpperDb, splL:$splLowerDb)';
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
