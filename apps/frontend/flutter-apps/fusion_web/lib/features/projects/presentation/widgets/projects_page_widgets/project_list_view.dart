import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/color_pallette.dart';
import '../../../data/models/project_model.dart';
import 'project_row.dart';
import 'project_table_header.dart';

class ProjectsListView extends StatelessWidget {
  final List<ProjectModel> projects;
  final Function(ProjectModel) onTap;

  const ProjectsListView({
    super.key,
    required this.projects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: context.colorScheme.elevation2,
      // raised: true,
      child: Column(
        children: [
          const ProjectTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color:  context.colorScheme.elevation3),
              itemBuilder: (context, index) {
                return ProjectRow(
                  project: projects[index],
                  isLast: index == projects.length - 1,
                  onTap: onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}