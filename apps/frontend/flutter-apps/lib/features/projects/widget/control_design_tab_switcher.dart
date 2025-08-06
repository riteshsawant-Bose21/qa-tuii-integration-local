import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/service_locator.dart';
import 'package:fusion_design_tool_prototype/core/services/project_manager.dart';

class ControlDesignTabSwitcher extends StatefulWidget {
  const ControlDesignTabSwitcher({super.key});

  @override
  ControlDesignTabSwitcherState createState() => ControlDesignTabSwitcherState();
}

class ControlDesignTabSwitcherState extends State<ControlDesignTabSwitcher> {
  int selectedIndex = 0; // Default to Design mode

  @override
  void initState() {
    super.initState();
    selectedIndex = serviceLocator<ProjectManager>().value.isInControlMode ? 1 : 0;
  }


  @override
  void didUpdateWidget(covariant ControlDesignTabSwitcher oldWidget) {
    selectedIndex = serviceLocator<ProjectManager>().value.isInControlMode ? 1 : 0;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Make width responsive to screen size
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabWidth = screenWidth > 600 ? 250 : screenWidth * 0.8;
    final double individualTabWidth = tabWidth / 2;

    return Container(
      width: tabWidth,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: selectedIndex == 0 ? 2 : individualTabWidth,
            top: 2,
            child: Container(
              width: individualTabWidth - 4, // Account for padding on both sides
              height: 31, // Fit within parent container (35 - 4 for top/bottom padding)
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 0;
                      serviceLocator<ProjectManager>().setControlMode(false); // Set to Design mode
                    });
                  },
                  child: SizedBox(
                    height: 35, // Match parent height
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.design_services,
                            size: 18,
                            color: selectedIndex == 0 ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Design',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selectedIndex == 0 ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 1;
                      serviceLocator<ProjectManager>().setControlMode(true); // Set to Control mode
                    });
                  },
                  child: SizedBox(
                    height: 35, // Match parent height
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.tune,
                            size: 18,
                            color: selectedIndex == 1 ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Control',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selectedIndex == 1 ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
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
