import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/widgets/viewmodels/sidebar_viewmodel.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FusionSidebar extends StatelessWidget {
  final ValueChanged<DashboardTabs>? onTabChanged;
  final DashboardTabs? selectedTab;

  const FusionSidebar({super.key, this.onTabChanged, this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final vm = SidebarViewModel();
        vm.initialize(selectedTab);
        return vm;
      },
      child: BlocBuilder<SidebarViewModel, BaseState<DashboardTabs?>>(
        builder: (context, state) {
          final viewModel = context.read<SidebarViewModel>();

          return Container(
            width: AppConstants.sidebarWidth,
            height: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// LOGO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Image.asset(
                          'assets/images/bose_professional_logo.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildUserSection(context, viewModel),

                    const SizedBox(height: 16),

                    Expanded(
                      child: _buildNavigationSection(context, viewModel),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===============================
  // USER SECTION
  // ===============================

  Widget _buildUserSection(BuildContext context, SidebarViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      padding: const EdgeInsets.all(AppConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: viewModel.clearNotifications,
                child: Badge(
                  smallSize: 10,
                  alignment: Alignment.topRight,
                  backgroundColor: Colors.red,
                  isLabelVisible: viewModel.hasNotifications,
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
            children: [
              Expanded(
                child: FusionAppText(
                  text: viewModel.appName,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: FusionDarkColorPallette.medium50,
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronDown),
            ],
          ),
          const SizedBox(height: 10),
          Text(viewModel.userName, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }

  // ===============================
  // NAVIGATION SECTION
  // ===============================

  Widget _buildNavigationSection(
    BuildContext context,
    SidebarViewModel viewModel,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(
                    context,
                    viewModel,
                    Icons.home_filled,
                    DashboardTabs.dashboard,
                  ),
                  _buildNavItem(
                    context,
                    viewModel,
                    Icons.work,
                    DashboardTabs.projects,
                  ),
                  _buildNavItem(
                    context,
                    viewModel,
                    Icons.devices,
                    DashboardTabs.devices,
                  ),
                  _buildNavItem(
                    context,
                    viewModel,
                    Icons.people,
                    DashboardTabs.users,
                  ),
                  _buildNavItem(
                    context,
                    viewModel,
                    Icons.business,
                    DashboardTabs.organizations,
                  ),
                  _buildNavItem(
                    context,
                    viewModel,
                    Icons.security,
                    DashboardTabs.roles,
                  ),
                  _buildNavItem(
                    context,
                    viewModel,
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
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    SidebarViewModel viewModel,
    IconData icon,
    DashboardTabs tab,
  ) {
    return _HoverNavItem(
      icon: icon,
      title: tab.title,
      semanticsId: 'test-${tab.name}-tab',
      isSelected: viewModel.selectedTab == tab,
      onTap: () {
        viewModel.setSelectedTab(tab);
        onTabChanged?.call(tab);
      },
    );
  }

  // ===============================
  // LOGOUT
  // ===============================

  void _handleLogout(BuildContext context) async {
    try {
      final dataSource = Auth0DataSource();
      final repository = AuthRepositoryImpl(dataSource: dataSource);
      final logoutUseCase = LogoutUseCase(repository);

      await logoutUseCase();

      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    } catch (_) {
      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    }
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
              children: <Widget>[
                Icon(widget.icon),
                const SizedBox(width: 10),
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
