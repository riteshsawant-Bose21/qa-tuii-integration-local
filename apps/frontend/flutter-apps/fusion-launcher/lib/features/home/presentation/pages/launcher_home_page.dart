import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/core/widgets/test_library_screen.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../widgets/fusion_side_bar.dart';
import '../widgets/home_tab_content.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/saved_projects_tab.dart';
import '../widgets/settings_tab_content.dart';

enum DashboardTabs {
  home("Home"),
  profile("Profile"),
  settings("Settings"),
  // community("Community"),
  testLibrady("Test Library"),
  savedProjects("Saved Projects");

  final String name;
  const DashboardTabs(this.name);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<DashboardTabs> _currentTabNotifier = ValueNotifier<DashboardTabs>(DashboardTabs.home);

  final ValueNotifier<bool> _showAllProjects = ValueNotifier<bool>(false);
  final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();
  final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  loadProjects() async {
    await serviceLocator<ProjectViewModel>().loadAllLocalProjects();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: context.colorScheme.elevation1,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ==================================
                //          Side bar with Tabs
                // ==================================
                if (isWide) ...<Widget>[
                  ValueListenableBuilder<DashboardTabs>(
                    valueListenable: _currentTabNotifier,
                    builder: (BuildContext context, DashboardTabs selectedTab, Widget? child) {
                      return FusionSidebar(
                        showAllProjects: _showAllProjects,
                        selectedTab: selectedTab, // now reactive
                        onTabChanged: (DashboardTabs tabValue) {
                          _currentTabNotifier.value = tabValue;
                        },
                      );
                    },
                  ),
                ],

                // ==================================
                //          Tab Content
                // ==================================
                Expanded(
                  child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                    listener: (BuildContext context, ProjectViewModelState state) {
                      if (state is ProjectLoaded && context.mounted) {
                        if (state.currentProject != null) {
                          FusionUiUtils.hideLoader(context);
                          Navigator.pushNamed(context, Routes.projectPage).then((_) async {
                            await serviceLocator<ProjectViewModel>().loadAllLocalProjects();
                          });
                        }
                      }
                      if (state is OpenProjectError && context.mounted) {
                        FusionUiUtils.hideLoader(context);
                        FusionToast.show(context, message: state.message);
                      }
                    },
                    builder: (BuildContext context, ProjectViewModelState state) {
                      return ValueListenableBuilder<DashboardTabs>(
                        valueListenable: _currentTabNotifier,
                        builder: (BuildContext context, DashboardTabs currentTab, Widget? child) {
                          switch (currentTab) {
                            case DashboardTabs.home:
                              return const HomeTabContent();
                            case DashboardTabs.profile:
                              return const ProfileTabContent();
                            case DashboardTabs.settings:
                              return const SettingsTabContent();
                            // case DashboardTabs.community:
                            //   return const CommunityTabContent();
                            case DashboardTabs.savedProjects:
                              return const SavedProjectsTabContent();
                            case DashboardTabs.testLibrady:
                              return TestLibraryScreen();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
