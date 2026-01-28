import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ControlDesignTabSwitcher extends StatefulWidget {
  final Function(int) onTabChanged;

  const ControlDesignTabSwitcher({
    super.key,
    required this.onTabChanged,
  });

  @override
  ControlDesignTabSwitcherState createState() => ControlDesignTabSwitcherState();
}

class ControlDesignTabSwitcherState extends State<ControlDesignTabSwitcher> {
  int get selectedIndex => serviceLocator<ProjectViewModel>().isInControlMode ? 1 : 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ControlDesignTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Make width responsive to screen size
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabWidth = screenWidth > 600 ? 64 : 64;
    final double individualTabWidth = tabWidth / 2;

    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return Container(
          width: tabWidth,
          padding: const EdgeInsets.only(top: 6, bottom: 6),

          height: 48,
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            border: Border(
              top: BorderSide(width: 1, color: context.colorScheme.elevation2),
              bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
            ),
          ),
          child: Container(
            width: tabWidth,
            alignment: Alignment.center,
            height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.colorScheme.elevation2),
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: selectedIndex == 0 ? 2 : individualTabWidth,
                  top: 2,
                  child: Container(
                    width: individualTabWidth - 4, // Account for padding on both sides
                    height: 28, // Fit within parent container (35 - 4 for top/bottom padding)
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
                          widget.onTabChanged(0);
                        },
                        child: SizedBox(
                          height: 32, // Match parent height
                          child: Center(
                            child: Icon(
                              Icons.design_services,
                              size: 18,
                              color: selectedIndex == 0 ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.onTabChanged(1);
                        },
                        child: SizedBox(
                          height: 32, // Match parent height
                          child: Center(
                            child: Icon(
                              Icons.tune,
                              size: 18,
                              color: selectedIndex == 1 ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
