import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_algorithms/surface_speakers_autolayout/surface_speakers_autolayout.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/assets/asset_svg.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../home/presentation/widgets/algorithms/ceiling_pendant_speaker_layout_widget.dart';

class AutoPlaceDialog extends StatefulWidget {
  const AutoPlaceDialog({super.key, this.result});

  final AutoPlacementParam? result;

  @override
  State<AutoPlaceDialog> createState() => _AutoPlaceDialogState();
}

class _AutoPlaceDialogState extends State<AutoPlaceDialog> {
  late AutoPlacementParam _result;
  final TextEditingController ceilingHeightController = TextEditingController();
  SpeakerPlacementAlgorithmResult? algorithmResult;

  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _result = widget.result ?? const AutoPlacementParam();
  }

  @override
  void dispose() {
    ceilingHeightController.dispose();
    errorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = context.colorScheme;
    final ListeningArea listeningArea = serviceLocator<ProjectViewModel>().getCurrentSelectedListeningArea()!;
    final MountingType mountingType = listeningArea.mountingType;
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
              if (algorithmResult?.surfacePlacementResult?.debugInfo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      _SurfacePlacementDebugDialog.show(
                        context,
                        result: algorithmResult!.surfacePlacementResult!,
                      );
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.bug_report_outlined, color: Colors.orangeAccent, size: 18),
                    ),
                  ),
                ),
              // if (algorithmResult?.surfacePlacementResult != null)
              //   InkWell(
              //     onTap: () {
              //       _SurfaceAlgoResult.show(
              //         context,
              //         result: algorithmResult!.surfacePlacementResult!,
              //         coverageAngle: algorithmResult!.coverageAngle,
              //         listnersHeight: algorithmResult!.listnersHeight,
              //         coveragePreference: algorithmResult!.coveragePreference,
              //         width: algorithmResult!.width,
              //         length: algorithmResult!.length,
              //       );
              //     },
              //     child: const Icon(
              //       Icons.info_outline,
              //       color: Colors.greenAccent,
              //       size: 18,
              //     ),
              //   ),
              if (algorithmResult?.placementResult != null)
                InkWell(
                  onTap: () {
                    CeilingPlacementResult.show(
                      context: context,
                      result: algorithmResult!.placementResult!,
                      coverageAngle: algorithmResult!.coverageAngle,
                      roomWidth: algorithmResult!.width,
                      roomLength: algorithmResult!.length,
                      selectedCoveragePreference: algorithmResult!.coveragePreference,
                      selectedLayoutPattern: algorithmResult!.ceilingPlacementParams!.selectedLayoutPattern,
                      boundaryOverlapThreshold: algorithmResult!.ceilingPlacementParams!.boundaryOverlapThreshold,
                      selectedSpeakerType: algorithmResult!.ceilingPlacementParams!.selectedSpeakerType,
                      selectedRoomType: algorithmResult!.ceilingPlacementParams!.selectedRoomType,
                      customGeometry: algorithmResult!.ceilingPlacementParams!.customGeometry ?? <Point2D>[],
                    );
                  },
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.greenAccent,
                    size: 18,
                  ),
                ),
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
                if (mountingType == MountingType.ceiling || mountingType == MountingType.pendant) Expanded(child: _buildLayoutSection(context)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ValueListenableBuilder<String?>(
            valueListenable: errorNotifier,
            builder: (BuildContext context, String? value, Widget? child) {
              if (value == null || value.isEmpty) return const SizedBox();

              return Row(
                children: <Widget>[
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FusionAppText(
                      text: value,
                      style: context.textTheme.l1Regular.copyWith(color: Colors.redAccent),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () {
                  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
                  final ResponseCallback<SpeakerPlacementAlgorithmResult> response = projectViewModel.runAutoPlacementForCurrentListeningArea(
                    autoPlacementResult: _result,
                  );

                  if (!response.success) {
                    errorNotifier.value = response.message;
                  } else {
                    errorNotifier.value = null;
                    FusionToast.success(context, message: 'Auto-placement completed successfully');
                    setState(() {
                      algorithmResult = response.data;
                    });
                    // Navigator.of(context).pop();
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutSection(BuildContext context) {
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
}

class _SurfaceAlgoResult extends StatelessWidget {
  static show(
    BuildContext context, {
    required SurfacePlacementResult result,
    required double coverageAngle,
    required double listnersHeight,
    required CoveragePreference coveragePreference,
    required double width,
    required double length,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: _SurfaceAlgoResult(
            result: result,
            coverageAngle: coverageAngle,
            listnersHeight: listnersHeight,
            coveragePreference: coveragePreference,
            width: width,
            length: length,
          ),
        );
      },
    );
  }

  const _SurfaceAlgoResult({
    required this.result,
    required this.coverageAngle,
    required this.listnersHeight,
    required this.coveragePreference,
    required this.width,
    required this.length,
  });
  final SurfacePlacementResult result;
  final double coverageAngle;
  final double listnersHeight;
  final CoveragePreference coveragePreference;
  final double width;
  final double length;

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      child: ListView(
        children: <Widget>[
          _buildDownAngleReferenceCard(context),
          SizedBox(height: context.mediumGap),
          _buildResultsCard(context),
          SizedBox(height: context.mediumGap),
          Center(child: FusionButton(label: "Close", onTap: () => Navigator.of(context).pop(), accessLabel: "Close dialog")),
          SizedBox(height: context.mediumGap),
        ],
      ),
    );
  }

  Widget _buildDownAngleReferenceCard(BuildContext context) {
    return FusionFlatContainer(
      color: context.colorScheme.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.table_chart,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Down Angle Reference Table',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: <Widget>[
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Mounting Height (m)',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      Expanded(
                        child: Text(
                          'Down-angle (deg)',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Table rows
                _buildTableRow(
                  'Less than 2.4',
                  '-5',
                  result.mountingHeight < 2.4,
                  context,
                ),
                _buildTableRow(
                  '2.4 - 4.6',
                  '-15',
                  result.mountingHeight >= 2.4 && result.mountingHeight <= 4.6,
                  context,
                ),
                _buildTableRow(
                  '4.6 - 5.5',
                  '-30',
                  result.mountingHeight >= 4.6 && result.mountingHeight <= 5.5,
                  context,
                ),
                _buildTableRow(
                  '5.5 and above',
                  '-45',
                  result.mountingHeight >= 5.5,
                  context,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The highlighted row shows the range for your current mounting height.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String height, String angle, bool isHighlighted, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5)
                : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              height,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: Text(
              angle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context) {
    return Column(
      children: <Widget>[
        // Quick Summary Card
        FusionFlatContainer(
          color: Colors.blue.withValues(alpha: 0.1),
          borderColor: Colors.blue,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.summarize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Speaker Layout Summary',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildSummaryMetric(
                      context,
                      'Total Speakers',
                      '${result.totalSpeakers}',
                      Icons.speaker_group,
                    ),
                    _buildSummaryMetric(
                      context,
                      'Front/Back Walls',
                      '${result.speakersOnLength} each',
                      Icons.linear_scale,
                    ),
                    _buildSummaryMetric(
                      context,
                      'Left/Right Walls',
                      '${result.speakersOnWidth} each',
                      Icons.linear_scale_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detailed Step-by-Step Calculations
        _buildCalculationStepsCard(
          context,
        ),
      ],
    );
  }

  Widget _buildSummaryMetric(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCalculationStepsCard(BuildContext context) {
    return FusionFlatContainer(
      color: context.colorScheme.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.calculate,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Calculation Steps',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1: Find distance d from loudspeaker to listener plane
          _buildCalculationStep(
            context: context,
            stepNumber: 1,
            title: 'Find Distance from Loudspeaker to Listener Plane',
            icon: Icons.straighten,
            formula: 'd_horiz = (mounting_height - listener_height) / tan(down_angle)',
            calculation:
                'd_horiz = (${result.mountingHeight.toStringAsFixed(1)} - $listnersHeight) / tan(${result.downAngle.abs().toStringAsFixed(0)}°)\n'
                'd_horiz = ${(result.mountingHeight - listnersHeight).toStringAsFixed(1)} / ${(tan(result.downAngle.abs() * pi / 180)).toStringAsFixed(3)}\n'
                'd_horiz = ${result.distanceToListenerPlane.toStringAsFixed(2)} m',
            result: 'd_horiz = ${result.distanceToListenerPlane.toStringAsFixed(2)} m',
            explanation: 'Horizontal distance from loudspeaker to the listener plane using the down-angle',
          ),

          // Step 2: Determine horizontal coverage
          _buildCalculationStep(
            context: context,
            stepNumber: 2,
            title: 'Determine Horizontal Coverage at Initial Mounting Height',
            icon: Icons.radio_button_unchecked,
            formula: 'Horizontal_coverage = 2 × tan(θ/2) × d',
            calculation:
                'Horizontal_coverage = 2 × tan($coverageAngle°/2) × ${result.distanceToListenerPlane.toStringAsFixed(2)}\n'
                'Horizontal_coverage = 2 × tan(${(coverageAngle / 2).toStringAsFixed(1)}°) × ${result.distanceToListenerPlane.toStringAsFixed(2)}\n'
                'Horizontal_coverage = 2 × ${(tan((coverageAngle / 2) * pi / 180)).toStringAsFixed(3)} × ${result.distanceToListenerPlane.toStringAsFixed(2)}\n'
                'Horizontal_coverage = ${result.coverageWidth.toStringAsFixed(2)} m',
            result: '${result.coverageWidth.toStringAsFixed(2)} m',
            explanation: 'Horizontal coverage slice the loudspeaker provides at the initial mounting height',
          ),

          // Step 3: Place speakers around perimeter with overlap
          _buildCalculationStep(
            context: context,
            stepNumber: 3,
            title: 'Place Horizontal Loudspeakers Around Perimeter',
            icon: Icons.grid_view,
            formula: 'Speakers per Wall = ceil(Wall Length / Effective Coverage)',
            calculation:
                'Effective Coverage = ${result.coverageWidth.toStringAsFixed(2)} × ${coveragePreference.overlapMultiplier} (${coveragePreference.name}) = ${result.effectiveCoverage.toStringAsFixed(2)} m\n\n'
                'Length Walls ($length m): ceil($length / ${result.effectiveCoverage.toStringAsFixed(2)}) = ${result.speakersOnLength} each\n'
                'Width Walls ($width m): ceil($width / ${result.effectiveCoverage.toStringAsFixed(2)}) = ${result.speakersOnWidth} each\n\n'
                'Total: (${result.speakersOnLength} × 2) + (${result.speakersOnWidth} × 2) = ${result.totalSpeakers} speakers',
            result: 'Total: ${result.totalSpeakers} speakers',
            explanation: 'Place horizontal loudspeakers around perimeter such that desired overlap is fulfilled',
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationStep({
    required BuildContext context,
    required int stepNumber,
    required String title,
    required IconData icon,
    required String formula,
    required String calculation,
    required String result,
    required String explanation,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Step Header
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Formula
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.functions,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formula,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Calculation
          Text(
            'Calculation:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            calculation,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Explanation
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  explanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debug dialog – shows step-by-step placement info + visualisation of all
// provisional, placed, and removed speaker positions on the room polygon.
// ─────────────────────────────────────────────────────────────────────────────

class _SurfacePlacementDebugDialog extends StatelessWidget {
  static void show(BuildContext context, {required SurfacePlacementResult result}) {
    showDialog(
      context: context,
      builder:
          (BuildContext ctx) => Dialog(
            insetPadding: const EdgeInsets.all(24),
            child: _SurfacePlacementDebugDialog(result: result),
          ),
    );
  }

  const _SurfacePlacementDebugDialog({required this.result});

  final SurfacePlacementResult result;

  @override
  Widget build(BuildContext context) {
    final SurfacePlacementDebugInfo? debug = result.debugInfo;
    return SizedBox(
      width: 680,
      height: 700,
      child: Column(
        children: <Widget>[
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _buildCalculationSection(context),
                const SizedBox(height: 16),
                if (debug != null) ...<Widget>[
                  _buildVisualisationSection(context, debug),
                  const SizedBox(height: 16),
                  _buildRemovedSpeakersSection(context, debug),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.bug_report_outlined, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            'Placement Debug Info',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationSection(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double ceilingHeight = result.mountingHeight + 0.15;
    final double overlapMultiplier = result.coverageWidth > 0 ? result.effectiveCoverage / result.coverageWidth : 1.0;
    final String downAngleRange =
        result.downAngle == -5.0
            ? '(h < 2.4 m)'
            : result.downAngle == -15.0
            ? '(2.4 – 4.6 m)'
            : result.downAngle == -30.0
            ? '(4.6 – 5.5 m)'
            : '(> 5.5 m)';

    return _DebugCard(
      title: 'Step-by-Step Calculations',
      icon: Icons.calculate_outlined,
      children: <Widget>[
        // ── Step 1: Mounting height ──────────────────────────────────────
        _StepBlock(
          step: 1,
          title: 'Mounting Height',
          formula: 'h_mount = h_ceiling − 0.15',
          substitution: 'h_mount = ${ceilingHeight.toStringAsFixed(2)} − 0.15',
          resultValue: '${result.mountingHeight.toStringAsFixed(2)} m',
          explanation: '15 cm clearance below ceiling for speaker bracket / mount.',
        ),
        const SizedBox(height: 10),

        // ── Step 2: Down-angle ───────────────────────────────────────────
        _StepBlock(
          step: 2,
          title: 'Down-Angle',
          formula: 'θ = design-guide table lookup(h_mount)',
          substitution: 'h_mount = ${result.mountingHeight.toStringAsFixed(2)} m  →  $downAngleRange',
          resultValue: '${result.downAngle.toStringAsFixed(1)}°',
          explanation: 'Steeper angle for higher ceilings keeps projection on the listener plane.',
        ),
        const SizedBox(height: 10),

        // ── Step 3: Distance to listener plane ───────────────────────────
        _StepBlock(
          step: 3,
          title: 'Distance to Listener Plane',
          formula: 'd = (h_mount − h_listener) ÷ tan(|θ|)',
          substitution: 'd = (${result.mountingHeight.toStringAsFixed(2)} − h_listener) ÷ tan(${result.downAngle.abs().toStringAsFixed(1)}°)',
          resultValue: '${result.distanceToListenerPlane.toStringAsFixed(3)} m',
          explanation: 'Horizontal throw from the speaker to the listener-ear plane.',
        ),
        const SizedBox(height: 10),

        // ── Step 4: Coverage width ────────────────────────────────────────
        _StepBlock(
          step: 4,
          title: 'Coverage Width at Listener Plane',
          formula: 'w = 2 × tan(φ ÷ 2) × d',
          substitution: 'w = 2 × tan(${result.horizontalCoverageAngle.toStringAsFixed(1)}° ÷ 2) × ${result.distanceToListenerPlane.toStringAsFixed(3)}',
          resultValue: '${result.coverageWidth.toStringAsFixed(3)} m',
          explanation: 'Width of the directional coverage sector at listener-ear height.',
        ),
        const SizedBox(height: 10),

        // ── Step 5: Effective coverage ────────────────────────────────────
        _StepBlock(
          step: 5,
          title: 'Effective Coverage (Spacing)',
          formula: 'e = w × overlap_multiplier',
          substitution: 'e = ${result.coverageWidth.toStringAsFixed(3)} × ${overlapMultiplier.toStringAsFixed(2)}',
          resultValue: '${result.effectiveCoverage.toStringAsFixed(3)} m',
          explanation: 'Per-wall speaker spacing — controls how much adjacent coverage zones overlap.',
        ),

        const Divider(height: 24),

        // ── Room + resolution summary ─────────────────────────────────────
        _DebugRow('Coverage angle (horizontal)', '${result.horizontalCoverageAngle.toStringAsFixed(1)}°'),
        _DebugRow('Room bounding-box length', '${result.roomLength.toStringAsFixed(2)} m'),
        _DebugRow('Room bounding-box width', '${result.roomWidth.toStringAsFixed(2)} m'),
        if (result.debugInfo != null) ...<Widget>[
          const SizedBox(height: 4),
          _DebugRow('Provisional speaker count', '${result.debugInfo!.provisionalPositions.length}'),
          _DebugRow('Corner-collision threshold', '${result.debugInfo!.cornerThreshold.toStringAsFixed(3)} m'),
          _DebugRow('Adjacent-merge threshold', '${result.debugInfo!.adjacentOverlapThreshold.toStringAsFixed(3)} m'),
          _DebugRow('Removed / merged', '${result.debugInfo!.removedSpeakers.length}'),
        ],
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Final speaker count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              '${result.totalSpeakers}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisualisationSection(BuildContext context, SurfacePlacementDebugInfo debug) {
    return _DebugCard(
      title: 'Room Visualisation',
      icon: Icons.grid_view_outlined,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: <Widget>[
              _LegendItem(color: Colors.white.withValues(alpha: 0.3), label: 'Room polygon'),
              _LegendItem(color: Colors.greenAccent, label: 'Placed (${result.positions.length})'),
              _LegendItem(color: Colors.orangeAccent.withValues(alpha: 0.7), label: 'Provisional (${debug.provisionalPositions.length})'),
              _LegendItem(color: Colors.redAccent, label: 'Removed (${debug.removedSpeakers.length})'),
            ],
          ),
        ),
        ClipRect(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: CustomPaint(
              painter: _RoomDebugPainter(
                roomCorners: debug.roomCorners,
                placed: result.positions,
                provisional: debug.provisionalPositions,
                removed: debug.removedSpeakers,
                effectiveCoverage: result.effectiveCoverage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemovedSpeakersSection(BuildContext context, SurfacePlacementDebugInfo debug) {
    if (debug.removedSpeakers.isEmpty) {
      return _DebugCard(
        title: 'Removed Speakers',
        icon: Icons.delete_outline,
        children: <Widget>[
          Text(
            'No speakers were removed or merged.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.greenAccent),
          ),
        ],
      );
    }

    return _DebugCard(
      title: 'Removed / Merged Speakers (${debug.removedSpeakers.length})',
      icon: Icons.delete_outline,
      children:
          debug.removedSpeakers.asMap().entries.map((MapEntry<int, RemovedSpeakerInfo> entry) {
            final int idx = entry.key;
            final RemovedSpeakerInfo info = entry.value;
            return _RemovedSpeakerTile(index: idx + 1, info: info);
          }).toList(),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _StepBlock extends StatelessWidget {
  const _StepBlock({
    required this.step,
    required this.title,
    required this.formula,
    required this.substitution,
    required this.resultValue,
    required this.explanation,
  });

  final int step;
  final String title;
  final String formula;
  final String substitution;
  final String resultValue;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orangeAccent.withValues(alpha: 0.04),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header row: step badge + title
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$step', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              // Result badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(resultValue, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Formula
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(formula, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
          const SizedBox(height: 4),
          // Substitution
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(substitution, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: cs.primary.withValues(alpha: 0.85))),
          ),
          const SizedBox(height: 6),
          // Explanation
          Text(explanation, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75))),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RemovedSpeakerTile extends StatelessWidget {
  const _RemovedSpeakerTile({required this.index, required this.info});

  final int index;
  final RemovedSpeakerInfo info;

  Color get _reasonColor {
    switch (info.reason) {
      case SpeakerRemovalReason.cornerCollision:
        return Colors.redAccent;
      case SpeakerRemovalReason.adjacentMerge:
        return Colors.orangeAccent;
      case SpeakerRemovalReason.postMergeCornerCollision:
        return Colors.deepOrangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _reasonColor.withValues(alpha: 0.08),
        border: Border.all(color: _reasonColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: _reasonColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$index', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              const SizedBox(width: 8),
              Text(info.reasonLabel, style: TextStyle(fontWeight: FontWeight.w600, color: _reasonColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          _DebugRow('Position (m)', '(${info.position.dx.toStringAsFixed(3)}, ${info.position.dy.toStringAsFixed(3)})'),
          if (info.nearestCorner != null)
            _DebugRow(
              'Nearest corner',
              '(${info.nearestCorner!.dx.toStringAsFixed(3)}, ${info.nearestCorner!.dy.toStringAsFixed(3)})'
                  ' — ${info.distanceToCorner?.toStringAsFixed(3) ?? '?'} m away',
            ),
          if (info.mergedWithPosition != null)
            _DebugRow(
              'Merged with',
              '(${info.mergedWithPosition!.dx.toStringAsFixed(3)}, ${info.mergedWithPosition!.dy.toStringAsFixed(3)})',
            ),
          if (info.mergedToPosition != null)
            _DebugRow(
              'Merged result at',
              '(${info.mergedToPosition!.dx.toStringAsFixed(3)}, ${info.mergedToPosition!.dy.toStringAsFixed(3)})',
            ),
        ],
      ),
    );
  }
}

// ─── CustomPainter ───────────────────────────────────────────────────────────

class _RoomDebugPainter extends CustomPainter {
  const _RoomDebugPainter({
    required this.roomCorners,
    required this.placed,
    required this.provisional,
    required this.removed,
    required this.effectiveCoverage,
  });

  final List<Offset> roomCorners;
  final List<SpeakerPosition> placed;
  final List<Offset> provisional;
  final List<RemovedSpeakerInfo> removed;

  /// Effective coverage in metres; used to draw coverage-radius circles.
  final double effectiveCoverage;

  @override
  void paint(Canvas canvas, Size size) {
    if (roomCorners.isEmpty) return;

    // Compute bounding box of room corners.
    double minX = roomCorners.first.dx, maxX = roomCorners.first.dx;
    double minY = roomCorners.first.dy, maxY = roomCorners.first.dy;
    for (final Offset c in roomCorners) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }

    const double padding = 24;
    final double scaleX = (size.width - padding * 2) / (maxX - minX == 0 ? 1 : maxX - minX);
    final double scaleY = (size.height - padding * 2) / (maxY - minY == 0 ? 1 : maxY - minY);
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double offsetX = padding + ((size.width - padding * 2) - (maxX - minX) * scale) / 2;
    final double offsetY = padding + ((size.height - padding * 2) - (maxY - minY) * scale) / 2;

    Offset toCanvas(Offset p) => Offset(offsetX + (p.dx - minX) * scale, offsetY + (p.dy - minY) * scale);

    // Draw room polygon.
    final Path roomPath = Path();
    roomPath.moveTo(toCanvas(roomCorners.first).dx, toCanvas(roomCorners.first).dy);
    for (final Offset c in roomCorners.skip(1)) {
      final Offset cp = toCanvas(c);
      roomPath.lineTo(cp.dx, cp.dy);
    }
    roomPath.close();

    canvas.drawPath(
      roomPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      roomPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Corner markers.
    for (final Offset c in roomCorners) {
      canvas.drawCircle(toCanvas(c), 3, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }

    // Effective coverage radius in canvas pixels (coverage is a diameter).
    final double coverageRadiusPx = (effectiveCoverage / 2) * scale;

    // Provisional speakers (small faded orange dot + faded coverage circle).
    final Set<String> placedKeys = placed.map((SpeakerPosition p) => '${p.x.toStringAsFixed(4)},${p.y.toStringAsFixed(4)}').toSet();
    for (final Offset p in provisional) {
      final String key = '${p.dx.toStringAsFixed(4)},${p.dy.toStringAsFixed(4)}';
      // Skip if it ended up as a final placed speaker (we'll draw those distinctly).
      if (placedKeys.contains(key)) continue;
      final Offset cp = toCanvas(p);
      // Coverage circle.
      canvas.drawCircle(
        cp,
        coverageRadiusPx,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.06)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        cp,
        coverageRadiusPx,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      // Speaker dot.
      canvas.drawCircle(cp, 4, Paint()..color = Colors.orangeAccent.withValues(alpha: 0.4));
    }

    // Removed speakers (red X + faint coverage circle).
    final Paint removedPaint =
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    for (final RemovedSpeakerInfo r in removed) {
      final Offset cp = toCanvas(r.position);
      // Coverage circle.
      canvas.drawCircle(
        cp,
        coverageRadiusPx,
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.05)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        cp,
        coverageRadiusPx,
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      // X marker.
      const double s = 5;
      canvas.drawLine(Offset(cp.dx - s, cp.dy - s), Offset(cp.dx + s, cp.dy + s), removedPaint);
      canvas.drawLine(Offset(cp.dx + s, cp.dy - s), Offset(cp.dx - s, cp.dy + s), removedPaint);
    }

    // Placed speakers (coverage circle + filled dot + rotation arrow).
    final Paint placedFill = Paint()..color = Colors.greenAccent;
    for (final SpeakerPosition sp in placed) {
      final Offset cp = toCanvas(Offset(sp.x, sp.y));
      // Coverage circle.
      canvas.drawCircle(
        cp,
        coverageRadiusPx,
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.07)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        cp,
        coverageRadiusPx,
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // Speaker dot.
      canvas.drawCircle(cp, 5, placedFill);
      // Rotation arrow (inward-facing direction).
      final double rad = sp.rotation * (3.14159265 / 180.0);
      const double arrowLen = 10;
      final Offset tip = Offset(cp.dx + arrowLen * cos(rad), cp.dy + arrowLen * sin(rad));
      canvas.drawLine(
        cp,
        tip,
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.9)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoomDebugPainter old) =>
      old.roomCorners != roomCorners ||
      old.placed != placed ||
      old.provisional != provisional ||
      old.removed != removed ||
      old.effectiveCoverage != effectiveCoverage;
}
