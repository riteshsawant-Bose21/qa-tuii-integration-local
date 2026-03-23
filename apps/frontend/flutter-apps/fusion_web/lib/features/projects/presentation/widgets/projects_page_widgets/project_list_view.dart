import 'package:flutter/material.dart';
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        color: Colors.white,
      ),
      child: Column(
        children: [
          const ProjectTableHeader(),

          /// 👇 THIS should scroll
          Expanded(
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
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