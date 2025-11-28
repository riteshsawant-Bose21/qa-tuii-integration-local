import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/project_card.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/pages/launcher_sign_in_page.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/utils/fusion_utils.dart';

Border _getBorder(BuildContext context) => Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), width: 0.3);

enum _SavedProjectsSortOption {
  name("Name");

  final String title;
  const _SavedProjectsSortOption(this.title);
}

class SavedProjectsTabContent extends StatelessWidget {
  const SavedProjectsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8).copyWith(left: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            spacing: 10,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Container(
                  height: 80,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: _getBorder(context),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Create a New Blank Project',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: NeumorphicDarkButton(
                          onTap: () {
                            CreateNewProjectDialog.show(context);
                          },
                          height: 50,
                          width: 50,
                          borderRadius: 10,
                          child: FittedBox(
                            child: Icon(
                              LucideIcons.plus100,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 80,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: _getBorder(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FusionAppText(
                        text: 'Templates',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Flexible(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: FusionAppText(
                                text: 'Start working from a prebuilt template.',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: NeumorphicDarkButton(
                                onTap: () {
                                  // Navigator.pushNamed(context, Routes.projectPage);
                                },
                                height: 26,
                                width: 38,
                                borderRadius: 10,
                                child: FittedBox(
                                  child: Icon(
                                    LucideIcons.arrowRight,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ==============================
          //   Saved Projects
          // ==============================
          const Expanded(child: _SavedProjectList()),
        ],
      ),
    );
  }
}

class _SavedProjectList extends StatefulWidget {
  const _SavedProjectList();

  @override
  State<_SavedProjectList> createState() => _SavedProjectListState();
}

// ignore: constant_identifier_names
const int MIN_SEARCH_LENGTH = 1;

class _SavedProjectListState extends State<_SavedProjectList> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  ValueNotifier<bool> showSearchBarNotifier = ValueNotifier<bool>(false);

  _SavedProjectsSortOption? selectedSortOption;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_listenToSearchChanges);
  }

  @override
  void dispose() {
    _searchController.removeListener(_listenToSearchChanges);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _listenToSearchChanges() {
    final String query = _searchController.text.trim();
    setState(() => _isSearching = query.isNotEmpty && query.length >= MIN_SEARCH_LENGTH);
  }

  List<ProjectData> get getProjects {
    late List<ProjectData> projects;

    final List<ProjectData> allProjects = serviceLocator<ProjectViewModel>().allProjects;

    // ================ SEARCH PROJECTS IF QUERY IS NOT EMPTY ==========================
    final String searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty && searchQuery.length >= MIN_SEARCH_LENGTH) {
      final List<ProjectData> allProjects = serviceLocator<ProjectViewModel>().allProjects;
      projects = allProjects.where((ProjectData project) => project.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    } else {
      // ======= SHOW ALL PROJECTS IF QUERY IS EMPTY ==========
      projects = allProjects;
    }

    // ======= SORT LOGIN AT THE END =======
    if (selectedSortOption == _SavedProjectsSortOption.name) {
      projects.sort((ProjectData a, ProjectData b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return projects;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        if (state is ProjectLoaded && context.mounted) {
          if (state.currentProject != null) {
            FusionUiUtils.hideLoader(context);
            Navigator.pushNamed(
              context,
              Routes.projectPage,
            ).then((_) async {
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
        final List<ProjectData> projects = getProjects;

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: _getBorder(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                    child: Row(
                      spacing: 10,
                      children: <Widget>[
                        /// Recent Projects
                        Expanded(
                          child: FusionAppText(
                            text: 'Projects',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: showSearchBarNotifier,
                          builder: (BuildContext context, bool showSearchBar, Widget? child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: showSearchBar ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Row(
                                children: <Widget>[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: showSearchBar ? 250 : 0,
                                    child: TextFormField(
                                      focusNode: _searchFocusNode,
                                      controller: _searchController,
                                      style: Theme.of(context).textTheme.labelLarge,
                                      cursorColor: Theme.of(context).colorScheme.onSurface,
                                      cursorWidth: 1,
                                      cursorHeight: 15,
                                      decoration: InputDecoration(
                                        filled: true,
                                        isDense: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        hintText: "Search projects",
                                        hoverColor: Colors.transparent,
                                        contentPadding: EdgeInsets.zero,
                                        hintStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      showSearchBarNotifier.value = !showSearchBarNotifier.value;

                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        showSearchBar ? _searchFocusNode.unfocus() : _searchFocusNode.requestFocus();
                                        _searchController.clear();
                                      });
                                    },
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        key: ValueKey<bool>(showSearchBar),
                                        showSearchBar ? LucideIcons.x : LucideIcons.search,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // ==============================
                        //   Sort by Widget
                        // ==============================
                        _SortByWidget(
                          selectedSortOption: selectedSortOption,
                          onSelect: (_SavedProjectsSortOption value) {
                            setState(() {
                              selectedSortOption = value == selectedSortOption ? null : value;
                            });
                          },
                        ),

                        // ==============================
                        //   Filter by Widget
                        // ==============================
                        const _FilterByWidget(), // TODO: Implement filter functionality
                      ],
                    ),
                  ),

                  Expanded(
                    child: Builder(
                      builder: (BuildContext context) {
                        if (_isSearching && projects.isEmpty) {
                          return Center(
                            child: FusionAppText(
                              text: "No Projects Found for \"${_searchController.text}\"",
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        } else if (state is! ProjectLoading && !serviceLocator<ProjectViewModel>().hasProjects) {
                          return Center(
                            child: FusionAppText(
                              text: "No Projects Saved Yet",
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        } else {
                          int crossAxisCount = constraints.maxWidth > 900 ? 4 : 3;
                          if (constraints.maxWidth > 1200) crossAxisCount = 5;

                          return GridView.builder(
                            itemCount: projects.length,
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 16 / 12,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final ProjectData project = projects[index];

                              return GestureDetector(
                                onTap: () => ProjectDetailsDialog.show(context, project: project),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: _getBorder(context),
                                  ),
                                  child: ProjectCard(
                                    title: project.projectName,
                                    onDelete: () => serviceLocator<ProjectViewModel>().deleteProjectFromLocal(project.id),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SortByWidget extends StatelessWidget {
  final _SavedProjectsSortOption? selectedSortOption;
  final ValueChanged<_SavedProjectsSortOption>? onSelect;
  const _SortByWidget({required this.selectedSortOption, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFFF5F5F5),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        splashColor: Colors.transparent, // Disable ripple
        highlightColor: Colors.transparent, // Disable tap highlight
        hoverColor: Colors.transparent, // Disable hover color
      ),
      child: PopupMenuButton<String>(
        color: Theme.of(context).colorScheme.surface,
        shadowColor: Colors.transparent,
        position: PopupMenuPosition.under,
        tooltip: '',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: _getBorder(context).top,
        ),
        offset: const Offset(0, 10),
        padding: EdgeInsets.zero,
        menuPadding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              height: 50,
              padding: const EdgeInsets.all(8).copyWith(right: 0),
              child: Builder(
                builder: (BuildContext context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ..._SavedProjectsSortOption.values.map(
                        (_SavedProjectsSortOption sortBy) {
                          return InkWell(
                            onTap: () {
                              onSelect?.call(sortBy);
                              Navigator.of(context).pop();
                            },
                            // behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: FusionAppText(
                                      text: sortBy.title,
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                  ),
                                ),
                                if (sortBy == selectedSortOption) ...<Widget>[
                                  Icon(
                                    LucideIcons.check,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ];
        },
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            children: <Widget>[
              FusionAppText(
                text: 'Sort by',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Icon(
                LucideIcons.chevronDown200,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterByWidget extends StatelessWidget {
  const _FilterByWidget();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFFF5F5F5),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        splashColor: Colors.transparent, // Disable ripple
        highlightColor: Colors.transparent, // Disable tap highlight
        hoverColor: Colors.transparent, // Disable hover color
      ),
      child: PopupMenuButton<String>(
        color: Theme.of(context).colorScheme.surface,
        shadowColor: Colors.transparent,
        position: PopupMenuPosition.under,
        tooltip: '',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: _getBorder(context).top,
        ),
        offset: const Offset(0, 10),
        padding: EdgeInsets.zero,
        menuPadding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              height: 50,
              padding: const EdgeInsets.all(8).copyWith(right: 0),
              child: Builder(
                builder: (BuildContext context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ..._SavedProjectsSortOption.values.map(
                        (_SavedProjectsSortOption sortBy) {
                          return InkWell(
                            onTap: () {
                              // widget.onSelect(value);
                              // Navigator.of(context).pop();
                            },
                            // behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: FusionAppText(
                                    text: sortBy.title,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ];
        },
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            children: <Widget>[
              FusionAppText(
                text: 'Filter',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Icon(
                LucideIcons.chevronDown200,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateNewProjectDialog extends StatefulWidget {
  const CreateNewProjectDialog({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      AnimatedBlurDialogRoute<void>(
        builder: (BuildContext context) {
          return const Material(
            color: Colors.transparent,
            child: CreateNewProjectDialog(),
          );
        },
      ),
    );
  }

  @override
  State<CreateNewProjectDialog> createState() => _CreateNewProjectDialogState();
}

class _CreateNewProjectDialogState extends State<CreateNewProjectDialog> {
  ValueNotifier<bool> shouldShowMoreDetailsNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    shouldShowMoreDetailsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double borderRadius = 14;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.maxWidth * 0.5 > 660 ? 660 : constraints.maxWidth * 0.5;

        return Container(
          constraints: BoxConstraints(
            maxWidth: cardWidth,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  spacing: 5,
                  children: <Widget>[
                    const Icon(Icons.circle, color: Colors.red),
                    const Icon(Icons.circle, color: Colors.orange),
                    const Icon(Icons.circle, color: Colors.green),
                    const Spacer(),
                    Badge(
                      smallSize: 8, // ← tiny dot size
                      alignment: Alignment.topRight,
                      backgroundColor: Colors.red,
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          size: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      child: FusionAppText(
                        text: "Help",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Icon(
                        LucideIcons.userRound,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12).copyWith(bottom: 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FusionAppText(
                          text: "BASIC INFORMATION",
                          maxLine: 2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        const Row(
                          spacing: 10,
                          children: <Widget>[
                            Expanded(
                              child: BorderedTextfield(
                                label: "Project File Name",
                                hintText: "Project Name",
                              ),
                            ),
                            Expanded(
                              child: BorderedTextfield(
                                label: "File Version",
                                hintText: "Version Number",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const BorderedTextfield(
                          label: "Project Tags or Categories",
                          hintText: "Add tags or categories (separated by commas)",
                        ),
                        const SizedBox(height: 5),
                        const Row(
                          spacing: 10,
                          children: <Widget>[
                            Expanded(
                              child: BorderedTextfield(
                                label: "Author Name",
                                hintText: "Full Name",
                              ),
                            ),
                            Expanded(
                              child: BorderedTextfield(
                                label: "Organization",
                                hintText: "Organization Name",
                              ),
                            ),
                          ],
                        ),

                        // =============================================
                        //  Add More Details Section
                        // =============================================
                        ValueListenableBuilder<bool>(
                          valueListenable: shouldShowMoreDetailsNotifier,
                          builder: (BuildContext context, bool value, Widget? child) {
                            return AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),
                              crossFadeState: shouldShowMoreDetailsNotifier.value ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              firstChild: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18).copyWith(top: 12),
                                child: InkWell(
                                  onTap: () {
                                    shouldShowMoreDetailsNotifier.value = !shouldShowMoreDetailsNotifier.value;
                                  },
                                  splashColor: Colors.transparent,
                                  child: FusionAppText(
                                    text: "Add More Details",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                              secondChild: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12).copyWith(bottom: 0),
                                child: Column(
                                  spacing: 10,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: "ORGANIZATION DETAILS",
                                      maxLine: 2,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const BorderedTextfield(
                                      label: "Project Tags or Categories",
                                      hintText: "Add tags or categories (separated by commas)",
                                    ),
                                    const SizedBox(height: 5),
                                    const Row(
                                      spacing: 10,
                                      children: <Widget>[
                                        Expanded(
                                          child: BorderedTextfield(
                                            label: "Author Name",
                                            hintText: "Full Name",
                                          ),
                                        ),
                                        Expanded(
                                          child: BorderedTextfield(
                                            label: "Organization",
                                            hintText: "Organization Name",
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      child: InkWell(
                                        onTap: () {
                                          shouldShowMoreDetailsNotifier.value = !shouldShowMoreDetailsNotifier.value;
                                        },
                                        splashColor: Colors.transparent,
                                        child: FusionAppText(
                                          text: "Show Less Details",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 5),
                        const BorderedTextfield(
                          label: "Notes",
                          hintText: "Add notes or comments",
                          minLines: 5,
                          maxLines: 10,
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
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

class BorderedTextfield extends StatelessWidget {
  final String label, hintText;
  final int minLines, maxLines;
  const BorderedTextfield({super.key, required this.label, required this.hintText, this.minLines = 1, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: FusionAppText(
            text: label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          minLines: minLines,
          maxLines: maxLines,

          decoration: InputDecoration(
            hintText: hintText,

            hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),

            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
