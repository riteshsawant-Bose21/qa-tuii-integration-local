import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_algorithms/surface_speakers_autolayout/surface_speakers_autolayout.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/assets/asset_svg.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class AutoPlaceDialog extends StatefulWidget {
  const AutoPlaceDialog({super.key, this.result});

  final AutoPlacementResult? result;

  @override
  State<AutoPlaceDialog> createState() => _AutoPlaceDialogState();
}

class _AutoPlaceDialogState extends State<AutoPlaceDialog> {
  late AutoPlacementResult _result;
  final TextEditingController ceilingHeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _result = widget.result ?? const AutoPlacementResult();
  }

  @override
  void dispose() {
    ceilingHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = context.colorScheme;

    return Container(
      width: 600,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              FusionAppText(
                text: 'AUTO-PLACEMENT',
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.8), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cs.elevation2.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: cs.elevation1, width: 4),
                      ),
                    ),
                    child: _buildSpacingSection(context),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(child: _buildLayoutSection(context)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () {
                  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
                  final ResponseCallback<bool> response = projectViewModel.runAutoPlacementForCurrentListeningArea(autoPlacementResult: _result);
                  if (!response.success) {
                    FusionToast.error(context, message: response.message);
                  } else {
                    FusionToast.success(context, message: 'Auto-placement completed successfully');
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.elevation3,
                  foregroundColor: cs.onSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const FusionAppText(text: 'Update'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingSection(BuildContext context) {
    final ColorScheme cs = context.colorScheme;

    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final ListeningArea? selectedListeningArea = projectViewModel.getCurrentSelectedListeningArea();
    ceilingHeightController.text = selectedListeningArea?.ceilingHeight.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'SPACING',
            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _presetTile(
                      context,
                      label: 'Edge-to-edge',
                      icon: AssetSvg.edgeToEdge,
                      selected: _result.autoPlaceCoveragePreference == CoveragePreference.edgeToEdge,
                      onTap: () => setState(() => _result = _result.copyWith(autoPlaceCoveragePreference: CoveragePreference.edgeToEdge)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _presetTile(
                      context,
                      label: 'Minimum Overlap',
                      icon: AssetSvg.minOverlap,
                      selected: _result.autoPlaceCoveragePreference == CoveragePreference.minimumOverlap,
                      onTap: () => setState(() => _result = _result.copyWith(autoPlaceCoveragePreference: CoveragePreference.minimumOverlap)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _presetTile(
                      context,
                      label: 'Center-to-center',
                      icon: AssetSvg.centreToCentre,
                      selected: _result.autoPlaceCoveragePreference == CoveragePreference.centerToCenter,
                      onTap: () => setState(() => _result = _result.copyWith(autoPlaceCoveragePreference: CoveragePreference.centerToCenter)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: SizedBox(),
                    // _presetTile(
                    //   context,
                    //   label: 'Customize',
                    //   icon: AssetSvg.customise,
                    //   selected: _result.autoPlaceCoveragePreference == CoveragePreference.customize,
                    //   // onTap: () => setState(() => _result = _result.copyWith(autoPlaceCoveragePreference: CoveragePreference.customize)),
                    //   onTap: () {},
                    // ),
                  ),
                ],
              ),
              // const SizedBox(height: 10),
              // _labeledRadioNumber(
              //   context,
              //   label: 'Custom',
              //   // selected: _result.autoPlaceCoveragePreference == AutoPlaceCoveragePreference.customize,
              //   selected: false,
              //   // value: _result.autoPlaceCustomSpacing,
              //   value: 0.0,
              //   // onSelect: () => setState(() => _result = _result.copyWith(autoPlaceCoveragePreference: AutoPlaceCoveragePreference.customize)),
              //   onSelect: () {},
              //   // onChanged: (double v) => setState(() => _result = _result.copyWith(autoPlaceCustomSpacing: v)),
              //   onChanged: (double v) {},
              // ),
              // const SizedBox(height: 8),
              // _labeledCheckboxNumber(
              //   context,
              //   label: 'Match Grid',
              //   // selected: _result.autoPlaceMatchGrid,
              //   selected: false,
              //   value: 0.6,
              //   // onChanged: (bool v) => setState(() => _result = _result.copyWith(autoPlaceMatchGrid: v)),
              //   onChanged: (bool v) {},
              // ),

              // const SizedBox(height: 10),
              // Row(
              //   spacing: 5,
              //   children: <Widget>[
              //     Expanded(child: FusionAppText(text: "Coverage Angle", style: context.textTheme.bodySmall)),
              //     Expanded(
              //       child: PropertyTextField(
              //         initialValue: _result.autoPlaceCoverageAngle.toStringAsFixed(0),
              //         onSubmitted: (String raw) {
              //           final double? parsed = double.tryParse(raw);
              //           if (parsed != null) {
              //             setState(() => _result = _result.copyWith(autoPlaceCoverageAngle: parsed.clamp(0.0, 180.0)));
              //           }
              //         },
              //         inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}$'))],
              //       ),
              //     ),
              //     FusionAppText(
              //       text: "deg",
              //       capitalize: false,
              //       style: context.textTheme.bodySmall,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 10),

              // BuildingPageTextField(
              //   label: "Ceiling Height (m)",
              //   controller: ceilingHeightController,
              //   hintText: "e.g. ${ListeningHeightOption.maxListeningHeight}",
              //   fillColor: context.colorScheme.elevation1,
              //   inputFormatters: <TextInputFormatter>[
              //     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              //   ],
              //   onFieldSubmitted: (String newValue) {
              //     if (selectedListeningArea == null) return;
              //     final double? parsed = double.tryParse(newValue);
              //     if (parsed == null) return;
              //     final ListeningArea updatedLA = selectedListeningArea.copyWith(ceilingHeight: parsed.toString());
              //     projectViewModel.updateListeningArea(area: updatedLA);
              //   },
              // ),
              // const SizedBox(height: 10),

              // FusionAppText(
              //   text: 'Boundary Threshold',
              //   style: context.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.85)),
              // ),
              // const SizedBox(height: 8),
              // FusionSlider(
              //   value: _result.autoPlaceBoundaryThreshold,
              //   min: 0.3,
              //   max: 1,
              //   onChanged: (double value) {
              //     setState(() => _result = _result.copyWith(autoPlaceBoundaryThreshold: value.clamp(0.0, 1.0)));
              //   },
              // ),
              // Row(
              //   children: <Widget>[
              //     FusionAppText(
              //       text: '30%',
              //       style: context.textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 9),
              //     ),
              //     const Spacer(),
              //     FusionAppText(
              //       text: '100%',
              //       style: context.textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 9),
              //     ),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutSection(BuildContext context) {
    final ColorScheme cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'LAYOUT',
            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _layoutTile(
                      context,
                      label: 'Square',
                      icon: AssetSvg.autoplaceSquare,
                      selected: _result.autoPlaceLayoutPattern == LayoutPattern.square,
                      onTap: () => setState(() => _result = _result.copyWith(autoPlaceLayoutPattern: LayoutPattern.square)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _layoutTile(
                      context,
                      label: 'Hexagonal',
                      icon: AssetSvg.autoplaceHexagonal,
                      selected: _result.autoPlaceLayoutPattern == LayoutPattern.hexagonal,
                      onTap: () => setState(() => _result = _result.copyWith(autoPlaceLayoutPattern: LayoutPattern.hexagonal)),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 12),
              // _xyField(
              //   context,
              //   axis: 'X',
              //   label: 'Grid Offset',
              //   // value: _result.autoPlaceGridX,
              //   value: 0.0,
              //   // onChanged: (double v) => setState(() => _result = _result.copyWith(autoPlaceGridX: v)),
              //   onChanged: (double v) {},
              // ),
              // const SizedBox(height: 8),
              // _xyField(
              //   context,
              //   axis: 'Y',
              //   label: '',
              //   // value: _result.autoPlaceOffsetY,
              //   value: 0.0,
              //   // onChanged: (double v) => setState(() => _result = _result.copyWith(autoPlaceOffsetY: v)),
              //   onChanged: (double v) {},
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetTile(
    BuildContext context, {
    required String label,
    required String icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ColorScheme cs = context.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.35)),
          color: selected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Column(
          children: <Widget>[
            FusionAppText(
              text: label,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            FusionIcon.svg(icon, color: cs.onSurface.withValues(alpha: 0.65)),
          ],
        ),
      ),
    );
  }

  Widget _layoutTile(
    BuildContext context, {
    required String label,
    required String icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ColorScheme cs = context.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.35)),
          color: selected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Column(
          children: <Widget>[
            FusionAppText(
              text: label,
              style: context.textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Center(child: FusionIcon.svg(icon, color: cs.onSurface.withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }

  Widget _labeledRadioNumber(
    BuildContext context, {
    required String label,
    required bool selected,
    required double value,
    required VoidCallback onSelect,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: onSelect,
          child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodySmall,
          ),
        ),
        _numberPill(context, value, onChanged),
      ],
    );
  }

  Widget _labeledCheckboxNumber(
    BuildContext context, {
    required String label,
    required bool selected,
    required double value,
    required ValueChanged<bool> onChanged,
    bool hideValue = false,
  }) {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () => onChanged(!selected),
          child: Icon(selected ? Icons.check_box : Icons.check_box_outline_blank, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.labelSmall,
          ),
        ),
        if (!hideValue) _numberPill(context, value, null),
      ],
    );
  }

  Widget _xyField(
    BuildContext context, {
    required String axis,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: <Widget>[
        Expanded(child: FusionAppText(text: label)),
        FusionAppText(
          text: axis,
          style: context.textTheme.labelSmall,
        ),
        const SizedBox(width: 6),
        _numberPill(context, value, onChanged),
      ],
    );
  }

  Widget _numberPill(BuildContext context, double value, ValueChanged<double>? onChanged) {
    final TextEditingController ctrl = TextEditingController(text: value.toStringAsFixed(1));
    return Container(
      width: 64,
      height: 28,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onSubmitted:
                  onChanged == null
                      ? null
                      : (String raw) {
                        final double parsed = double.tryParse(raw) ?? value;
                        onChanged(parsed);
                      },
            ),
          ),
          FusionAppText(
            text: 'm',
            style: context.textTheme.labelSmall?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class FusionSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const FusionSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 12,
        trackShape: const _FusionSliderTrackShape(),
        thumbShape: const _SquareSliderThumbShape(
          thumbRadius: 6,
          cornerRadius: 3,
        ),
        overlayShape: SliderComponentShape.noOverlay,
        thumbColor: Colors.white,
        activeTrackColor: context.colorScheme.primaryColor,
        inactiveTrackColor: context.colorScheme.elevation4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FusionSliderTrackShape extends SliderTrackShape {
  const _FusionSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 12;

    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;

    return Rect.fromLTWH(offset.dx, trackTop, parentBox.size.width, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Canvas canvas = context.canvas;

    final Rect trackRect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);

    final RRect trackRRect = RRect.fromRectAndRadius(trackRect, const Radius.circular(4));

    /// Inactive track
    canvas.drawRRect(trackRRect, Paint()..color = sliderTheme.inactiveTrackColor!);

    /// Active track (LEFT → THUMB)
    final Rect activeRect = Rect.fromLTRB(trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom);

    canvas.drawRect(activeRect, Paint()..color = sliderTheme.activeTrackColor!);
  }
}

class _SquareSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double cornerRadius;

  const _SquareSliderThumbShape({required this.thumbRadius, this.cornerRadius = 3});

  @override
  Size getPreferredSize(bool isEnabled, bool isInteractive) {
    return Size(thumbRadius * 2, thumbRadius * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: thumbRadius * 2,
          height: thumbRadius * 2,
        ),
        Radius.circular(cornerRadius),
      ),
      Paint()
        ..color = sliderTheme.thumbColor ?? Colors.white
        ..style = PaintingStyle.fill,
    );
  }
}
