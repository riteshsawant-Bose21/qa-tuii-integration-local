import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_lib/constants/test_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/utils/fusion_utils.dart';

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
                              color: FusionDarkColorPallette.dark80,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.bell, size: 16),
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
                    Text(
                      UserSessionManager.getSignedInUserEmail() ?? "",
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
                            const NeumorphicDarkTextField(
                              hintText: 'Search',
                              prefix: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(LucideIcons.search, size: 10),
                              ),
                              borderRadius: 8,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

                      const Divider(height: 0),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _HoverNavItem(
                              icon: Icons.public,
                              title: DashboardTabs.community.name,
                              semanticsId: 'community_tab',
                              isSelected: widget.selectedTab == DashboardTabs.community,
                              onTap: () => widget.onTabChanged?.call(DashboardTabs.community),
                            ),
                            // show only in debug mode
                            if (kDebugMode) ...<Widget>[
                              _HoverNavItem(
                                icon: Icons.library_books_sharp,
                                title: DashboardTabs.testLibrady.name,
                                semanticsId: 'library_tab',
                                isSelected: widget.selectedTab == DashboardTabs.testLibrady,
                                onTap: () => Navigator.pushNamed(context, Routes.mylibraryPage),
                              ),
                            ],
                          ],
                        ),
                      ),

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
          content: const FusionAppText(text: "Are you sure you want to sign out?"),
          actions: <Widget>[
            NeumorphicDarkButton(
              onTap: () async {
                await serviceLocator<AuthViewModel>().logout();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  //   Navigator.pushReplacementNamed(context, '/welcome');
                }
              },
              height: 32,
              borderRadius: 8,
              child: FusionAppText(text: "Sign Out", style: context.textTheme.labelMedium),
            ),
            const SizedBox(height: 5),
            NeumorphicDarkButton(
              onTap: () => Navigator.pop(ctx),
              height: 32,
              borderRadius: 8,
              child: FusionAppText(text: "Cancel", style: context.textTheme.labelMedium),
            ),
          ],
        );
      },
    );
  }

  void _showNewProjectDialog(BuildContext context) {
    final TextEditingController projectNameController = TextEditingController();
    final TextEditingController venueNameController = TextEditingController();
    final TextEditingController budgetController = TextEditingController(text: '100,000');
    final ValueNotifier<String?> projectNameErrorNotifier = ValueNotifier<String?>(null);
    final ValueNotifier<String?> venueNameErrorNotifier = ValueNotifier<String?>(null);
    final ValueNotifier<String?> venueTypeErrorNotifier = ValueNotifier<String?>(null);
    final ValueNotifier<String?> applicationErrorNotifier = ValueNotifier<String?>(null);

    // Venue Type - single selection
    final ValueNotifier<String?> selectedVenueTypeNotifier = ValueNotifier<String?>(null);

    // Application - single selection
    final ValueNotifier<String?> selectedApplicationNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const FusionAppText(
            text: "Create New Project",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Project Name
                  _buildInputLabel("Project Name"),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: projectNameErrorNotifier,
                    builder: (BuildContext context, String? errorText, _) {
                      return SemanticHelper.formControl(
                        testId: SemanticHelper.createTestId(SemanticTypes.textInput, FusionTestKeys.projectNameInput),
                        child: TextFormField(
                          controller: projectNameController,
                          autofocus: true,
                          decoration: _buildInputDecoration(
                            context,
                            'Project Name',
                            errorText,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Venue Name
                  _buildInputLabel("Venue Name"),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: venueNameErrorNotifier,
                    builder: (BuildContext context, String? errorText, _) {
                      return SemanticHelper.formControl(
                        testId: SemanticHelper.createTestId(SemanticTypes.textInput, FusionTestKeys.venueNameInput),
                        child: TextFormField(
                          controller: venueNameController,
                          decoration: _buildInputDecoration(
                            context,
                            'Venue Name',
                            errorText,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Venue Type
                  _buildInputLabel("Venue Type"),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: selectedVenueTypeNotifier,
                    builder: (BuildContext context, String? selectedVenueType, _) {
                      return Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _buildIconTile(
                                  'Indoor',
                                  Icons.home_outlined,
                                  selectedVenueType == 'Indoor',
                                  () {
                                    selectedVenueTypeNotifier.value = selectedVenueType == 'Indoor' ? null : 'Indoor';
                                    venueTypeErrorNotifier.value = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildIconTile(
                                  'Outdoor',
                                  Icons.park_outlined,
                                  selectedVenueType == 'Outdoor',
                                  () {
                                    selectedVenueTypeNotifier.value = selectedVenueType == 'Outdoor' ? null : 'Outdoor';
                                    venueTypeErrorNotifier.value = null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: _buildIconTile(
                                  'Hybrid',
                                  Icons.merge_type_outlined,
                                  selectedVenueType == 'Hybrid',
                                  () {
                                    selectedVenueTypeNotifier.value = selectedVenueType == 'Hybrid' ? null : 'Hybrid';
                                    venueTypeErrorNotifier.value = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: venueTypeErrorNotifier,
                    builder: (BuildContext context, String? errorText, _) {
                      return errorText != null
                          ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorText,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          )
                          : const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Application
                  _buildInputLabel("Application"),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: selectedApplicationNotifier,
                    builder: (BuildContext context, String? selectedApplication, _) {
                      return Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _buildIconTile(
                                  'Restaurant',
                                  Icons.restaurant_outlined,
                                  selectedApplication == 'Restaurant',
                                  () {
                                    selectedApplicationNotifier.value = selectedApplication == 'Restaurant' ? null : 'Restaurant';
                                    applicationErrorNotifier.value = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildIconTile(
                                  'Gym',
                                  Icons.fitness_center_outlined,
                                  selectedApplication == 'Gym',
                                  () {
                                    selectedApplicationNotifier.value = selectedApplication == 'Gym' ? null : 'Gym';
                                    applicationErrorNotifier.value = null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _buildIconTile(
                                  'Shopping Mall',
                                  Icons.shopping_bag_outlined,
                                  selectedApplication == 'Shopping Mall',
                                  () {
                                    selectedApplicationNotifier.value = selectedApplication == 'Shopping Mall' ? null : 'Shopping Mall';
                                    applicationErrorNotifier.value = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildIconTile(
                                  'Super Market',
                                  Icons.store_outlined,
                                  selectedApplication == 'Super Market',
                                  () {
                                    selectedApplicationNotifier.value = selectedApplication == 'Super Market' ? null : 'Super Market';
                                    applicationErrorNotifier.value = null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _buildIconTile(
                                  'Stadium',
                                  Icons.stadium_outlined,
                                  selectedApplication == 'Stadium',
                                  () {
                                    selectedApplicationNotifier.value = selectedApplication == 'Stadium' ? null : 'Stadium';
                                    applicationErrorNotifier.value = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildIconTile(
                                  'Other',
                                  Icons.add_business_rounded,
                                  selectedApplication == 'Other',
                                  () {
                                    selectedApplicationNotifier.value = selectedApplication == 'Other' ? null : 'Other';
                                    applicationErrorNotifier.value = null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: applicationErrorNotifier,
                    builder: (BuildContext context, String? errorText, _) {
                      return errorText != null
                          ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorText,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          )
                          : const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Budget
                  _buildInputLabel("Budget"),
                  const SizedBox(height: 8),
                  SemanticHelper.formControl(
                    testId: SemanticHelper.createTestId(SemanticTypes.textInput, FusionTestKeys.budgetInput),
                    child: TextFormField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        context,
                        'Budget',
                        null,
                      ).copyWith(
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.cancelCreateProjectButton),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Cancel"),
              ),
            ),
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.createProjectButton),
              child: ElevatedButton(
                onPressed: () async {
                  final String projectName = projectNameController.text.trim();
                  final String venueName = venueNameController.text.trim();
                  // final String budget = budgetController.text.trim();

                  // Clear all previous errors
                  projectNameErrorNotifier.value = null;
                  venueNameErrorNotifier.value = null;
                  venueTypeErrorNotifier.value = null;
                  applicationErrorNotifier.value = null;

                  // Validation with field-specific errors
                  bool hasError = false;

                  if (projectName.isEmpty) {
                    projectNameErrorNotifier.value = 'Project name cannot be empty';
                    hasError = true;
                  }

                  if (venueName.isEmpty) {
                    venueNameErrorNotifier.value = 'Venue name cannot be empty';
                    hasError = true;
                  }

                  if (selectedVenueTypeNotifier.value == null) {
                    venueTypeErrorNotifier.value = 'Please select a venue type';
                    hasError = true;
                  }

                  if (selectedApplicationNotifier.value == null) {
                    applicationErrorNotifier.value = 'Please select an application';
                    hasError = true;
                  }

                  if (hasError) {
                    return;
                  }

                  FusionUiUtils.showLoader(context);
                  final NewProjectDetails newProject = NewProjectDetails(name: projectName);
                  final ProjectData? projectData = await serviceLocator<ProjectViewModel>().createAndSaveNewProject(
                    newProject,
                  );
                  if (context.mounted) {
                    FusionUiUtils.hideLoader(context);
                  }

                  serviceLocator<ProjectViewModel>().openProject(projectData!.id);

                  // if (errorMessage != null) {
                  //   projectNameErrorNotifier.value = errorMessage;
                  //   return;
                  // }

                  if (context.mounted) {
                    serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.myProjects);
                    Navigator.of(context).pop();
                    // Navigator.pushNamed(context, Routes.projectPage);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Create"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputLabel(String label) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, label),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hintText, String? errorText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      errorText: errorText,
      errorStyle: TextStyle(
        color: Colors.red.shade600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildIconTile(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return SemanticHelper.formControl(
      testId: SemanticHelper.createTestId(SemanticTypes.toggle, title),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
            border: Border.all(
              color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
              width: isSelected ? 1 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
