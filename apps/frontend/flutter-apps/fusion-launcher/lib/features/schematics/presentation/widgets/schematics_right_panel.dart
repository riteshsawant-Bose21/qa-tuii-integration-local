import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class SchematicsRightPanel extends StatefulWidget {
  final double panelWidth;

  const SchematicsRightPanel({
    super.key,
    required this.panelWidth,
  });

  @override
  State<SchematicsRightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<SchematicsRightPanel> {
  // Sample zone data - can be any length
  final List<Map<String, dynamic>> _zoneData = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Zone 1_Reception',
      'color': Colors.teal[100]!,
    },
    <String, dynamic>{
      'name': 'Zone 2_Cardio',
      'color': Colors.purple[100]!,
    },
    <String, dynamic>{
      'name': 'Zone 3_Weight',
      'color': Colors.amber[100]!,
    },
    <String, dynamic>{
      'name': 'Zone 4_Studio',
      'color': Colors.red[100]!,
    },
    <String, dynamic>{
      'name': 'Zone 5_Yoga',
      'color': Colors.blue[100]!,
    },
    <String, dynamic>{
      'name': 'Zone 6_Pool',
      'color': Colors.green[100]!,
    },
  ];

  // Dynamic zone expansion states based on zone data length
  late Map<int, ValueNotifier<bool>> _zoneExpansionStates;

  @override
  void initState() {
    super.initState();
    // Initialize expansion states dynamically based on zone data length
    _zoneExpansionStates = <int, ValueNotifier<bool>>{};
    for (int i = 0; i < _zoneData.length; i++) {
      _zoneExpansionStates[i] = ValueNotifier<bool>(i == 0); // First zone expanded by default
    }
  }

  @override
  void dispose() {
    // Dispose all ValueNotifiers
    for (final ValueNotifier<bool> notifier in _zoneExpansionStates.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            /// Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: "Zones (${_zoneData.length})",
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLine: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.fusionTextViewColor),
                ],
              ),
            ),

            /// Zones List
            Expanded(
              child: ListView.separated(
                itemCount: _zoneData.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> zone = _zoneData[index];
                  return _buildZoneItem(
                    zone['name'] as String,
                    _zoneExpansionStates[index]!,
                    zone['color'] as Color,
                    constraints.maxWidth,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoneItem(String zoneName, ValueNotifier<bool> isExpanded, Color bgColor, double availableWidth) {
    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (BuildContext context, bool expanded, Widget? child) {
        return Column(
          children: <Widget>[
            /// Zone Header
            InkWell(
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Container(
                color: Colors.grey[100],
                height: 32,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 10,
                      decoration: BoxDecoration(
                        color: bgColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        zoneName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zone Content
            if (expanded) _buildZoneContent(availableWidth),
          ],
        );
      },
    );
  }

  Widget _buildZoneContent(double availableWidth) {
    final double spacing = 0.0;
    final double minSectionWidth = 180.0;
    int sectionsPerRow = 2;

    if (availableWidth < (minSectionWidth * 2 + spacing)) {
      sectionsPerRow = 1;
    }

    double sectionWidth;
    if (sectionsPerRow == 1) {
      sectionWidth = availableWidth;
    } else {
      sectionWidth = (availableWidth - spacing) / 2;
    }

    return Container(
      width: availableWidth,
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.zero,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: sectionWidth,
              child: _buildZoneSection(
                context: context,
                title: "Speakers",
                items: <Widget>[
                  _buildSpeakerItem("DM55E(2)", "4"),
                  _buildSpeakerItem("DM85E", "20"),
                  _buildSpeakerItem("DM55E(1)", "4"),
                ],
              ),
            ),
            SizedBox(
              width: sectionWidth,
              child: _buildZoneSection(
                context: context,
                title: "Controllers",
                items: <Widget>[
                  _buildControllerItem("Control PAL LT(2)"),
                  _buildControllerItem("Control PAL LT(1)"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Common section widget for Speakers/Controllers
  Widget _buildZoneSection({
    required BuildContext context,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.launcherBgColor1,
        border: Border(
          right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLine: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.fusionTextViewColor),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSpeakerItem(String name, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   border: Border.all(color: Colors.grey[300]!),
      //   borderRadius: BorderRadius.circular(4),
      // ),
      child: Row(
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "- $value",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Icon(Icons.add, size: 14, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _buildControllerItem(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.softGray,
      ),
      child: Row(
        children: <Widget>[
          // todo : icon here
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
