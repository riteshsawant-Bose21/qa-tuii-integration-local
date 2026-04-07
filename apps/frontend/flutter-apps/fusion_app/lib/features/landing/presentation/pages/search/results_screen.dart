import 'package:flutter/material.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/features/landing/presentation/pages/search/no_results_screen.dart';
import 'package:fusion_app/features/landing/presentation/widgets/project_slider.dart';
import 'package:fusion_app/features/landing/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ResultsScreen extends StatelessWidget {
  final List<ProjectData> projects;
  const ResultsScreen({super.key, required this.projects});


  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Title
            if(projects.isEmpty)
              SearchNoResultScreen()
            else
            Expanded(child: ProjectSlider(projects: projects))
          ],
        ),
      ),
    );
  }

}