import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/constants/assets_constants.dart';

class ListeningAreasPanel extends StatefulWidget {
  const ListeningAreasPanel({super.key});

  @override
  ListeningAreasPanelState createState() => ListeningAreasPanelState();
}

class ListeningAreasPanelState extends State<ListeningAreasPanel> with TickerProviderStateMixin {
  final Set<String> _expandedListeningAreas = <String>{};

  @override
  void initState() {
    super.initState();
    _initializeExpandedStates();
  }

  void _initializeExpandedStates() {
    // Expand all listening areas by default
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getAllListeningAreas();
    for (final ListeningArea area in listeningAreas) {
      _expandedListeningAreas.add(area.id);
    }
  }

  void _toggleListeningAreaExpansion(String listeningAreaId) {
    setState(() {
      if (_expandedListeningAreas.contains(listeningAreaId)) {
        _expandedListeningAreas.remove(listeningAreaId);
      } else {
        _expandedListeningAreas.add(listeningAreaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Listening Areas List
              _buildListeningAreasList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListeningAreasList() {
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getAllListeningAreas();

    if (listeningAreas.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      constraints: const BoxConstraints(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 3),
          ...listeningAreas.map(
            (ListeningArea area) => Container(
              child: _buildListeningAreaCard(area),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.layers_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'No listening areas yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningAreaCard(ListeningArea area) {
    final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId == area.id;
    final bool isExpanded = _expandedListeningAreas.contains(area.id);
    final String floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: area.id)?.name ?? '';

    // Get speakers for this listening area
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id);
    final List<Speaker> speakers = allHardware.whereType<Speaker>().toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Listening Area Header
        Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[200] : Colors.transparent,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(area.id);
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
              },
              child: Row(
                children: <Widget>[
                  // Expand/Collapse icon
                  InkWell(
                    onTap: () => _toggleListeningAreaExpansion(area.id),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.25 : 0.0,
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Listening area icon
                  SvgPicture.asset(
                    Assets.listeningAreaSvg,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Colors.black87,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FusionAppText(
                      text: "$floorName / ${area.name}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expandable Speakers Section
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (speakers.isNotEmpty) ...speakers.map((Speaker speaker) => _buildSpeakerItem(speaker)) else _buildNoSpeakersMessage(),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSpeakerItem(Speaker speaker) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == speaker.id;

        return Container(
          margin: const EdgeInsets.only(left: 24, top: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[200] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () {
              serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(speaker.id);
              serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    speaker.assetImagePath,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FusionAppText(
                      text: speaker.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSpeakersMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FusionAppText(
              text: 'No speakers',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
