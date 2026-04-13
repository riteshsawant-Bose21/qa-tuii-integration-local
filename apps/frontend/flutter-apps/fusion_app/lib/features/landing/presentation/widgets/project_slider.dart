import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/landing/presentation/widgets/project_card.dart';
import 'package:fusion_app/features/landing/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart' show serviceLocator;
class ProjectSlider extends StatelessWidget {

  final List<ProjectData> projects;
  const ProjectSlider({required this.projects,super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: projects.length,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        return ProjectCard(
            onClick:(){
              // serviceLocator<ProjectViewModel>().openProject(projects[i].id);
              Navigator.pushNamed(
                  context,
                  Routes.homePage
              );
            },
            data: projects[i]
        );
      },
    );
  }
}
