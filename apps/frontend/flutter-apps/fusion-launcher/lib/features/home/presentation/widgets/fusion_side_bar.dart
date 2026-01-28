import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/bug_report_popup.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_launcher/features/home/presentation/pages/launcher_home_page.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/services/user_session_manager.dart';

class FusionSidebar extends StatefulWidget {
  final ValueNotifier<bool> showAllProjects;
  final ValueChanged<DashboardTabs>? onTabChanged;
  final DashboardTabs? selectedTab;

  const FusionSidebar({
    super.key,
    required this.showAllProjects,
    this.onTabChanged,
    this.selectedTab, // added in constructor
  });

  @override
  State<FusionSidebar> createState() => _FusionSidebarState();
}

class _FusionSidebarState extends State<FusionSidebar> {
  String _appVersion = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _initAppVersion();
  }

  Future<void> _initAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}-${packageInfo.buildNumber}';
      });
    } catch (e) {
      // Fallback to default version if package info fails
      setState(() {
        _appVersion = 'v1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ========== Notification Icon ==========
              Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, "dashboard_sidebar_notification_button"),
                          child: Badge(
                            smallSize: 10, // ← tiny dot size
                            alignment: Alignment.topRight,
                            backgroundColor: FusionDarkColorPallette.green20,
                            textColor: FusionDarkColorPallette.green20,
                            padding: const EdgeInsets.only(),
                            textStyle: const TextStyle(fontSize: 0),
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation4,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.bell,
                                size: 16,
                                color: context.colorScheme.primaryWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ========== User Info Tile ==========
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: "Welcome back",
                            style: context.textTheme.labelMedium?.copyWith(
                              color: FusionDarkColorPallette.medium50,
                            ),
                          ),
                        ),

                        const Icon(LucideIcons.chevronDown),
                        const SizedBox(width: 10),
                      ],
                    ),
                    FutureBuilder<UserModel?>(
                      future: UserSessionManager.getSignedInUserProfile(),
                      builder: (BuildContext context, AsyncSnapshot<UserModel?> asyncSnapshot) {
                        if (asyncSnapshot.hasData) {
                          final UserModel user = asyncSnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FusionAppText(
                                text: user.account?.name ?? 'Fusion User',
                                style: context.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLine: 2,
                              ),
                              const SizedBox(height: 8),
                              Tooltip(
                                message: user.user?.email ?? '',
                                child: FusionAppText(
                                  maxLine: 1,
                                  text: user.user?.email ?? '--',
                                  style: context.textTheme.titleSmall,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FusionAppText(
                                text: 'Fusion User',
                                style: context.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLine: 2,
                              ),
                            ],
                          );
                        }

                        // return FusionShimmer(
                        //   baseColor: context.colorScheme.surface.withAlpha(50),
                        //   highlightColor: context.colorScheme.onSurface.withOpacity(0.1),
                        //   height: 25,
                        //   width: double.infinity,
                        //   radius: 8,
                        // );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SemanticHelper.formControl(
                              testId: SemanticHelper.createTestId(SemanticTypes.textInput, "dashboard_sidebar_search_input"),
                              child: const NeumorphicDarkTextField(
                                hintText: 'Search',
                                prefix: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(LucideIcons.search, size: 10),
                                ),
                                borderRadius: 8,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 10),

                            _HoverNavItem(
                              icon: Icons.home_filled,
                              title: DashboardTabs.home.name,
                              semanticsId: 'home_tab',
                              isSelected: widget.selectedTab == DashboardTabs.home,
                              onTap: () => widget.onTabChanged?.call(DashboardTabs.home),
                            ),
                            _HoverNavItem(
                              icon: Icons.account_circle,
                              title: DashboardTabs.profile.name,
                              semanticsId: 'profile_tab',
                              isSelected: widget.selectedTab == DashboardTabs.profile,
                              onTap: () => widget.onTabChanged?.call(DashboardTabs.profile),
                            ),
                            _HoverNavItem(
                              icon: Icons.settings_sharp,
                              title: DashboardTabs.settings.name,
                              semanticsId: 'settings_tab',
                              isSelected: widget.selectedTab == DashboardTabs.settings,
                              onTap: () => widget.onTabChanged?.call(DashboardTabs.settings),
                            ),
                          ],
                        ),
                      ),

                      // const Divider(height: 0),
                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: <Widget>[
                      //       _HoverNavItem(
                      //         icon: Icons.public,
                      //         title: DashboardTabs.community.name,
                      //         semanticsId: 'community_tab',
                      //         isSelected: widget.selectedTab == DashboardTabs.community,
                      //         onTap: () => widget.onTabChanged?.call(DashboardTabs.community),
                      //       ),
                      //       // show only in debug mode
                      //       if (kDebugMode) ...<Widget>[
                      //         _HoverNavItem(
                      //           icon: Icons.library_books_sharp,
                      //           title: DashboardTabs.testLibrady.name,
                      //           semanticsId: 'library_tab',
                      //           isSelected: widget.selectedTab == DashboardTabs.testLibrady,
                      //           onTap: () => Navigator.pushNamed(context, Routes.mylibraryPage),
                      //         ),
                      //       ],
                      //     ],
                      //   ),
                      // ),
                      const Divider(height: 0),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            GuideShowcaseWrapper(
                              step: GuideShowCaseSteps.myProjects,
                              onHighlightedSpotTap: (TapDownDetails details) => CreateNewProjectDialog.show(context),
                              // onHighlightedSpotTap: (TapDownDetails details) => _showNewProjectDialog(context),
                              child: _HoverNavItem(
                                icon: Icons.description,
                                title: 'New Project',
                                semanticsId: 'my_projects_section',
                                trailing: Icons.add_sharp,
                                // onTap: () => _showNewProjectDialog(context),
                                onTap: () => CreateNewProjectDialog.show(context),
                              ),
                            ),
                            _HoverNavItem(
                              icon: Icons.save,
                              title: DashboardTabs.savedProjects.name,
                              isSelected: widget.selectedTab == DashboardTabs.savedProjects,
                              semanticsId: 'saved_projects_section',
                              onTap: () {
                                widget.onTabChanged?.call(DashboardTabs.savedProjects);
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      // Build number text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: Text(
                          'Build- $_appVersion',
                          style: const TextStyle(
                            fontSize: 12,
                            color: FusionDarkColorPallette.medium50,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const Divider(height: 0),

                      // Submit Feedback button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: _HoverNavItem(
                          icon: Icons.feedback_rounded,
                          title: 'Submit Feedback',
                          semanticsId: 'submit_feedback_section',
                          onTap: () => handleExportLogs(context),
                        ),
                      ),

                      const Divider(height: 0),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _HoverNavItem(
                          icon: LucideIcons.logOut,
                          title: 'Sign Out',
                          semanticsId: 'signout_section',
                          onTap: () => _logoutDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // _buildProjectList(),
            ],
          ),
        ),
      ),
    );
  }

  void _logoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: FusionAppText(text: "Sign Out", style: context.textTheme.titleMedium),
          content: const FusionAppText(
            text: "Are you sure you want to sign out? ",
          ),
          actions: <Widget>[
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, "dashboard_sidebar_signout_button"),
              child: NeumorphicDarkButton(
                onTap: () async {
                  await serviceLocator<AuthViewModel>().logout();
                },
                height: 32,
                borderRadius: 8,
                child: FusionAppText(text: "Sign Out", style: context.textTheme.labelMedium),
              ),
            ),
            const SizedBox(height: 5),
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, "dashboard_sidebar_cancel_button"),
              child: NeumorphicDarkButton(
                onTap: () => Navigator.pop(ctx),
                height: 32,
                borderRadius: 8,
                child: FusionAppText(text: "Cancel", style: context.textTheme.labelMedium),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// New widget for nav items with hover and selected style.
class _HoverNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final IconData? trailing;
  final VoidCallback? onTap;

  final bool isSelected;
  final String semanticsId;

  const _HoverNavItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,

    this.isSelected = false,
    required this.semanticsId,
  });

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color themeColor = context.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(SemanticTypes.listItem, widget.semanticsId),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isSelected ? themeColor.withValues(alpha: 0.04) : (_isHovered ? themeColor.withValues(alpha: 0.02) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              spacing: 10,
              children: <Widget>[
                Icon(widget.icon),
                Expanded(
                  child: Text(
                    widget.title,
                    style: context.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trailing != null) Icon(widget.trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
