import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/utils/fusion_utils.dart';

class FusionSidebar extends StatefulWidget {
  final ValueNotifier<bool> showAllProjects;
  final ValueChanged<String>? onTabChanged;
  final String? selectedTab;

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
    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.borderColorL,
            width: 0.1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            _buildUserInfoTile(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBox(),
            ),
            const SizedBox(height: 6),
            // Replaced nav items with _HoverNavItem
            _HoverNavItem(
              icon: Icons.home_filled,
              title: 'Home',
              isSelected: widget.selectedTab == 'Home',
              onTap: () => widget.onTabChanged?.call('Home'),
            ),
            _HoverNavItem(
              icon: Icons.person_sharp,
              title: 'Profile',
              isSelected: widget.selectedTab == 'Profile',
              onTap: () => widget.onTabChanged?.call('Profile'),
            ),
            _HoverNavItem(
              icon: Icons.settings_sharp,
              title: 'Settings',
              isSelected: widget.selectedTab == 'Settings',
              onTap: () => widget.onTabChanged?.call('Settings'),
            ),
            _HoverNavItem(
              icon: Icons.public,
              title: 'Community',
              isSelected: widget.selectedTab == 'Community',
              onTap: () => widget.onTabChanged?.call('Community'),
            ),
            // show only in debug mode
            if (kDebugMode)
              _HoverNavItem(
                icon: Icons.library_books_sharp,
                title: 'Test Library',
                isSelected: widget.selectedTab == 'Library',
                onTap: () => Navigator.pushNamed(context, Routes.mylibraryPage),
              ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.borderColorL,
            ),
            GuideShowcaseWrapper(
              step: GuideShowCaseSteps.myProjects,
              onHighlightedSpotTap: (TapDownDetails details) => _showNewProjectDialog(context),
              child: _HoverNavItem(
                icon: Icons.folder_sharp,
                title: 'Add New Project',
                isBold: true,
                trailing: Icons.add_sharp,
                onTap: () => _showNewProjectDialog(context),
              ),
            ),
            const SizedBox(width: 5),
            // _buildProjectList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoTile() {
    return GestureDetector(
      onTap: () => _logoutDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 13, // (28 - 2) / 2 to account for border
              backgroundImage: AssetImage("assets/images/fusion_default_icon.png"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                UserSessionManager.getSignedInUserEmail() ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.borderColorL,
          width: 1,
        ),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 11),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        ),
        style: TextStyle(fontSize: 11),
      ),
    );
  }

  // Widget _buildProjectList() {
  //   return ValueListenableBuilder<List<ProjectListModel>>(
  //     valueListenable: widget.projectListManager,
  //     builder: (BuildContext context, List<ProjectListModel> projects, _) {
  //       return ValueListenableBuilder<bool>(
  //         valueListenable: widget.showAllProjects,
  //         builder: (BuildContext context, bool showAll, __) {
  //           if (projects.isEmpty) {
  //             return _buildNavItem(Icons.folder_outlined, 'No Projects Available', isSubItem: true);
  //           }
  //
  //           final List<ProjectListModel> visibleProjects = showAll ? projects : projects.take(5).toList();
  //
  //           return Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: <Widget>[
  //               ...visibleProjects.map((ProjectListModel project) {
  //                 return MouseRegion(
  //                   cursor: SystemMouseCursors.click,
  //                   child: InkWell(
  //                     onTap: () async {
  //                       FusionUtils.showLoader(context);
  //                       await widget.projectListManager.downloadAndExtractProjectZip(
  //                         fileId: project.metaData.fileId,
  //                         projectName: project.name,
  //                         projectManager: widget.projectManager,
  //                         localUpdatedAt: project.updatedAt,
  //                       );
  //                       if (context.mounted) {
  //                         FusionUtils.hideLoader(context);
  //                         Navigator.pushNamed(context, Routes.projectPage);
  //                       }
  //                     },
  //                     onLongPress: () async {
  //                       await widget.projectListManager.deleteProject(
  //                         folderName: project.name,
  //                         projectId: project.id,
  //                       );
  //                       widget.projectListManager.remove(project.id);
  //                     },
  //                     child: _buildNavItem(Icons.folder_outlined, project.name, isSubItem: true),
  //                   ),
  //                 );
  //               }),
  //               if (projects.length > 5)
  //                 Padding(
  //                   padding: const EdgeInsets.only(left: 32.0, top: 8),
  //                   child: TextButton(
  //                     onPressed: () => widget.showAllProjects.value = !showAll,
  //                     child: Text(showAll ? 'View Less' : 'View All'),
  //                   ),
  //                 ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

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
          title: const Text(
            "Create New Project",
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
                      return TextFormField(
                        controller: projectNameController,
                        autofocus: true,
                        decoration: _buildInputDecoration(
                          context,
                          'Project Name',
                          errorText,
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
                      return TextFormField(
                        controller: venueNameController,
                        decoration: _buildInputDecoration(
                          context,
                          'Venue Name',
                          errorText,
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
                  TextFormField(
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
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
            ElevatedButton(
              onPressed: () async {
                final String projectName = projectNameController.text.trim();
                final String venueName = venueNameController.text.trim();
                final String budget = budgetController.text.trim();

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
          ],
        );
      },
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
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
    return GestureDetector(
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
    );
  }

  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
        activeColor: Colors.blue.shade600,
        checkColor: Colors.white,
      ),
    );
  }

  // NEW: Helper method to wrap _HoverNavItem for project list items.
  Widget _buildNavItem(
    IconData icon,
    String title, {
    bool isSubItem = false,
    bool isBold = false,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    return _HoverNavItem(
      icon: icon,
      title: title,
      isSubItem: isSubItem,
      isBold: isBold,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// New widget for nav items with hover and selected style.
class _HoverNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSubItem;
  final bool isBold;
  final IconData? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool isSelected;

  const _HoverNavItem({
    required this.icon,
    required this.title,
    this.isSubItem = false,
    this.isBold = false,
    this.trailing,
    this.onTap,
    this.textColor,
    this.isSelected = false,
    Key? key,
  }) : super(key: key);

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontSize: 13,
      fontWeight: widget.isBold || widget.isSelected ? FontWeight.bold : FontWeight.normal,
      color: widget.textColor ?? Colors.black87,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: widget.isSelected ? Colors.blue.shade100 : (_isHovered ? Colors.grey.shade200 : Colors.transparent),
          padding: EdgeInsets.only(
            left: widget.isSubItem ? 32 : 16,
            right: 16,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: <Widget>[
              Icon(widget.icon, size: 16, color: widget.textColor ?? Colors.black),
              const SizedBox(width: 16),
              Expanded(
                child: Text(widget.title, style: style, overflow: TextOverflow.ellipsis),
              ),
              if (widget.trailing != null) Icon(widget.trailing, size: 16, color: widget.textColor ?? Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
