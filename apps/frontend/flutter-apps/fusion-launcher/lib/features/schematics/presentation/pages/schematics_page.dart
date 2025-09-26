import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class SchematicsPage extends StatefulWidget {
  const SchematicsPage({super.key});

  @override
  _SchematicsPageState createState() => _SchematicsPageState();
}

class _SchematicsPageState extends State<SchematicsPage> {
  double? leftPanelWidth; // Make nullable to calculate dynamically
  final double minPanelWidth = 300.0;
  final double dividerWidth = 1.0;

  // Add view state management
  bool isListingView = true; // true for listing view, false for wiring view

  // Zone expansion state
  final ValueNotifier<bool> zone1Expanded = ValueNotifier<bool>(true);
  final ValueNotifier<bool> zone2Expanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> zone3Expanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> zone4Expanded = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        leftPanelWidth ??= ((availableWidth - dividerWidth) / 2).clamp(minPanelWidth, availableWidth - minPanelWidth - dividerWidth);
        final double rightPanelWidth = (availableWidth - leftPanelWidth! - dividerWidth).clamp(minPanelWidth, availableWidth * 0.8);

        return Column(
          children: <Widget>[
            Expanded(
              child: isListingView ? _buildListingView(availableWidth, rightPanelWidth) : _buildWiringView(),
            ),
            Container(
              height: 44,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isListingView = true;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      color: isListingView ? Colors.black87 : Colors.transparent,
                      child: SvgPicture.asset(
                        "assets/svg/listing_view_icon.svg",
                        width: 40,
                        height: 40,
                        colorFilter: ColorFilter.mode(
                          isListingView ? Colors.white : Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isListingView = false;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      color: !isListingView ? Colors.black87 : Colors.transparent,
                      child: SvgPicture.asset(
                        "assets/svg/wiring_view_icon.svg",
                        width: 40,
                        height: 40,
                        colorFilter: ColorFilter.mode(
                          !isListingView ? Colors.white : Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListingView(double availableWidth, double rightPanelWidth) {
    return Row(
      children: <Widget>[
        // Left Panel - Sources, Processors, etc.
        Container(
          width: leftPanelWidth,
          height: double.infinity,
          color: Colors.white,
          child: LeftPanel(panelWidth: leftPanelWidth!),
        ),

        // Resizable Divider
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              final double newWidth = leftPanelWidth! + details.delta.dx;
              final double maxAllowedWidth = availableWidth - minPanelWidth - dividerWidth;
              if (newWidth >= minPanelWidth && newWidth <= maxAllowedWidth) {
                setState(() {
                  leftPanelWidth = newWidth;
                });
              }
            },
            child: Container(
              width: dividerWidth,
              height: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Container(
                  width: 1,
                  height: double.infinity,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ),

        // Right Panel - Zones
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: rightPanelWidth,
              minWidth: minPanelWidth,
            ),
            height: double.infinity,
            color: Colors.white,
            child: RightPanel(
              panelWidth: rightPanelWidth,
              zone1Expanded: zone1Expanded,
              zone2Expanded: zone2Expanded,
              zone3Expanded: zone3Expanded,
              zone4Expanded: zone4Expanded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWiringView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cable,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Wiring View',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeftPanel extends StatefulWidget {
  final double panelWidth;

  const LeftPanel({super.key, required this.panelWidth});

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        final double spacing = 0.0;
        final double usableWidth = availableWidth - (spacing * 2);

        /// Force 2x2 layout (2 columns, 2 rows) by default
        double containerWidth;
        final double minContainerWidth = 180.0;
        int containersPerRow = 2;

        /// Always start with 2 columns

        /// Only allow single column if space is extremely tight
        if (usableWidth < (minContainerWidth * 2 + spacing)) {
          containersPerRow = 1;
        }

        /// Calculate container width based on columns
        if (containersPerRow == 1) {
          containerWidth = usableWidth.clamp(minContainerWidth, double.infinity);
        } else {
          /// For 2 columns, distribute width evenly
          containerWidth = (usableWidth - spacing) / 2;
          containerWidth = containerWidth.clamp(minContainerWidth, double.infinity);
        }

        /// Calculate container height for 2x2 grid (2 rows)
        final int rows = 2; // Force 2 rows for 2x2 layout
        final double totalVerticalSpacing = spacing * (rows + 1); // Top, bottom, and between rows
        final double containerHeight = ((availableHeight - totalVerticalSpacing) / rows).clamp(250.0, double.infinity);

        final List<String> sections = <String>["Sources", "Processors & Amplifiers", "End Points", "Other Devices"];

        return SingleChildScrollView(
          padding: EdgeInsets.all(spacing),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children:
                sections
                    .map((String sectionName) => _buildSection(context: context, title: sectionName, width: containerWidth, height: containerHeight))
                    .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.launcherBgColor1,
        border: Border(
          bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
          right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Header
          Container(
            width: width,
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

          /// Content
          Expanded(
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: _buildSectionContent(title),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(String sectionTitle) {
    switch (sectionTitle) {
      case "Sources":
        return Column(
          children: <Widget>[
            _buildSourceItem("Paging Mic(2)", Icons.mic, false),
            _buildSourceItem("Paging Mic(1)", Icons.mic, false),
            _buildSourceItem("Wire Mic(2)", Icons.mic, true),
            _buildSourceItem("Wire Mic(1)", Icons.mic, true),
            _buildSourceItem("Laptop(2)", Icons.laptop, false),
            _buildSourceItem("Laptop(1)", Icons.laptop, false),
            _buildSourceItem("DVD", Icons.album, false),
          ],
        );

      case "Processors & Amplifiers":
        return Column(
          children: <Widget>[
            _buildProcessorItem("Fusion Mini 6", false),
            const SizedBox(height: 4),
            _buildProcessorItem("PowerSmart PSM-8300 (2)", true, <String>[
              "Z1",
              "Z2",
              "Z3",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "GF",
            ]),
            const SizedBox(height: 4),
            _buildProcessorItem("PowerSmart PSM-8300 (1)", false, <String>["Z1", "Z2", "Z3", "Z4", "GF"]),
          ],
        );

      case "End Points":
        return Column(
          children: <Widget>[
            _buildSourceItem("BluePaL", Icons.bluetooth, false),
            _buildSourceItem("XLRPaL (2)", Icons.cable, false),
            _buildSourceItem("XLRPaL (1)", Icons.cable, false),
          ],
        );

      case "Other Devices":
        return Column(
          children: <Widget>[
            _buildSourceItem("8 Unit Rack", Icons.storage, false),
            _buildSourceItem("Network Switch", Icons.router, false),
          ],
        );

      default:
        return Container();
    }
  }

  Widget _buildSourceItem(String name, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // decoration: BoxDecoration(
      //   color: isActive ? Colors.grey[200] : Colors.white,
      //   border: Border.all(color: Colors.grey[300]!),
      //   borderRadius: BorderRadius.circular(4),
      // ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            // child: Text(
            //   name,
            //   style: TextStyle(fontSize: 11, color: Colors.grey[800]),
            //   overflow: TextOverflow.ellipsis,
            // ),
            child: FusionAppText(
              text: name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessorItem(String name, bool isActive, [List<String>? zones]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // decoration: BoxDecoration(
      //   color: isActive ? Colors.grey[200] : Colors.white,
      //   border: Border.all(color: Colors.grey[300]!),
      //   borderRadius: BorderRadius.circular(4),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FusionAppText(
                  text: name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          if (zones != null) ...<Widget>[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children:
                  zones
                      .map(
                        (String zone) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getZoneColor(zone),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            zone,
                            style: const TextStyle(fontSize: 8, color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'Z1':
        return Colors.teal;
      case 'Z2':
        return Colors.purple;
      case 'Z3':
        return Colors.amber;
      case 'Z4':
        return Colors.red;
      case 'GF':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class RightPanel extends StatefulWidget {
  final double panelWidth;
  final ValueNotifier<bool> zone1Expanded;
  final ValueNotifier<bool> zone2Expanded;
  final ValueNotifier<bool> zone3Expanded;
  final ValueNotifier<bool> zone4Expanded;

  const RightPanel({
    super.key,
    required this.panelWidth,
    required this.zone1Expanded,
    required this.zone2Expanded,
    required this.zone3Expanded,
    required this.zone4Expanded,
  });

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            /// Header
            Container(
              // width: width,
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
                      text: "Zones",
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
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _buildZoneItem("Zone 1_Reception", widget.zone1Expanded, Colors.teal[100]!, constraints.maxWidth),
                    const SizedBox(height: 8),
                    _buildZoneItem("Zone 2_Cardio", widget.zone2Expanded, Colors.purple[100]!, constraints.maxWidth),
                    const SizedBox(height: 8),
                    _buildZoneItem("Zone 3_Weight", widget.zone3Expanded, Colors.amber[100]!, constraints.maxWidth),
                    const SizedBox(height: 8),
                    _buildZoneItem("Zone 4_Studio", widget.zone4Expanded, Colors.red[100]!, constraints.maxWidth),
                  ],
                ),
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
