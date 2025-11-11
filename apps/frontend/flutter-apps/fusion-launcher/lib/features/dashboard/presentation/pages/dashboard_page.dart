import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/home_tab_content.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/utils/bug_report_popup.dart';
import '../widgets/community_tab_content.dart';
import '../widgets/fusion_side_bar.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/settings_tab_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<String> _currentTabNotifier = ValueNotifier<String>('Home');

  final ValueNotifier<bool> _showAllProjects = ValueNotifier<bool>(false);
  final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();
  final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();

  @override
  void initState() {
    super.initState();
    final bool isAdmin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;
    if (!isAdmin) {
      userProfileManager.getUserProfile();
    }
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
          backgroundColor: AppTheme.lightTheme.colorScheme.launcherBgColor1,
          // appbar with title "Fusion Suite"
          appBar: AppBar(
            title: const Text(
              'FUSION SUITE',
              style: TextStyle(
                letterSpacing: 2.4,
                wordSpacing: 3.0,
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.black87,
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.help, color: Colors.white),
                tooltip: 'Guide Help',
                onPressed: () => GuideShowcaseWrapper.askGuideNeededDialog(context),
              ),

              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                tooltip: 'Share Logs',
                onPressed: () {
                  handleExportLogs(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _logoutDialog(context),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // if (isWide) _buildSidebar(),
                if (isWide)
                  ValueListenableBuilder<String>(
                    valueListenable: _currentTabNotifier,
                    builder:
                        (BuildContext context, String selectedTab, _) => FusionSidebar(
                          showAllProjects: _showAllProjects,
                          selectedTab: selectedTab, // now reactive
                          onTabChanged: (String tab) => _currentTabNotifier.value = tab,
                        ),
                  ),
                if (isWide) const VerticalDivider(width: 1, thickness: 0.8, color: Colors.black12),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _currentTabNotifier,
                    builder: (BuildContext context, String currentTab, _) => _buildTabContent(currentTab),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Updated _buildTabContent to accept currentTab parameter.
  Widget _buildTabContent(String currentTab) {
    switch (currentTab) {
      case 'Home':
        return const HomeTabContent();
      case 'Profile':
        return const ProfileTabContent();
      case 'Settings':
        return const SettingsTabContent();
      case 'Community':
        return const CommunityTabContent();
      default:
        return const HomeTabContent();
    }
  }

  /// Shows a dialog to confirm logout
  void _logoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext ctx) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  UserSessionManager.logout();
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }

  /// Shows a context menu for project actions
  void _showContextMenu(
    BuildContext context,
    Offset position,
    String projectId,
  ) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final String? choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            iconColor: Colors.black,
            leading: Icon(Icons.delete_sharp, color: Colors.black),
            title: Text('Delete'),
          ),
        ),
      ],
    );

    switch (choice) {
      // case 'duplicate':
      //   {
      //     final ProjectEntity? project = serviceLocator<ProjectManager>().byId(projectId)?.clone();
      //     if (project != null) {
      //       final String newId = Helper.generateUniqueId();
      //       serviceLocator<ProjectManager>().add(
      //         ProjectEntity(
      //           id: newId,
      //           initialName: '${project.name.value} (Copy)',
      //           initialDevicesConfig: project.productsConfig.value,
      //           initialColors: project.colors.value,
      //           initialSpecs: project.specs.value,
      //           initialDesignLayout: DesignLayoutEntity.initialDesignEntity(),
      //           initialZoneSpecs: <ZoneSpec>[],
      //         ),
      //       );
      //
      //
      //       // if (context.mounted) {
      //       //   Navigator.pushNamed(
      //       //     context,
      //       //     Routes.launcherProjectPage,
      //       //     arguments: newId,
      //       //   );
      //       // }
      //     }
      //   }
      //   break;
      case 'delete':
        {
          // final ProjectListModel? project = projectListManager.byId(projectId);
          // if (project != null) {
          //   await projectListManager.deleteProject(
          //     folderName: project.name,
          //     projectId: project.id,
          //   );
          //   projectListManager.remove(project.id);
          // }
        }
        break;
      default:
        break;
    }
  }
}
