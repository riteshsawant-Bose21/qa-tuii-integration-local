import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplPanel extends StatefulWidget {
  const SplPanel({
    super.key,
    this.initial = const SplPanelData(),
    this.onChanged,
  });

  final SplPanelData initial;
  final ValueChanged<SplPanelData>? onChanged;

  @override
  State<SplPanel> createState() => _SplPanelState();
}

class _SplPanelState extends State<SplPanel> {
  // Top selections
  String _type = 'Direct SPL (A-Weighted)';
  String _frequency = '2000 Hz';
  String _bandwidth = '3 Octaves';
  String _resolution = 'Medium';

  // Direct SPL
  bool _directExpanded = true;
  bool _directAutoScale = false;
  bool _directInvert = false;
  final TextEditingController _directUpper = TextEditingController();
  final TextEditingController _directLower = TextEditingController();

  // S/N Ratio
  bool _snrExpanded = true;
  bool _snrAutoScale = false;
  bool _snrInvert = false;
  final TextEditingController _snrUpper = TextEditingController();
  final TextEditingController _snrLower = TextEditingController();

  static final List<TextInputFormatter> _numFmt = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[-]?\d*\.?\d*')),
  ];

  @override
  void initState() {
    super.initState();
    final SplPanelData i = widget.initial;
    _type = i.type;
    _frequency = i.frequency;
    _bandwidth = i.bandwidth;
    _resolution = i.resolution;

    _directAutoScale = i.directAutoScale;
    _directInvert = i.directInvertColor;
    _directUpper.text = _numOrEmpty(i.directUpperDb);
    _directLower.text = _numOrEmpty(i.directLowerDb);

    _snrAutoScale = i.snrAutoScale;
    _snrInvert = i.snrInvertColor;
    _snrUpper.text = _numOrEmpty(i.snrUpperDb);
    _snrLower.text = _numOrEmpty(i.snrLowerDb);

    for (final TextEditingController c in <TextEditingController>[_directUpper, _directLower, _snrUpper, _snrLower]) {
      c.addListener(_emit);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_directUpper, _directLower, _snrUpper, _snrLower]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged?.call(
      SplPanelData(
        type: _type,
        frequency: _frequency,
        bandwidth: _bandwidth,
        resolution: _resolution,
        directAutoScale: _directAutoScale,
        directInvertColor: _directInvert,
        directUpperDb: double.tryParse(_directUpper.text),
        directLowerDb: double.tryParse(_directLower.text),
        snrAutoScale: _snrAutoScale,
        snrInvertColor: _snrInvert,
        snrUpperDb: double.tryParse(_snrUpper.text),
        snrLowerDb: double.tryParse(_snrLower.text),
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
          final FlexColumnWidth col1 = const FlexColumnWidth();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Top selectors (Type/Frequency/Bandwidth/Resolution)
                Table(
                  columnWidths: const <int, TableColumnWidth>{0: col0, 1: FlexColumnWidth()},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: <TableRow>[
                    _row(
                      label: 'Type',
                      labelStyle: labelStyle,
                      control: _dd(
                        value: _type,
                        items: const <String>[
                          'Direct SPL (A-Weighted)',
                          'Direct SPL (C-Weighted)',
                          'Direct SPL (Z-Weighted)',
                        ],
                        onChanged: (String? v) {
                          setState(() => _type = v!);
                          _emit();
                        },
                      ),
                    ),
                    _row(
                      label: 'Frequency',
                      labelStyle: labelStyle,
                      control: _dd(
                        value: _frequency,
                        items: const <String>['250 Hz', '500 Hz', '1000 Hz', '2000 Hz', '4000 Hz'],
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
                        items: const <String>['1/3 Octave', '1 Octave', '3 Octaves', 'Full Band'],
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
                        items: const <String>['Low', 'Medium', 'High', 'Ultra'],
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

                // Direct SPL section
                _Section(
                  title: 'Direct SPL',
                  initiallyExpanded: _directExpanded,
                  onExpansionChanged: (bool v) => setState(() => _directExpanded = v),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _toggleRow(
                        label: 'Scale Automatically',
                        value: _directAutoScale,
                        onChanged: (bool v) {
                          setState(() => _directAutoScale = v);
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
                              controller: _directUpper,
                              hint: 'Value',
                              enabled: !_directAutoScale,
                            ),
                          ),
                          _row(
                            label: 'Lower Limit (dB)',
                            labelStyle: labelStyle,
                            control: _tf(
                              controller: _directLower,
                              hint: 'Value',
                              enabled: !_directAutoScale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _toggleRow(
                        label: 'Invert Color Scale',
                        value: _directInvert,
                        onChanged: (bool v) {
                          setState(() => _directInvert = v);
                          _emit();
                        },
                      ),
                    ],
                  ),
                ),

                // Light divider between sections
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.grey.shade300,
                  indent: 0,
                  endIndent: 0,
                ),

                // S/N Ratio section
                _Section(
                  title: 'S/N Ratio',
                  initiallyExpanded: _snrExpanded,
                  onExpansionChanged: (bool v) => setState(() => _snrExpanded = v),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _toggleRow(
                        label: 'Scale Automatically',
                        value: _snrAutoScale,
                        onChanged: (bool v) {
                          setState(() => _snrAutoScale = v);
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
                              controller: _snrUpper,
                              hint: 'Value',
                              enabled: !_snrAutoScale,
                            ),
                          ),
                          _row(
                            label: 'Lower Limit (dB)',
                            labelStyle: labelStyle,
                            control: _tf(
                              controller: _snrLower,
                              hint: 'Value',
                              enabled: !_snrAutoScale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _toggleRow(
                        label: 'Invert Color Scale',
                        value: _snrInvert,
                        onChanged: (bool v) {
                          setState(() => _snrInvert = v);
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
        value: value,
        isExpanded: true,
        style: const TextStyle(fontSize: 12, color: Colors.black),
        items:
            items
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
  final String type;
  final String frequency;
  final String bandwidth;
  final String resolution;

  final bool directAutoScale;
  final bool directInvertColor;
  final double? directUpperDb;
  final double? directLowerDb;

  final bool snrAutoScale;
  final bool snrInvertColor;
  final double? snrUpperDb;
  final double? snrLowerDb;

  const SplPanelData({
    this.type = 'Direct SPL (A-Weighted)',
    this.frequency = '2000 Hz',
    this.bandwidth = '3 Octaves',
    this.resolution = 'Medium',
    this.directAutoScale = false,
    this.directInvertColor = false,
    this.directUpperDb,
    this.directLowerDb,
    this.snrAutoScale = false,
    this.snrInvertColor = false,
    this.snrUpperDb,
    this.snrLowerDb,
  });

  @override
  String toString() =>
      'SplPanelData(type:$type, freq:$frequency, bw:$bandwidth, res:$resolution, '
      'directAuto:$directAutoScale, directInv:$directInvertColor, '
      'directU:$directUpperDb, directL:$directLowerDb, '
      'snrAuto:$snrAutoScale, snrInv:$snrInvertColor, '
      'snrU:$snrUpperDb, snrL:$snrLowerDb)';
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
        // childrenPadding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
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
