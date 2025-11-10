import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/sub_zone_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../core/constants/assets_constants.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class ZoneCard extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final Color bgColor;
  const ZoneCard({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.bgColor,
  });

  @override
  State<ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends State<ZoneCard> {
  late ValueNotifier<bool> _isZoneExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    _isZoneExpanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isZoneExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isZoneExpanded,
      builder: (BuildContext context, bool zoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
            // final bool isSelected = selectedDevice?.id == widget.zoneId && selectedDevice?.type == SelectedItemType.zone;

            return Column(
              children: <Widget>[
                MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true),
                  onExit: (_) => setState(() => isHovered = false),
                  child: _buildZoneHeader(
                    context: context,
                    expanded: zoneExpanded,
                    isHovered: isHovered,
                    isSelected: false,
                  ),
                ),

                /// Zone Content - shows subzones when expanded
                if (zoneExpanded) _buildZoneContent(),
              ],
            );
          },
        );
      },
    );
  }

  /// Zone header - always visible
  Widget _buildZoneHeader({required BuildContext context, required bool expanded, required bool isHovered, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        _isZoneExpanded.value = !_isZoneExpanded.value;

        /// Select zone on tap
        _projectViewModel.setSelectedDevice(widget.zoneId, SelectedItemType.zone);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 14),
        height: 32,
        decoration: BoxDecoration(
          color: isHovered ? widget.bgColor.withAlpha(100) : widget.bgColor.withAlpha(120),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.greyDark : Colors.transparent,
          ),
        ),
        child: Row(
          children: <Widget>[
            /// Expand/collapse icon
            Icon(
              expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
            ),
            const SizedBox(width: 4),

            /// Zone name
            Expanded(
              child: FusionAppText(
                text: widget.zoneName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const FusionImage.asset(
              Assets.processingBlocksFilledWhiteIcon,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// Zone content
  Widget _buildZoneContent() {
    /// Calculate dynamic height based on subzones
    /// Each subzone card is approximately 40-50px, add padding
    final int subZoneCount = _projectViewModel.subZones.length;
    final double calculatedHeight = (subZoneCount * 100.0);

    /// Constrain between min and max heights
    final double constrainedHeight = calculatedHeight.clamp(200.0, 400.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            return SizedBox(
              height: constrainedHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Functions Panel
                  Container(
                    width: constraints.maxWidth * 0.34,
                    height: constrainedHeight,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).colorScheme.grey),
                      ),
                    ),
                    child: _buildZoneFunctionsPanel(),
                  ),

                  /// Full height divider
                  Container(
                    width: 1,
                    height: constrainedHeight,
                    color: Theme.of(context).colorScheme.grey,
                  ),

                  /// Subzone Panel
                  Expanded(
                    child: SizedBox(
                      height: constrainedHeight,
                      child: _buildSubZonePanel(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Zone functions panel
  Widget _buildZoneFunctionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'FUNCTIONS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        /// Add your function buttons here
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FusionAppText(
            text: 'Source-Mix',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  /// Subzone panel
  Widget _buildSubZonePanel() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        print('Building SubZone Panel with ${_projectViewModel.subZones.length} subzones');
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.grey),
            ),
          ),
          child:
              _projectViewModel.subZones.isEmpty
                  ? Center(
                    child: FusionAppText(
                      text: 'No sub zones added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        // color: Theme.of(context).colorScheme.greyDark,
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _projectViewModel.subZones.length,
                      onReorder: (int oldIndex, int newIndex) {},
                      itemBuilder: (BuildContext context, int index) {
                        final SubZone subZoneData = _projectViewModel.subZones[index];
                        return ReorderableDragStartListener(
                          key: ValueKey<String>(subZoneData.id),
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SubZoneCard(
                              subZoneId: subZoneData.id,
                              subZoneName: subZoneData.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        );
      },
    );
  }
}
