import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/processing_block_model.dart';
import 'package:fusion_lib/models/project_entities/project_data.dart';
import 'package:fusion_lib/models/project_entities/zone_model.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class Properties extends StatefulWidget {
  const Properties({super.key});

  @override
  State<Properties> createState() => _PropertiesState();
}

class _PropertiesState extends State<Properties> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  /// Dummy zones data
  final List<Zone> _dummyZones = <Zone>[
    Zone(
      id: 'zone_001',
      name: 'Main Hall',
      listeningAreaIds: <String>['listening_area_001', 'listening_area_002'],
      processingBlocks: <ProcessingBlockModel>[],
      sourceSetIds: <String>['source_set_001'],
      zoneColor: '#2196F3',
      selectedMixIndex: 0,
    ),
    Zone(
      id: 'zone_002',
      name: 'Conference Room A',
      listeningAreaIds: <String>['listening_area_003'],
      processingBlocks: <ProcessingBlockModel>[],
      sourceSetIds: <String>['source_set_002'],
      zoneColor: '#4CAF50',
      selectedMixIndex: 0,
    ),
    Zone(
      id: 'zone_003',
      name: 'Lobby Area',
      listeningAreaIds: <String>['listening_area_004', 'listening_area_005'],
      processingBlocks: <ProcessingBlockModel>[],
      sourceSetIds: <String>['source_set_003'],
      zoneColor: '#FF9800',
      selectedMixIndex: 0,
    ),
    Zone(
      id: 'zone_004',
      name: 'Outdoor Patio',
      listeningAreaIds: <String>['listening_area_006'],
      processingBlocks: <ProcessingBlockModel>[],
      sourceSetIds: <String>['source_set_004'],
      zoneColor: '#9C27B0',
      selectedMixIndex: 0,
    ),
  ];

  /// Add state for dropdown selections
  final Map<String, String> _selectedValues = <String, String>{
    'Zone': 'Main Hall',
    'Type': 'Default Type',
    'Listening Height': 'Standing (5 ft)',
    'SPL Range': 'Background Music',
    'Ceiling Height': 'Standing (10 ft)',
  };

  /// Define dropdown options for each property
  Map<String, List<String>> get _dropdownOptions => <String, List<String>>{
    'Zone': _dummyZones.map((Zone zone) => zone.name).toList(),
    'Type': <String>['Default Type', 'Indoor', 'Outdoor', 'Mixed'],
    'Listening Height': <String>['Standing (5 ft)', 'Seated (3 ft)', 'Standing (6 ft)', 'Mixed Height'],
    'SPL Range': <String>['Background Music', 'Foreground Music', 'Speech', 'High SPL'],
    'Ceiling Height': <String>['Standing (10 ft)', 'Low (8 ft)', 'Medium (12 ft)', 'High (15+ ft)'],
  };

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: 1.0);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Handles expansion state changes and triggers icon rotation animation.
  ///
  /// Called by the [ExpansionTile] when the user taps to expand or collapse.
  /// Animates the trailing icon to provide visual feedback.
  ///
  /// [expanded] - `true` if the tile is being expanded, `false` if collapsing.
  void _handleExpansionChanged(bool expanded) {
    if (expanded) {
      _rotationController.forward();
    } else {
      _rotationController.reverse();
    }
  }

  final List<PropertyRow> rows = <PropertyRow>[
    PropertyRow(title: "P1", x: 12, y: 23, z: 35),
    PropertyRow(title: "P2", x: 12, y: 23, z: 35),
    PropertyRow(title: "P3", x: 12, y: 23, z: 35),
    PropertyRow(title: "P4", x: 12, y: 23, z: 35),
    PropertyRow(title: "P5", x: 10, y: 20, z: 30),
  ];

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final List<Zone> zones = projectViewModel.zones.isNotEmpty ? projectViewModel.zones : _dummyZones;
    final List<ProjectData> projects = projectViewModel.allProjects;

    return Container(
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Column(
        children: <Widget>[
          /// Component Sections
          _buildZoneSection(
            context: context,
            title: zones.first.name,
            zone: zones,
            venueType: projects.isNotEmpty ? projects.first.name : 'Default Project',
            listeningHeight: "Standing (5 ft)",
            splRange: "Background Music",
            ceilingHeight: "Standing (10 ft)",
          ),
        ],
      ),
    );
  }

  /// Builds an expandable section for a specific zone with its properties.
  Widget _buildZoneSection({
    required BuildContext context,
    required String title,
    required List<Zone> zone,
    required String venueType,
    required String listeningHeight,
    required String splRange,
    required String ceilingHeight,
  }) {
    return ExpansionTile(
      childrenPadding: EdgeInsets.zero,
      minTileHeight: 0,
      collapsedBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      collapsedIconColor: Theme.of(context).colorScheme.fusionButtonTextColor,
      iconColor: Theme.of(context).colorScheme.fusionButtonTextColor,
      onExpansionChanged: _handleExpansionChanged,
      tilePadding: EdgeInsets.zero,
      showTrailingIcon: false,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _RotatingIcon(animation: _rotationAnimation, color: Theme.of(context).colorScheme.fusionButtonColor),
            const SizedBox(
              width: 4,
            ),
            FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      // add lock icon for trailing
      trailing: Icon(
        Icons.lock,
        size: 16,
        color: Theme.of(context).colorScheme.fusionButtonTextColor,
      ),
      children: <Widget>[
        _buildZonePropertyRow(
          context: context,
          label: "Zone",
          value: venueType,
        ),
        const SizedBox(
          height: 8,
        ),
        _buildZonePropertyRow(
          context: context,
          label: "Type",
          value: venueType,
        ),
        const SizedBox(
          height: 8,
        ),
        _buildZonePropertyRow(
          context: context,
          label: "Listening Ht",
          value: listeningHeight,
        ),
        const SizedBox(
          height: 8,
        ),
        _buildZonePropertyRow(
          context: context,
          label: "SPL Range",
          value: splRange,
        ),
        const SizedBox(
          height: 8,
        ),
        _buildZonePropertyRow(
          context: context,
          label: "Ceiling Ht",
          value: ceilingHeight,
        ),
        const SizedBox(
          height: 8,
        ),

        PropertyListWidget(
          rows: rows,
        ),
      ],
    );
  }

  /// Builds a dropdown row displaying a property label and its selectable value.
  Widget _buildZonePropertyRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final List<String>? options = _dropdownOptions[label];

    return PopupMenuButton<String>(
      onSelected: (String newValue) {
        setState(() {
          _selectedValues[label] = newValue;
        });
      },
      constraints: const BoxConstraints(maxHeight: 600, minWidth: 200),
      padding: EdgeInsets.zero,
      offset: const Offset(50, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
      ),
      color: Theme.of(context).colorScheme.white,
      elevation: 1,
      itemBuilder: (BuildContext context) {
        if (options == null || options.isEmpty) {
          return <PopupMenuEntry<String>>[];
        }

        return options.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: FusionAppText(
              text: option,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left: Label
            FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
              ),
            ),
            // Right: Value + Arrow
            Container(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: <Widget>[
                  FusionAppText(
                    text: _selectedValues[label] ?? value,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.fusionTextViewColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rotating icon widget that animates based on expansion state.
///
/// Displays a downward-pointing arrow icon that rotates 180 degrees during
/// the expand/collapse animation to provide visual feedback to users.
/// The icon points down when collapsed and up when expanded.
class _RotatingIcon extends StatelessWidget {
  const _RotatingIcon({required this.animation, required this.color});

  /// The animation that drives the rotation transformation.
  ///
  /// Should be a value between 0.0 (no rotation) and 0.5 (180 degrees).
  final Animation<double> animation;

  /// The color to apply to the icon.
  ///
  /// Should match the theme's text color for consistency.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder:
          (BuildContext context, Widget? child) => RotationTransition(
            turns: animation,
            child: Icon(Icons.keyboard_arrow_down, size: 16, color: color),
          ),
    );
  }
}

class PropertyRow {
  final String title;
  final int x;
  final int y;
  final int z;

  PropertyRow({
    required this.title,
    required this.x,
    required this.y,
    required this.z,
  });
}

class PropertyListWidget extends StatefulWidget {
  final List<PropertyRow> rows;

  const PropertyListWidget({super.key, required this.rows});

  @override
  State<PropertyListWidget> createState() => _PropertyListWidgetState();
}

class _PropertyListWidgetState extends State<PropertyListWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final List<PropertyRow> visibleRows = _showAll ? widget.rows : widget.rows.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Table-style layout ensures alignment
        Column(
          children: visibleRows.map((PropertyRow row) => _PropertyRowWidget(row: row)).toList(),
        ),

        // Show more / less button if more than 4 rows
        if (widget.rows.length > 4)
          GestureDetector(
            onTap: () {
              setState(() => _showAll = !_showAll);
            },
            child: Text(_showAll ? "Show Less" : "Show More"),
          ),
      ],
    );
  }
}

class _PropertyRowWidget extends StatelessWidget {
  final PropertyRow row;

  const _PropertyRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyleGrey = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );
    final TextStyle? textStyleBlack = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: <Widget>[
          // Title
          Expanded(
            flex: 2,
            child: Text(row.title, style: textStyleGrey),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Text("X", style: textStyleGrey),
                const SizedBox(width: 4),
                Text("${row.x}", style: textStyleBlack),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Text("Y", style: textStyleGrey),
                const SizedBox(width: 4),
                Text("${row.y}", style: textStyleBlack),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Text("Z", style: textStyleGrey),
                const SizedBox(width: 4),
                Text("${row.z}", style: textStyleBlack),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
