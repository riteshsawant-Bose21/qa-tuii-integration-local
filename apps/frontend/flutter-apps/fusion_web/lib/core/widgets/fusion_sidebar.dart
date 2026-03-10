// // import 'package:flutter/material.dart';
// // import 'package:fusion_lib/fusion_lib.dart';
// // import 'package:fusion_lib/fusion_theme/app_theme.dart';
// // import 'package:fusion_web/core/navigation/app_router.dart';
// // import 'package:fusion_web/core/constants/app_constants.dart';
// // import 'package:fusion_web/core/widgets/viewmodels/sidebar_viewmodel.dart';
// // import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
// // import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
// // import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
// // import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
// // class FusionSidebar extends StatefulWidget {
// //   const FusionSidebar({super.key});

// //   @override
// //   State<FusionSidebar> createState() => _FusionSidebarState();
// // }

// // class _FusionSidebarState extends State<FusionSidebar> {
// //   late SidebarViewModel _viewModel;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializeViewModel();
// //   }

// //   void _initializeViewModel() {
// //     _viewModel = SidebarViewModel();
// //     _viewModel.initialize();
// //   }

// //   @override
// //   void didUpdateWidget(FusionSidebar oldWidget) {
// //     super.didUpdateWidget(oldWidget);
// //     if (widget.selectedTab != oldWidget.selectedTab) {
// //       _viewModel.setSelectedTab(widget.selectedTab);
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _viewModel.dispose();
// //     super.dispose();
// //   }

// //   void _handleLogout() async {
// //     try {
// //       // Initialize Auth0 for logout
// //       final dataSource = Auth0DataSource();
// //       final repository = AuthRepositoryImpl(dataSource: dataSource);
// //       final logoutUseCase = LogoutUseCase(repository);

// //       // Perform logout
// //       await logoutUseCase();

// //       // Navigate to login page
// //       if (mounted) {
// //         Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
// //       }
// //     } catch (e) {
// //       print('Logout error: $e');
// //       // Still navigate to login page even if logout fails
// //       if (mounted) {
// //         Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: AppConstants.sidebarWidth,
// //       height: double.infinity,
// //       decoration: BoxDecoration(color: Theme.of(context).cardColor),
// //       child: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(8.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: <Widget>[
// //               // Bose Professional Logo
// //               Container(
// //                 width: double.infinity,
// //                 padding: const EdgeInsets.all(16),
// //                 child: Center(
// //                   child: Image.asset(
// //                     'assets/images/bose_professional_logo.png',
// //                     height: 32,
// //                     fit: BoxFit.contain,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //               _buildUserSection(context),
// //               const SizedBox(height: 16),
// //               _buildNavigationSection(context),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildUserSection(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       decoration: BoxDecoration(
// //         color: context.colorScheme.primaryContainer.withValues(alpha: 0.1),
// //         borderRadius: BorderRadius.circular(AppConstants.borderRadius),
// //         border: Border.all(
// //           color: context.colorScheme.outline.withValues(alpha: 0.1),
// //         ),
// //       ),
// //       padding: const EdgeInsets.all(AppConstants.padding),
// //       child: ListenableBuilder(
// //         listenable: _viewModel,
// //         builder: (context, child) {
// //           return Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: <Widget>[
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.end,
// //                 children: <Widget>[
// //                   GestureDetector(
// //                     onTap: _viewModel.clearNotifications,
// //                     child: Badge(
// //                       smallSize: 10,
// //                       alignment: Alignment.topRight,
// //                       backgroundColor: Colors.red,
// //                       textColor: Colors.white,
// //                       padding: const EdgeInsets.only(),
// //                       textStyle: const TextStyle(fontSize: 0),
// //                       isLabelVisible: _viewModel.hasNotifications,
// //                       child: Container(
// //                         height: 36,
// //                         width: 36,
// //                         decoration: BoxDecoration(
// //                           color: Colors.white,
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                         child: const Icon(LucideIcons.bell, size: 16),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 10),
// //               Row(
// //                 children: <Widget>[
// //                   Expanded(
// //                     child: FusionAppText(
// //                       text: _viewModel.appName,
// //                       style: context.textTheme.labelMedium?.copyWith(
// //                         color: FusionDarkColorPallette.medium50,
// //                       ),
// //                     ),
// //                   ),
// //                   const Icon(LucideIcons.chevronDown),
// //                   const SizedBox(width: 10),
// //                 ],
// //               ),
// //               const SizedBox(height: 10),
// //               Text(_viewModel.userName, style: context.textTheme.titleMedium),
// //             ],
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildNavigationSection(BuildContext context) {
// //     return Expanded(
// //       child: Container(
// //         width: double.infinity,
// //         decoration: BoxDecoration(
// //           color: context.colorScheme.surface,
// //           borderRadius: BorderRadius.circular(AppConstants.borderRadius),
// //           border: Border.all(
// //             color: context.colorScheme.outline.withValues(alpha: 0.1),
// //           ),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: <Widget>[
// //             Expanded(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(AppConstants.padding),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: <Widget>[
// //                     _buildNavItem(
// //                       context,
// //                       Icons.home_filled,
// //                       "Dashboard", "/dashboard",
// //                     ),
// //                     _buildNavItem(context, Icons.work, DashboardTabs.projects),
// //                     _buildNavItem(
// //                       context,
// //                       Icons.devices,
// //                       DashboardTabs.devices,
// //                     ),
// //                     _buildNavItem(context, Icons.people, DashboardTabs.users),
// //                     _buildNavItem(context, Icons.security, DashboardTabs.roles),
// //                     _buildNavItem(
// //                       context,
// //                       Icons.settings,
// //                       DashboardTabs.settings,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             const Divider(height: 0),
// //             Padding(
// //               padding: const EdgeInsets.all(AppConstants.padding),
// //               child: _HoverNavItem(
// //                 icon: LucideIcons.logOut,
// //                 title: 'Sign Out',
// //                 semanticsId: 'signout_section',
// //                 onTap: _handleLogout,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildNavItem(BuildContext context, IconData icon, DashboardTabs tab) {
// //     return ListenableBuilder(
// //       listenable: _viewModel,
// //       builder: (context, child) {
// //         return _HoverNavItem(
// //           icon: icon,
// //           title: tab.title,
// //           semanticsId: 'test-${tab.name}-tab',
// //           isSelected: _viewModel.selectedTab == tab,
// //           onTap: () {
// //           },
// //         );
// //       },
// //     );
// //   }
// // }

// // class _HoverNavItem extends StatefulWidget {
// //   final IconData icon;
// //   final String title;
// //   final VoidCallback? onTap;

// //   final bool isSelected;
// //   final String semanticsId;

// //   const _HoverNavItem({
// //     required this.icon,
// //     required this.title,
// //     this.onTap,

// //     this.isSelected = false,
// //     required this.semanticsId,
// //   });

// //   @override
// //   State<_HoverNavItem> createState() => _HoverNavItemState();
// // }

// // class _HoverNavItemState extends State<_HoverNavItem> {
// //   bool _isHovered = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     final Color themeColor = context.colorScheme.onSurface;

// //     return MouseRegion(
// //       onEnter: (_) => setState(() => _isHovered = true),
// //       onExit: (_) => setState(() => _isHovered = false),
// //       child: SemanticHelper.container(
// //         testId: SemanticHelper.createTestId(
// //           SemanticTypes.listItem,
// //           widget.semanticsId,
// //         ),
// //         child: InkWell(
// //           onTap: widget.onTap,
// //           borderRadius: BorderRadius.circular(8),
// //           child: Container(
// //             decoration: BoxDecoration(
// //               color: widget.isSelected
// //                   ? themeColor.withValues(alpha: 0.04)
// //                   : (_isHovered
// //                         ? themeColor.withValues(alpha: 0.02)
// //                         : Colors.transparent),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             padding: const EdgeInsets.all(8),
// //             child: Row(
// //               spacing: 10,
// //               children: <Widget>[
// //                 Icon(widget.icon),
// //                 Expanded(
// //                   child: Text(
// //                     widget.title,
// //                     style: context.textTheme.labelMedium,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:fusion_lib/fusion_lib.dart';
// import 'package:fusion_lib/fusion_theme/app_theme.dart';
// import 'package:fusion_web/core/navigation/app_router.dart';
// import 'package:fusion_web/core/constants/app_constants.dart';
// import 'package:fusion_web/core/widgets/viewmodels/sidebar_viewmodel.dart';
// import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
// import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

// class FusionSidebar extends StatefulWidget {
//   final ValueChanged<DashboardTabs>? onTabChanged;
//   final DashboardTabs? selectedTab;

//   const FusionSidebar({super.key, this.onTabChanged, this.selectedTab});

//   @override
//   State<FusionSidebar> createState() => _FusionSidebarState();
// }

// class _FusionSidebarState extends State<FusionSidebar> {
//   late SidebarViewModel _viewModel;

//   @override
//   void initState() {
//     super.initState();
//     _initializeViewModel();
//   }

//   void _initializeViewModel() {
//     _viewModel = SidebarViewModel();
//     _viewModel.setSelectedTab(widget.selectedTab);
//     _viewModel.initialize();
//   }

//   @override
//   void didUpdateWidget(FusionSidebar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.selectedTab != oldWidget.selectedTab) {
//       _viewModel.setSelectedTab(widget.selectedTab);
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void _handleLogout() async {
//     try {
//       // Initialize Auth0 for logout
//       final dataSource = Auth0DataSource();
//       final repository = AuthRepositoryImpl(dataSource: dataSource);
//       final logoutUseCase = LogoutUseCase(repository);

//       // Perform logout
//       await logoutUseCase();

//       // Navigate to login page
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
//       }
//     } catch (e) {
//       print('Logout error: $e');
//       // Still navigate to login page even if logout fails
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: AppConstants.sidebarWidth,
//       height: double.infinity,
//       decoration: BoxDecoration(color: Theme.of(context).cardColor),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               // Bose Professional Logo
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 child: Center(
//                   child: Image.asset(
//                     'assets/images/bose_professional_logo.png',
//                     height: 32,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _buildUserSection(context),
//               const SizedBox(height: 16),
//               _buildNavigationSection(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUserSection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: context.colorScheme.primaryContainer.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(AppConstants.borderRadius),
//         border: Border.all(
//           color: context.colorScheme.outline.withValues(alpha: 0.1),
//         ),
//       ),
//       padding: const EdgeInsets.all(AppConstants.padding),
//       child: ListenableBuilder(
//         listenable: _viewModel,
//         builder: (context, child) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: <Widget>[
//                   GestureDetector(
//                     onTap: _viewModel.clearNotifications,
//                     child: Badge(
//                       smallSize: 10,
//                       alignment: Alignment.topRight,
//                       backgroundColor: Colors.red,
//                       textColor: Colors.white,
//                       padding: const EdgeInsets.only(),
//                       textStyle: const TextStyle(fontSize: 0),
//                       isLabelVisible: _viewModel.hasNotifications,
//                       child: Container(
//                         height: 36,
//                         width: 36,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Icon(LucideIcons.bell, size: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: <Widget>[
//                   Expanded(
//                     child: FusionAppText(
//                       text: _viewModel.appName,
//                       style: context.textTheme.labelMedium?.copyWith(
//                         color: FusionDarkColorPallette.medium50,
//                       ),
//                     ),
//                   ),
//                   const Icon(LucideIcons.chevronDown),
//                   const SizedBox(width: 10),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Text(_viewModel.userName, style: context.textTheme.titleMedium),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildNavigationSection(BuildContext context) {
//     return Expanded(
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: context.colorScheme.surface,
//           borderRadius: BorderRadius.circular(AppConstants.borderRadius),
//           border: Border.all(
//             color: context.colorScheme.outline.withValues(alpha: 0.1),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(AppConstants.padding),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     _buildNavItem(
//                       context,
//                       Icons.home_filled,
//                       DashboardTabs.dashboard,
//                     ),
//                     _buildNavItem(context, Icons.work, DashboardTabs.projects),
//                     _buildNavItem(
//                       context,
//                       Icons.devices,
//                       DashboardTabs.devices,
//                     ),
//                     _buildNavItem(context, Icons.people, DashboardTabs.users),
//                     _buildNavItem(context, Icons.security, DashboardTabs.roles),
//                     _buildNavItem(
//                       context,
//                       Icons.settings,
//                       DashboardTabs.settings,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const Divider(height: 0),
//             Padding(
//               padding: const EdgeInsets.all(AppConstants.padding),
//               child: _HoverNavItem(
//                 icon: LucideIcons.logOut,
//                 title: 'Sign Out',
//                 semanticsId: 'signout_section',
//                 onTap: _handleLogout,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(BuildContext context, IconData icon, DashboardTabs tab) {
//     return ListenableBuilder(
//       listenable: _viewModel,
//       builder: (context, child) {
//         return _HoverNavItem(
//           icon: icon,
//           title: tab.title,
//           semanticsId: 'test-${tab.name}-tab',
//           isSelected: _viewModel.selectedTab == tab,
//           onTap: () {
//             _viewModel.setSelectedTab(tab);
//             if (widget.onTabChanged != null) {
//               widget.onTabChanged!(tab);
//             }
//           },
//         );
//       },
//     );
//   }
// }

// class _HoverNavItem extends StatefulWidget {
//   final IconData icon;
//   final String title;
//   final VoidCallback? onTap;

//   final bool isSelected;
//   final String semanticsId;

//   const _HoverNavItem({
//     required this.icon,
//     required this.title,
//     this.onTap,

//     this.isSelected = false,
//     required this.semanticsId,
//   });

//   @override
//   State<_HoverNavItem> createState() => _HoverNavItemState();
// }

// class _HoverNavItemState extends State<_HoverNavItem> {
//   bool _isHovered = false;

//   @override
//   Widget build(BuildContext context) {
//     final Color themeColor = context.colorScheme.onSurface;

//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: SemanticHelper.container(
//         testId: SemanticHelper.createTestId(
//           SemanticTypes.listItem,
//           widget.semanticsId,
//         ),
//         child: InkWell(
//           onTap: widget.onTap,
//           borderRadius: BorderRadius.circular(8),
//           child: Container(
//             decoration: BoxDecoration(
//               color: widget.isSelected
//                   ? themeColor.withValues(alpha: 0.04)
//                   : (_isHovered
//                         ? themeColor.withValues(alpha: 0.02)
//                         : Colors.transparent),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             padding: const EdgeInsets.all(8),
//             child: Row(
//               spacing: 10,
//               children: <Widget>[
//                 Icon(widget.icon),
//                 Expanded(
//                   child: Text(
//                     widget.title,
//                     style: context.textTheme.labelMedium,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.1),
        ),
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
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.1),
        ),
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

      context.go(AppConstants.loginRoute);
    } catch (e) {
      print('Logout error: $e');
      // Navigate to login even if logout fails
      context.go(AppConstants.loginRoute);
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
