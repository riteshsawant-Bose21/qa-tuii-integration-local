import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/properties/schematic_properties.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ColorSelector extends StatefulWidget {
  final String? selectedColor;
  final List<String> availableColors;
  final Function(String) onColorChanged;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? popupWidth;
  final int? gridColumns;
  final double? alpha;
  final bool enabled;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.availableColors,
    required this.onColorChanged,
    this.width = 24,
    this.height = 24,
    this.borderRadius = 4,
    this.popupWidth = 150,
    this.gridColumns = 5,
    this.alpha = 0.6,
    this.enabled = true,
  });

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showColorPicker() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideColorPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: _hideColorPicker,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: Stack(
              children: <Widget>[
                Positioned(
                  width: widget.popupWidth,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: const Offset(0, 30),
                    child: Material(
                      elevation: 12.0,
                      borderRadius: BorderRadius.circular(12),
                      child: FusionFlatContainer(
                        semanticsId: "zone_color_selector_popup",
                        padding: const EdgeInsets.all(12),
                        color: context.colorScheme.elevation2,
                        // decoration: BoxDecoration(
                        //   borderRadius: BorderRadius.circular(8),
                        // ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FusionAppText(
                              text: 'Select Color',
                              style: context.textTheme.l1Regular.copyWith(color: context.colorScheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.gridColumns!,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                childAspectRatio: 1,
                              ),
                              itemCount: widget.availableColors.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String hexCode = widget.availableColors[index];
                                final bool isSelected = hexCode == widget.selectedColor;

                                return GestureDetector(
                                  onTap: () {
                                    widget.onColorChanged(hexCode);
                                    _hideColorPicker();
                                  },
                                  child: SemanticHelper.container(
                                    testId: SemanticHelper.createTestId(SemanticTypes.container, "create_zone_color_option_$index"),
                                    isChecked: isSelected,
                                    isSelected: isSelected,
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
                          ],
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap:
            widget.enabled
                ? () {
                  if (_overlayEntry == null) {
                    _showColorPicker();
                  } else {
                    _hideColorPicker();
                  }
                }
                : null,
        child: SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "active_color"),
          value: widget.selectedColor,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: hexToColor(widget.selectedColor!), //.withAlpha(widget.alpha!.toInt()),
              border: Border.all(color: context.colorScheme.textPrimary),
              borderRadius: BorderRadius.circular(widget.borderRadius!),
            ),
          ),
        ),
      ),
    );
  }
}
