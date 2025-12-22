import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/properties_and_filter_section.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SourceOption {
  singleSource("Single Source"),
  multipleSources("Multiple Sources");

  const SourceOption(this.displayName);
  final String displayName;
}

enum SourceOptionType {
  mono("Mono"),
  stereo("Stereo"),
  monoSum("Mono-Sum");

  const SourceOptionType(this.displayName);
  final String displayName;
}

class CreateZonePopup extends StatelessWidget {
  final Widget child;
  const CreateZonePopup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      blurAmount: 1,
      backgroundColor: const Color(0xFF292826),
      content: Container(
        width: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF292826),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ADD SOURCE
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: 'CREATE ZONE',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(LucideIcons.x200, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 0.5, height: 0),
            Padding(
              padding: const EdgeInsetsGeometry.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionColorPicker(
                    initialColor: context.colorScheme.primaryColor,
                    onChanged: (Color value) {
                      //
                    },
                  ),

                  FusionRadio<SourceOption>(
                    selected: SourceOption.singleSource,
                    options: SourceOption.values,
                    labelBuilder: (SourceOption option) {
                      return FusionAppText(
                        text: option.displayName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                    onChanged: (SourceOption value) {},
                  ),
                  const SizedBox(height: 20),
                  BuildRowPropertyWidget(
                    label: "Type",
                    value: "Value",
                    options: <String>["Value"],
                    onOptionSelected: (int value) {
                      //
                    },
                  ),
                  const SizedBox(height: 5),
                  BuildRowPropertyWidget(
                    label: "",
                    value: "Value",
                    options: <String>["Value"],
                    onOptionSelected: (int value) {
                      //
                    },
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NeumorphicDarkButton(
                      onTap: () {},
                      backgroundColor: context.colorScheme.surface,
                      width: 32,
                      height: 32,
                      borderRadius: 8,
                      child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                    ),
                  ),

                  //
                  const SizedBox(height: 10),
                  BuildRowPropertyWidget(
                    label: "Location",
                    value: "Value",
                    options: <String>["Value"],
                    onOptionSelected: (int value) {
                      //
                    },
                  ),
                  const SizedBox(height: 5),
                  BuildRowPropertyWidget(
                    label: "",
                    value: "Value",
                    options: <String>["Value"],
                    onOptionSelected: (int value) {
                      //
                    },
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NeumorphicDarkButton(
                      onTap: () {},
                      backgroundColor: context.colorScheme.surface,
                      width: 32,
                      height: 32,
                      borderRadius: 8,
                      child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 10),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: <Widget>[
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF595752),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          DefaultTextStyle.merge(
                            style: context.textTheme.bodySmall,
                            child: FusionAppText(
                              text: "Use only in this location",
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FusionRadio<SourceOptionType>(
                    selected: SourceOptionType.mono,
                    options: SourceOptionType.values,
                    labelBuilder: (SourceOptionType option) {
                      return FusionAppText(
                        text: option.displayName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                    onChanged: (SourceOptionType value) {},
                  ),
                  const SizedBox(height: 5),
                  BuildRowPropertyWidget(
                    label: "Connection",
                    value: "Value",
                    options: <String>["Value"],
                    onOptionSelected: (int value) {
                      //
                    },
                  ),
                  const SizedBox(height: 5),
                  BuildRowPropertyWidget(
                    label: "Name",
                    value: "Value",
                    options: <String>["Value"],
                    onOptionSelected: (int value) {
                      //
                    },
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      // Cancel & Save buttons
                      GestureDetector(
                        onTap: Navigator.of(context).pop,
                        child: FusionAppText(
                          text: "Cancel",
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      NeumorphicDarkButton(
                        onTap: () {},
                        backgroundColor: context.colorScheme.surface,
                        text: "Save",
                        width: 69,
                        height: 32,
                        borderRadius: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}

class FusionColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onChanged;

  const FusionColorPicker({
    super.key,
    required this.initialColor,
    required this.onChanged,
  });

  @override
  State<FusionColorPicker> createState() => _FusionColorPickerState();
}

class _FusionColorPickerState extends State<FusionColorPicker> {
  late Color _currentColor;
  late TextEditingController _hexController;

  final List<Color> presetColors = const <Color>[
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
    Color(0xFF757575),
    Color(0xFF546E7A),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hexController = TextEditingController(
      text: _toHex(_currentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int portraitCrossAxisCount = 4;
    final int landscapeCrossAxisCount = 5;
    final double borderRadius = 30;
    final double blurRadius = 5;
    final double iconSize = 24;

    Widget pickerLayoutBuilder(BuildContext context, List<Color> colors, PickerItem child) {
      final Orientation orientation = MediaQuery.of(context).orientation;

      return SizedBox(
        width: 300,
        height: orientation == Orientation.portrait ? 360 : 240,
        child: GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? portraitCrossAxisCount : landscapeCrossAxisCount,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          children: <Widget>[for (Color color in colors) child(color)],
        ),
      );
    }

    Widget pickerItemBuilder(Color color, bool isCurrentColor, void Function() changeColor) {
      return Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: color,
          boxShadow: <BoxShadow>[BoxShadow(color: color.withOpacity(0.8), offset: const Offset(1, 2), blurRadius: blurRadius)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: changeColor,
            borderRadius: BorderRadius.circular(borderRadius),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isCurrentColor ? 1 : 0,
              child: Icon(
                Icons.done,
                size: iconSize,
                color: useWhiteForeground(color) ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _header(),
        const SizedBox(height: 12),

        /// 🎨 Main Picker
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return ColorPicker(
              pickerColor: widget.initialColor,
              onColorChanged: widget.onChanged,
              colorPickerWidth: 0,
            );
          },
        ),

        const SizedBox(height: 12),
        _hexRow(),
        const SizedBox(height: 12),
        _presetGrid(),
      ],
    );
  }

  // ───────────────── HEADER ─────────────────
  Widget _header() {
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.colorize,
          size: 18,
          color: Colors.white.withOpacity(0.7),
        ),
      ],
    );
  }

  // ───────────────── HEX + OPACITY ─────────────────
  Widget _hexRow() {
    return Row(
      children: <Widget>[
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: 'HEX',
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'HEX', child: Text('HEX')),
            ],
            onChanged: (_) {},
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _hexController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onSubmitted: _onHexSubmitted,
          ),
        ),
        Text(
          '${(_currentColor.opacity * 100).round()}%',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  // ───────────────── PRESETS ─────────────────
  Widget _presetGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          presetColors.map((Color color) {
            return GestureDetector(
              onTap: () => _onColorChanged(color),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      color == _currentColor ? 1 : 0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ───────────────── HELPERS ─────────────────
  void _onColorChanged(Color color) {
    setState(() {
      _currentColor = color;
      _hexController.text = _toHex(color);
    });
    widget.onChanged(color);
  }

  void _onHexSubmitted(String value) {
    final String hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      _onColorChanged(Color(int.parse('0xFF$hex')));
    }
  }

  String _toHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
