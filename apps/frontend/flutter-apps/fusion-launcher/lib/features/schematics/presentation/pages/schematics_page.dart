import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_page.dart';

import '../widgets/schematics_left_panel.dart';
import '../widgets/schematics_right_panel.dart';

class SchematicsPage extends StatefulWidget {
  const SchematicsPage({super.key});

  @override
  State<SchematicsPage> createState() => _SchematicsPageState();
}

class _SchematicsPageState extends State<SchematicsPage> {
  final double minPanelWidth = 300.0;
  final double dividerWidth = 1.0;

  /// Add view state management
  bool isListingView = true; // true for listing view, false for wiring view

  /// Track left panel width as percentage of available space instead of absolute pixels
  double _leftPanelRatio = 0.5; // Default to 50% of available space

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;

        /// Calculate left panel width as percentage of available space
        double leftPanelWidth =
            (availableWidth - dividerWidth) * _leftPanelRatio;

        /// Ensure minimum widths are respected
        leftPanelWidth = leftPanelWidth.clamp(
          minPanelWidth,
          availableWidth - minPanelWidth - dividerWidth,
        );

        /// Recalculate ratio based on clamped width to maintain consistency
        _leftPanelRatio = leftPanelWidth / (availableWidth - dividerWidth);

        final double rightPanelWidth =
            availableWidth - leftPanelWidth - dividerWidth;

        return Column(
          children: <Widget>[
            Expanded(
              child:
                  isListingView
                      ? _buildListingView(
                        availableWidth,
                        leftPanelWidth,
                        rightPanelWidth,
                      )
                      : const WiringPage(),
            ),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                border: Border(
                  top: BorderSide(
                    width: 1,
                    color: Theme.of(context).colorScheme.grey,
                  ),
                ),
              ),

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
                      color:
                          isListingView ? Colors.black87 : Colors.transparent,
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
                      color:
                          !isListingView ? Colors.black87 : Colors.transparent,
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

  Widget _buildListingView(
    double availableWidth,
    double leftPanelWidth,
    double rightPanelWidth,
  ) {
    return Row(
      children: <Widget>[
        /// Left Panel - Sources, Processors, etc.
        SizedBox(
          width: leftPanelWidth,
          height: double.infinity,
          child: Container(
            color: Colors.white,
            child: SchematicsLeftPanel(panelWidth: leftPanelWidth),
          ),
        ),

        /// Resizable Divider
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              setState(() {
                final double newWidth = leftPanelWidth + details.delta.dx;
                final double maxAllowedWidth =
                    availableWidth - minPanelWidth - dividerWidth;

                if (newWidth >= minPanelWidth && newWidth <= maxAllowedWidth) {
                  // Update the ratio instead of absolute width
                  _leftPanelRatio = newWidth / (availableWidth - dividerWidth);
                  _leftPanelRatio = _leftPanelRatio.clamp(
                    0.2,
                    0.8,
                  ); // Keep between 20% and 80%
                }
              });
            },
            child: Container(
              width: 4, // Increased interactive area from 1 to 8 pixels
              height: double.infinity,
              color: Colors.white, // Make the wider area transparent
              child: Center(
                child: Container(
                  width: 1, // Keep the visual line at 1 pixel
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ),

        /// Right Panel - Zones
        Expanded(
          child: Container(
            height: double.infinity,
            color: Colors.white,
            child: SchematicsRightPanel(
              panelWidth: rightPanelWidth,
            ),
          ),
        ),
      ],
    );
  }

  /// Placeholder wiring view
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
