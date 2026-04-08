//
// import 'package:fusion_app/features/project/presentation/building/project_work_area_screen.dart';
// import 'package:fusion_app/features/project/presentation/configuration/configuration_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:fusion_app/features/project/widgets/bottom_nav.dart';
// import 'package:fusion_app/features/project/widgets/fab.dart';
//
// enum ProjectTab { building, schematic, cost, configuration }
//
// class ProjectScreen extends StatefulWidget {
//   const ProjectScreen({super.key});
//
//   @override
//   State<ProjectScreen> createState() => _ProjectScreenState();
// }
//
// class _ProjectScreenState extends State<ProjectScreen> {
//   final ValueNotifier<ProjectTab> _selectedTab = ValueNotifier(ProjectTab.building);
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: ValueListenableBuilder<ProjectTab>(
//           valueListenable: _selectedTab,
//           builder: (_, current, __) {
//           return _buildTabContent();
//         }
//       ),
//       bottomNavigationBar: BottomNavigation(selectedTab:_selectedTab),
//       floatingActionButton: const CenterFab(),
//       floatingActionButtonLocation:
//       FloatingActionButtonLocation.centerDocked,
//     );
//   }
//
//   Widget _buildTabContent() {
//     switch (_selectedTab.value) {
//       case ProjectTab.building:
//         return  ProjectWorkArea();
//       case ProjectTab.schematic:
//         return   ProjectWorkArea();
//       case ProjectTab.cost:
//         return   ProjectWorkArea();
//       case ProjectTab.configuration:
//         return  ConfigurationScreen();
//     }
//   }
// }
//
//
//
//
//
