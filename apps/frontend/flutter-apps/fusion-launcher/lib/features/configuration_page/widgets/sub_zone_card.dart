import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../core/constants/assets_constants.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart' show SelectedItem, SelectedItemType;
import '../viewModel/zones_viewmodel/config_zones_state.dart';
import '../viewModel/zones_viewmodel/config_zones_viewmodel.dart';
import '../../processing_block/view/processing_chain_view.dart';

class SubZoneCard extends StatefulWidget {
  final String subZoneId;
  final String subZoneName;
  final SubZone subZoneData;
  final Function(bool)? onExpansionChanged;

  const SubZoneCard({
    super.key,
    required this.subZoneId,
    required this.subZoneName,
    required this.subZoneData,
    this.onExpansionChanged,
  });

  @override
  State<SubZoneCard> createState() => _SubZoneCardState();
}

class _SubZoneCardState extends State<SubZoneCard> {
  late ValueNotifier<bool> _isSubZoneExpanded;
  ConfigZonesViewmodel get _zonesViewmodel => context.read<ConfigZonesViewmodel>();
  bool _isSubZoneHovered = false;
  int? _hoveredCircuitIndex;

  @override
  void initState() {
    super.initState();
    _isSubZoneExpanded = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _isSubZoneExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: AlignmentGeometry.topCenter,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isSubZoneExpanded,
        builder: (BuildContext context, bool subZoneExpanded, Widget? child) {
          return BlocBuilder<ConfigZonesViewmodel, ConfigZonesState>(
            builder: (BuildContext context, ConfigZonesState state) {
              final SelectedItem? selectedDevice = _zonesViewmodel.selectedDevice;
              final bool isSelected = selectedDevice?.id == widget.subZoneId && selectedDevice?.type == SelectedItemType.subzone;

              return Column(
                children: <Widget>[
                  MouseRegion(
                    onEnter: (_) => setState(() => _isSubZoneHovered = true),
                    onExit: (_) => setState(() => _isSubZoneHovered = false),
                    child: _buildSubZoneHeader(
                      context: context,
                      expanded: subZoneExpanded,
                      isHovered: _isSubZoneHovered,
                      isSelected: isSelected,
                    ),
                  ),

                  /// Sub Zone Content - shows circuits when expanded
                  if (subZoneExpanded) _buildSubZoneContent(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Zone header - always visible
  Widget _buildSubZoneHeader({required BuildContext context, required bool expanded, required bool isHovered, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        final bool newExpandedState = !_isSubZoneExpanded.value;
        _isSubZoneExpanded.value = newExpandedState;

        /// Trigger the expansion callback
        widget.onExpansionChanged?.call(newExpandedState);

        // /// Select subzone on tap
        // _projectViewModel.setSelectedDevice(widget.subZoneId, SelectedItemType.subzone);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
        padding: const EdgeInsets.only(left: 12, right: 13),
        height: 32,
        decoration: BoxDecoration(
          color: isHovered ? context.colorScheme.elevation3 : context.colorScheme.elevation2,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: <Widget>[
            /// Expand/collapse icon
            Icon(expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.primaryWhite),
            const SizedBox(width: 6),

            /// Sub Zone icon
            const FusionImage.asset(
              Assets.subZoneIcon,
              width: 10,
              height: 10,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),

            /// Sub Zone name
            Expanded(
              child: FusionAppText(
                text: widget.subZoneName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            InkWell(
              onTap: () {
                ProcessingChainView.showForSubzone(context, widget.subZoneData);
              },
              child: FusionImage.asset(
                Assets.processingBlocksFilledIcon,
                width: 24,
                height: 24,
                assetColor: context.colorScheme.primaryWhite,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty circuits placeholder (ensures visible height)
  Widget _buildEmptyCircuitsPlaceholder() {
    return SizedBox(
      height: 60,
      child: Center(
        child: FusionAppText(
          text: 'No circuits added yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Subzone content - shows circuits/devices
  Widget _buildSubZoneContent() {
    return BlocBuilder<ConfigZonesViewmodel, ConfigZonesState>(
      builder: (BuildContext context, ConfigZonesState state) {
        final List<CircuitModel> circuitList = _zonesViewmodel.getCircuitsInSubZone(subZoneId: widget.subZoneId);
        return Container(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 400),
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          margin: const EdgeInsets.only(left: 12, right: 12),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2.withAlpha(100),
          ),
          child:
              circuitList.isEmpty
                  ? _buildEmptyCircuitsPlaceholder()
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: circuitList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CircuitModel circuitData = circuitList[index];
                      final List<Speaker> speakersList = _zonesViewmodel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredCircuitIndex = index),
                        onExit: (_) => setState(() => _hoveredCircuitIndex = null),
                        child: _buildCircuitCard(
                          index: index,
                          circuitData: circuitData,
                          speakersList: speakersList,
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }

  /// Build individual circuit card to avoid recursion
  Widget _buildCircuitCard({required int index, required CircuitModel circuitData, required List<Speaker> speakersList}) {
    final bool isThisCircuitHovered = _hoveredCircuitIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: isThisCircuitHovered ? context.colorScheme.elevation2 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 10, right: 10),
      child: Row(
        children: <Widget>[
          FusionImage.asset(
            speakersList.isNotEmpty ? speakersList.first.assetImagePath : "",
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FusionAppText(
              text: circuitData.name,
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
          InkWell(
            onTap: () {
              ProcessingChainView.showForCircuit(context, circuitData);
            },
            child: FusionImage.asset(
              Assets.processingBlocksFilledIcon,
              width: 24,
              height: 24,
              assetColor: context.colorScheme.primaryWhite,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
