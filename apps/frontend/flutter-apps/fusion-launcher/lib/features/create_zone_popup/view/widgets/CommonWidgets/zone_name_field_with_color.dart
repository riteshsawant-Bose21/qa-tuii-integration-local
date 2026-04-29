import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/zone_model.dart';

import '../../../../projects/widget/building/side_panel_widgets/schematic_properties.dart';

class ZoneNameFieldWithColor extends StatefulWidget {
  const ZoneNameFieldWithColor({
    super.key,
    required this.zoneName,
    required this.zoneColor,
    required this.onNameChanged,
    required this.onColorChanged,
  });

  final String zoneName;
  final String zoneColor;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onColorChanged;

  @override
  State<ZoneNameFieldWithColor> createState() => _ZoneNameFieldWithColorState();
}

class _ZoneNameFieldWithColorState extends State<ZoneNameFieldWithColor> {
  bool _showColorGrid = false;
  bool _isHoveringDot = false;
  bool _isHoveringField = false;
  late final TextEditingController _controller;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String randomColor = Zone.zoneColors.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onColorChanged(randomColor);
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.zoneName);

    if (widget.zoneColor.isEmpty) {
      final math.Random random = math.Random();
      final String randomColor = Zone.zoneColors[random.nextInt(Zone.zoneColors.length)];
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onColorChanged(randomColor));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "create_zone_name_field_section"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: 'create_zone_name_field_label',
            text: "Zone Name",
            style: Theme.of(context).textTheme.l1Medium.withColor(context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 8),

          // ── Name row ──
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringField = true),
            onExit: (_) => setState(() => _isHoveringField = false),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                color: _isHoveringField ? context.colorScheme.elevation2 : Colors.transparent,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  // Color dot
                  SemanticHelper.container(
                    value: widget.zoneColor,
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "create_zone_color_dot"),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _isHoveringDot = true),
                      onExit: (_) => setState(() => _isHoveringDot = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _showColorGrid = !_showColorGrid),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: (widget.zoneColor.isNotEmpty) ? hexToColor(widget.zoneColor) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: context.colorScheme.zone1Stroke, width: 0.75),
                          ),
                          child: _isHoveringDot ? FusionIcon.icon(Icons.edit, size: 10, color: Colors.white) : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Name input
                  Expanded(
                    child: FusionTextField(
                      maxLength: 30,
                      semanticFieldId: 'create_zone_name_field',
                      controller: _controller,
                      hintText: "Enter zone name",
                      decoration: InputDecoration(
                        hintText: "Enter zone name",
                        labelStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPrimary),
                        hintStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPlaceholder),
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: widget.onNameChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Color grid (collapsible) ──
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "create_zone_color_grid_section"),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              curve: Curves.easeOut,
              child: SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (BuildContext context) {
                    if (_showColorGrid) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colorScheme.elevation4, width: 1),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 16,
                              crossAxisSpacing: 7,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: Zone.zoneColors.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String hexCode = Zone.zoneColors[index];
                              final bool isSelected = widget.zoneColor == hexCode;
                              return GestureDetector(
                                onTap: () {
                                  widget.onColorChanged(hexCode);
                                  setState(() => _showColorGrid = false);
                                },
                                child: SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "create_zone_color_option_$index"),
                                  isChecked: isSelected,
                                  value: hexCode,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: hexToColor(hexCode),
                                      borderRadius: BorderRadius.circular(3),
                                      border: isSelected ? Border.all(color: context.colorScheme.primaryWhite, width: 2) : null,
                                    ),
                                    child: isSelected ? FusionIcon.icon(Icons.check, color: Colors.white, size: 10) : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
