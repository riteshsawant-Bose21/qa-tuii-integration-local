import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/widgets/viewmodels/sidebar_viewmodel.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FusionSidebar extends StatefulWidget {
  final ValueChanged<DashboardTabs>? onTabChanged;
  final DashboardTabs? selectedTab;

  const FusionSidebar({super.key, this.onTabChanged, this.selectedTab});

  @override
  State<FusionSidebar> createState() => _FusionSidebarState();
}

class _FusionSidebarState extends State<FusionSidebar> {
  late SidebarViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
  }

  void _initializeViewModel() {
    _viewModel = SidebarViewModel();
    _viewModel.setSelectedTab(widget.selectedTab);
    _viewModel.initialize();
  }

  @override
  void didUpdateWidget(FusionSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != oldWidget.selectedTab) {
      _viewModel.setSelectedTab(widget.selectedTab);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildUserSection(context),
              const SizedBox(height: 16),
              _buildNavigationSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.padding),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    onTap: _viewModel.clearNotifications,
                    child: Badge(
                      smallSize: 10,
                      alignment: Alignment.topRight,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      padding: const EdgeInsets.only(),
                      textStyle: const TextStyle(fontSize: 0),
                      isLabelVisible: _viewModel.hasNotifications,
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
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: _viewModel.appName,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: FusionDarkColorPallette.medium50,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.chevronDown),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 10),
              Text(_viewModel.userName, style: context.textTheme.titleMedium),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: context.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildNavItem(
                      context,
                      Icons.home_filled,
                      DashboardTabs.dashboard,
                    ),
                    _buildNavItem(context, Icons.work, DashboardTabs.projects),
                    _buildNavItem(
                      context,
                      Icons.devices,
                      DashboardTabs.devices,
                    ),
                    _buildNavItem(context, Icons.people, DashboardTabs.users),
                    _buildNavItem(context, Icons.security, DashboardTabs.roles),
                    _buildNavItem(
                      context,
                      Icons.settings,
                      DashboardTabs.settings,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: _HoverNavItem(
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                semanticsId: 'signout_section',
                onTap: _viewModel.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, DashboardTabs tab) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return _HoverNavItem(
          icon: icon,
          title: tab.title,
          semanticsId: 'test-${tab.name}-tab',
          isSelected: _viewModel.selectedTab == tab,
          onTap: () {
            _viewModel.setSelectedTab(tab);
            if (widget.onTabChanged != null) {
              widget.onTabChanged!(tab);
            }
          },
        );
      },
    );
  }
}

class _HoverNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  final bool isSelected;
  final String semanticsId;

  const _HoverNavItem({
    required this.icon,
    required this.title,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
