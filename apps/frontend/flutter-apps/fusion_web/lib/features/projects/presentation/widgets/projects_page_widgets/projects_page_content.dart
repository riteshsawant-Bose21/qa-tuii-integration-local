import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/presentation/widgets/projects_page_widgets/project_grid_view.dart';
import 'package:fusion_web/features/projects/presentation/widgets/projects_page_widgets/project_list_view.dart';

class ProjectsPageContent extends StatelessWidget {
  final BaseState<List<ProjectModel>> state;
  final Function(ProjectModel) onProjectTap;

  const ProjectsPageContent({
    super.key,
    required this.state,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjectsViewModel>();

    if (state is LoadingState) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colorScheme.white,
        ),
      );
    }

    if (state is ErrorState<List<ProjectModel>>) {
      return Center(
        child: FusionAppText(text: (state as ErrorState).message),
      );
    }

    final projects = (state as LoadedState<List<ProjectModel>>).data;

    return viewModel.isGridView
        ? ProjectsGridView(
            projects: projects,
            onTap: onProjectTap,
          )
        : ProjectsListView(
            projects: projects,
            onTap: onProjectTap,
          );
  }
}