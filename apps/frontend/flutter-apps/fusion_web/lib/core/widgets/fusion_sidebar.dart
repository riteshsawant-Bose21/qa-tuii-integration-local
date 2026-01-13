import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FusionSidebar extends StatefulWidget {
  final ValueChanged<DashboardTabs>? onTabChanged;
  final DashboardTabs? selectedTab;

  const FusionSidebar({super.key, this.onTabChanged, this.selectedTab});

  @override
  State<FusionSidebar> createState() => _FusionSidebarState();
}

class _FusionSidebarState extends State<FusionSidebar> {
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
              Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
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
                        Badge(
                          smallSize: 10,
                          alignment: Alignment.topRight,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          padding: const EdgeInsets.only(),
                          textStyle: const TextStyle(fontSize: 0),
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.bell, size: 16),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: "Fusion Web",
                            style: context.textTheme.labelMedium?.copyWith(
                              color: FusionDarkColorPallette.medium50,
                            ),
                          ),
                        ),

                        const Icon(LucideIcons.chevronDown),
                        const SizedBox(width: 10),
                      ],
                    ),
                    Text(
                      "Sujith Devadas",
                      style: context.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
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
                            _HoverNavItem(
                              icon: Icons.home_filled,
                              title: DashboardTabs.dashboard.title,
                              semanticsId: 'test-dashboard-tab',
                              isSelected:
                                  widget.selectedTab == DashboardTabs.dashboard,
                              onTap: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(DashboardTabs.dashboard);
                                }
                              },
                            ),
                            _HoverNavItem(
                              icon: Icons.work,
                              title: DashboardTabs.projects.title,
                              semanticsId: 'test-projects-tab',
                              isSelected:
                                  widget.selectedTab == DashboardTabs.projects,
                              onTap: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(DashboardTabs.projects);
                                }
                              },
                            ),
                            _HoverNavItem(
                              icon: Icons.devices,
                              title: DashboardTabs.devices.title,
                              semanticsId: 'test-devices-tab',
                              isSelected:
                                  widget.selectedTab == DashboardTabs.devices,
                              onTap: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(DashboardTabs.devices);
                                }
                              },
                            ),
                            _HoverNavItem(
                              icon: Icons.people,
                              title: DashboardTabs.users.title,
                              semanticsId: 'test-users-tab',
                              isSelected:
                                  widget.selectedTab == DashboardTabs.users,
                              onTap: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(DashboardTabs.users);
                                }
                              },
                            ),
                            _HoverNavItem(
                              icon: Icons.settings,
                              title: DashboardTabs.settings.title,
                              semanticsId: 'test-settings-tab',
                              isSelected:
                                  widget.selectedTab == DashboardTabs.settings,
                              onTap: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(DashboardTabs.settings);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const Divider(height: 0),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _HoverNavItem(
                          icon: LucideIcons.logOut,
                          title: 'Sign Out',
                          semanticsId: 'signout_section',
                          onTap: () => {/* Handle sign out action */},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        testId: SemanticHelper.createTestId(
          SemanticTypes.listItem,
          widget.semanticsId,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? themeColor.withValues(alpha: 0.04)
                  : (_isHovered
                        ? themeColor.withValues(alpha: 0.02)
                        : Colors.transparent),
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
