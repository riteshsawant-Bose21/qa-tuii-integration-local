import 'dart:math';

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
  SpeakerPlacementAlgorithmResult? algorithmResult;
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
              if (algorithmResult?.surfacePlacementResult != null)
                InkWell(
                  onTap: () {
                    _SurfaceAlgoResult.show(
                      context,
                      result: algorithmResult!.surfacePlacementResult!,
                      coverageAngle: algorithmResult!.coverageAngle,
                      listnersHeight: algorithmResult!.listnersHeight,
                      coveragePreference: algorithmResult!.coveragePreference,
                      width: algorithmResult!.width,
                      length: algorithmResult!.length,
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
                    FusionToast.error(context, message: response.message);
                  } else {
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
    super.key,
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
