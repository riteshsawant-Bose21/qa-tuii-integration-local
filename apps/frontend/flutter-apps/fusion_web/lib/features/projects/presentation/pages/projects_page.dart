import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
import 'package:fusion_web/features/projects/presentation/widgets/projects_page_widgets/projects_page_content.dart';
//Routes
import 'package:go_router/go_router.dart';
//base viewmodel
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
//project specific
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
//Ui widgets
import 'package:fusion_web/features/projects/presentation/widgets/projects_page_widgets/project_filters.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final ProjectsViewModel _viewModel = ServiceLocator().projectsViewModel;
  // Make it scalable for larger screens
  double get headlineFontSize => MediaQuery.of(context).size.width * 0.07;
  double get subHeadingFontSize => MediaQuery.of(context).size.width * 0.02;

  @override
  void initState() {
    super.initState();

    _viewModel.initialize();
  }

  void _navigateToDetail(ProjectModel project) {
    context.go('${AppConstants.projectsRoute}/${project.id}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _viewModel,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<ProjectsViewModel, BaseState<List<ProjectModel>>>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    title: 'Projects',
                    subtitle:
                        'Manage and monitor all projects across your organization',
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation2,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const SizedBox(height: 24),
                          const SizedBox(height: 12),
                          const ProjectsFilters(),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ProjectsPageContent(
                              state: state,
                              onProjectTap: _navigateToDetail,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
