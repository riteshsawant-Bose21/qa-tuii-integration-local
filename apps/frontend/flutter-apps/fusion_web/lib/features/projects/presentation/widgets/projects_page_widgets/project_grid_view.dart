import 'package:flutter/material.dart';
import '../../../data/models/project_model.dart';
import 'project_grid_card.dart';

class ProjectsGridView extends StatelessWidget {
  final List<ProjectModel> projects;
  final Function(ProjectModel) onTap;

  const ProjectsGridView({
    super.key,
    required this.projects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (con, index) {
        return ProjectGridCard(project: projects[index], onTap: onTap);
      },
    );
  }
}
