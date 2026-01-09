import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ColorSelector extends StatefulWidget {
  final Color selectedColor;
  final List<Color> availableColors;
  final Function(Color) onColorChanged;
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
    this.popupWidth = 200,
    this.gridColumns = 4,
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
      builder:
          (BuildContext context) => GestureDetector(
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
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const FusionAppText(
                                text: 'Select Color',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                  final Color color = widget.availableColors[index];
                                  final bool isSelected = color == widget.selectedColor;

                                  return GestureDetector(
                                    onTap: () {
                                      widget.onColorChanged(color);
                                      _hideColorPicker();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child:
                                          isSelected
                                              ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                              : null,
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
          ),
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
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.selectedColor.withValues(alpha: widget.alpha!),
            borderRadius: BorderRadius.circular(widget.borderRadius!),
          ),
        ),
      ),
    );
  }
}
