import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/project_card.dart';
import 'package:fusion_launcher/features/projects/view_model/project_sync_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/utils/fusion_utils.dart';
import '../../../authentication/viewmodel/session_view_model.dart';
import '../../../create_new_project/views/create_new_project_dialog.dart';
import 'import_project_dialog.dart';

Border _getBorder(BuildContext context) => Border.all(
  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
  width: 0.3,
);

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
                    color: context.colorScheme.elevation1,
                    borderRadius: BorderRadius.circular(12),
                    border: _getBorder(context),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Create a New Blank Project',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FusionNeumorphicButton(
                        semanticId: 'create_new_project_button',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => const ZipImportDialog(),
                          );
                        },
                        height: 50,
                        width: 100,

                        borderRadius: 10,
                        child: const FusionAppText(text: "Import"),
                      ),
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: SemanticHelper.button(
                          testId: SemanticHelper.createTestId(
                            SemanticTypes.button,
                            "create_new_project_button",
                          ),
                          child: FusionNeumorphicButton(
                            semanticId: 'create_new_project_button',
                            onTap: () {
                              CreateNewProjectDialog.show(context);
                            },
                            height: 50,
                            width: 50,
                            borderRadius: 10,
                            child: FittedBox(
                              child: Icon(
                                LucideIcons.plus100,
                                color: context.colorScheme.onSurface,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded(
              //   child: Container(
              //     height: 80,
              //     width: double.infinity,
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: context.colorScheme.surface,
              //       borderRadius: BorderRadius.circular(12),
              //       border: _getBorder(context),
              //     ),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: <Widget>[
              //         FusionAppText(
              //           text: 'Templates',
              //           style: context.textTheme.titleMedium?.copyWith(
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),

              //         Flexible(
              //           child: Row(
              //             children: <Widget>[
              //               Expanded(
              //                 child: FusionAppText(
              //                   text: 'Start working from a prebuilt template.',
              //                   style: context.textTheme.labelSmall?.copyWith(
              //                     color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              //                   ),
              //                 ),
              //               ),
              //               MouseRegion(
              //                 cursor: SystemMouseCursors.click,
              //                 child: NeumorphicDarkButton(
              //                   onTap: () {
              //                     // Navigator.pushNamed(context, Routes.projectPage);
              //                   },
              //                   height: 26,
              //                   width: 38,
              //                   borderRadius: 10,
              //                   child: FittedBox(
              //                     child: Icon(
              //                       LucideIcons.arrowRight,
              //                       color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
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
    setState(
      () => _isSearching = query.isNotEmpty && query.length >= MIN_SEARCH_LENGTH,
    );
  }

  List<ProjectData> get getProjects {
    late List<ProjectData> projects;

    final List<ProjectData> allProjects = serviceLocator<ProjectViewModel>().allProjects;

    // ================ SEARCH PROJECTS IF QUERY IS NOT EMPTY ==========================
    final String searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty && searchQuery.length >= MIN_SEARCH_LENGTH) {
      final List<ProjectData> allProjects = serviceLocator<ProjectViewModel>().allProjects;
      projects =
          allProjects
              .where(
                (ProjectData project) => project.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
    } else {
      // ======= SHOW ALL PROJECTS IF QUERY IS EMPTY ==========
      projects = allProjects;
    }

    // ======= SORT LOGIN AT THE END =======
    if (selectedSortOption == _SavedProjectsSortOption.name) {
      projects.sort(
        (ProjectData a, ProjectData b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return projects;
  }

  bool get hasCloudAccess {
    return serviceLocator<SessionViewModel>().hasCloudAccess();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectSyncViewModel, ProjectSyncViewModelState>(
      listener: (BuildContext context, ProjectSyncViewModelState syncState) {
        if (syncState is ProjectsLoadFailure) {
          FusionToast.show(context, message: syncState.error);
        }
      },
      builder: (BuildContext context, ProjectSyncViewModelState syncState) {
        return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
          listener: (BuildContext context, ProjectViewModelState state) {
            if (state is OpenProjectError && context.mounted) {
              FusionUiUtils.hideLoader(context);
              FusionToast.show(context, message: state.message);
            }
          },
          builder: (BuildContext context, ProjectViewModelState state) {
            final List<ProjectData> projects = getProjects;

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SemanticHelper.container(
                  testId: SemanticHelper.createTestId(
                    SemanticTypes.container,
                    "saved_projects_section",
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation1,
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: 'Projects',
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    //cloud sync icon button
                                    if (hasCloudAccess)
                                      SemanticHelper.button(
                                        testId: SemanticHelper.createTestId(
                                          SemanticTypes.button,
                                          "saved_projects_section_item_upload",
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            serviceLocator<ProjectSyncViewModel>().uploadAllProjects();
                                          },
                                          tooltip: "Upload All Projects to Cloud",
                                          icon: Icon(
                                            LucideIcons.cloudUpload,
                                            size: 18,
                                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    //cloud download icon button
                                    if (hasCloudAccess)
                                      SemanticHelper.button(
                                        testId: SemanticHelper.createTestId(
                                          SemanticTypes.button,
                                          "saved_projects_section_item_download",
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            serviceLocator<ProjectSyncViewModel>().getAllProjects(
                                              forceFetch: true,
                                            );
                                          },
                                          tooltip: "Download All Projects from Cloud",
                                          icon: Icon(
                                            LucideIcons.cloudDownload,
                                            size: 18,
                                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              ValueListenableBuilder<bool>(
                                valueListenable: showSearchBarNotifier,
                                builder: (
                                  BuildContext context,
                                  bool showSearchBar,
                                  Widget? child,
                                ) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: showSearchBar ? context.colorScheme.onSurface.withValues(alpha: 0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: showSearchBar ? 250 : 0,
                                          child: SemanticHelper.formControl(
                                            testId: SemanticHelper.createTestId(
                                              SemanticTypes.textInput,
                                              "saved_projects_section_search_input",
                                            ),
                                            child: TextFormField(
                                              focusNode: _searchFocusNode,
                                              controller: _searchController,
                                              style: context.textTheme.labelLarge,
                                              cursorColor: context.colorScheme.onSurface,
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
                                                hintStyle: context.textTheme.labelMedium?.copyWith(
                                                  color: Colors.grey,
                                                ),
                                              ),
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
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            transitionBuilder: (
                                              Widget child,
                                              Animation<double> animation,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            child: SemanticHelper.button(
                                              testId: SemanticHelper.createTestId(
                                                SemanticTypes.button,
                                                "saved_projects_section_search_button",
                                              ),
                                              child: Icon(
                                                key: ValueKey<bool>(
                                                  showSearchBar,
                                                ),
                                                showSearchBar ? LucideIcons.x : LucideIcons.search,
                                                size: 18,
                                              ),
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
                              // const _FilterByWidget(), // TODO: Implement filter functionality
                            ],
                          ),
                        ),

                        Expanded(
                          child: Builder(
                            builder: (BuildContext context) {
                              //Add a circle progress indicator when loading projects
                              if (syncState is LoadingAllProjects) {
                                return Center(
                                  child: SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }

                              if (_isSearching && projects.isEmpty) {
                                return Center(
                                  child: FusionAppText(
                                    text: "No Projects Found for \"${_searchController.text}\"",
                                    style: context.textTheme.labelLarge?.copyWith(
                                      fontSize: 16,
                                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                );
                              } else if (state is! ProjectLoading && !serviceLocator<ProjectViewModel>().hasProjects) {
                                return Center(
                                  child: FusionAppText(
                                    text: "No Projects Saved Yet",
                                    style: context.textTheme.labelLarge?.copyWith(
                                      fontSize: 16,
                                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
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
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final ProjectData project = projects[index];

                                    return GestureDetector(
                                      onTap:
                                          () => ProjectDetailsDialog.show(
                                            context,
                                            project: project,
                                          ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: context.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: _getBorder(context),
                                        ),
                                        child: ProjectCard(
                                          index: index,
                                          projectData: project,
                                          onDelete:
                                              () => serviceLocator<ProjectSyncViewModel>().deleteProject(
                                                projectId: project.id,
                                              ),
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
                  ),
                );
              },
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

  const _SortByWidget({
    required this.selectedSortOption,
    required this.onSelect,
  });

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
        color: context.colorScheme.surface,
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
                          return SemanticHelper.button(
                            testId: SemanticHelper.createTestId(
                              SemanticTypes.button,
                              "saved_projects_section_sort_button_$sortBy",
                            ),
                            child: InkWell(
                              onTap: () {
                                onSelect?.call(sortBy);
                                Navigator.of(context).pop();
                              },
                              // behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      child: FusionAppText(
                                        text: sortBy.title,
                                        style: context.textTheme.labelMedium,
                                      ),
                                    ),
                                  ),
                                  if (sortBy == selectedSortOption) ...<Widget>[
                                    Icon(
                                      LucideIcons.check,
                                      color: context.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ],
                              ),
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
        child: SemanticHelper.button(
          testId: SemanticHelper.createTestId(
            SemanticTypes.button,
            "saved_projects_section_sort_button",
          ),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Row(
              children: <Widget>[
                FusionAppText(
                  text: 'Sort by',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown200,
                  size: 18,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
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
        color: context.colorScheme.surface,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  child: FusionAppText(
                                    text: sortBy.title,
                                    style: context.textTheme.labelMedium,
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
        child: SemanticHelper.button(
          testId: SemanticHelper.createTestId(
            SemanticTypes.button,
            "saved_projects_section_item_upload",
          ),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Row(
              children: <Widget>[
                FusionAppText(
                  text: 'Filter',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown200,
                  size: 18,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BorderedTextfield extends StatefulWidget {
  final String? controllerValue;
  final String label, hintText;
  final int minLines, maxLines;
  final bool isEnabled, isObscured;
  final FormFieldValidator<String>? validator;
  final String? sementicFieldId;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const BorderedTextfield({
    super.key,
    this.controllerValue,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.isEnabled = true,
    this.isObscured = false,
    this.validator,
    this.sementicFieldId,
    this.autofocus = false,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<BorderedTextfield> createState() => _BorderedTextfieldState();
}

class _BorderedTextfieldState extends State<BorderedTextfield> {
  late bool isObscured;
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;
  bool isFocused = false;

  @override
  void initState() {
    super.initState();

    isObscured = widget.isObscured;
    _controller.text = widget.controllerValue ?? '';

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BorderedTextfield oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String incoming = widget.controllerValue ?? '';

    if (incoming != _controller.text) {
      _controller.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 12.0;

    final Widget obsecuredWidget = InkWell(
      onTap: () => setState(() => isObscured = !isObscured),
      splashColor: Colors.transparent,
      child: Icon(
        isObscured ? LucideIcons.eyeOff : LucideIcons.eye,
        size: 18,
        color: context.colorScheme.textPrimary.withValues(alpha: 0.6),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: widget.label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.textPrimary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        SemanticHelper.formControl(
          testId: SemanticHelper.createTestId(
            SemanticTypes.textInput,
            widget.sementicFieldId ?? "${widget.label}_input",
          ),
          child: TextFormField(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            controller: _controller,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            enabled: widget.isEnabled,
            obscureText: isObscured,
            inputFormatters: widget.inputFormatters,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.textPrimary,
            ),
            onChanged: widget.onChanged,
            validator: widget.validator,
            mouseCursor: widget.isEnabled ? null : SystemMouseCursors.forbidden,
            cursorColor: context.colorScheme.textPrimary,
            cursorWidth: 1,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.textPrimary.withValues(alpha: 0.4),
              ),
              errorStyle: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.errorText,
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(14),
              suffixIcon: widget.isObscured ? obsecuredWidget : null,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: context.colorScheme.errorText),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: context.colorScheme.strokeLight),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: context.colorScheme.strokeLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: context.colorScheme.strokeLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: context.colorScheme.primaryWhite),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
