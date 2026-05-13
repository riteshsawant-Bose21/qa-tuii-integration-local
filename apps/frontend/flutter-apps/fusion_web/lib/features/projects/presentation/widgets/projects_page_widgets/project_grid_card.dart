import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';

import '../../../data/models/project_model.dart';

class ProjectGridCard extends StatelessWidget {
  final ProjectModel project;
  final Function(ProjectModel) onTap;

  const ProjectGridCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {


    return InkWell(
      onTap: () => onTap(project),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "assets/icons/floor_plan_placeholder.png",
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.topLeft,
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: ProjectActionsMenu(
                        onInvite: () => ProjectActionsHandler.invite(
                          context: context,
                          project: project,
                          viewModel: ServiceLocator().projectsViewModel,
                        ),
                        onArchive: () => ProjectActionsHandler.archive(
                          context: context,
                          project: project,
                          viewModel: ServiceLocator().projectsViewModel,
                        ),
                        onDelete: () => ProjectActionsHandler.delete(
                          context: context,
                          project: project,
                          viewModel: ServiceLocator().projectsViewModel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔹 CONTENT (LIKE REFERENCE)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FusionAppText(
                        text: project.name,
                        textAlign: TextAlign.left,
                      ),
                    ),

                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FusionAppText(
                        text: "Updated ${_formatDate(project.lastUpdated)}",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: context.colorScheme.elevation6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
