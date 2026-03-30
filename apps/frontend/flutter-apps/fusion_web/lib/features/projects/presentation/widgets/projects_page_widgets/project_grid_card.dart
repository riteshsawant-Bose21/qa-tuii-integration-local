import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';

import '../../../data/models/project_model.dart';
import 'status_badge.dart';
import 'device_health_box.dart';
import 'open_incidents_warning.dart';

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
    final total =
        project.healthyDevices +
        project.warningDevices +
        project.criticalDevices;

    return InkWell(
      onTap: () => onTap(project),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: context.colorScheme.onSurface.withValues(alpha: 0.05),

          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),

                ProjectActionsMenu(
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
              ],
            ),

            const SizedBox(height: 12),

            /// client
            Text(
              project.clientName,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),

            const SizedBox(height: 12),

            /// region (status)
            Text(
              project.region,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),

            const SizedBox(height: 12),

            /// status badge ( phase )
            StatusBadge(status: project.status),

           

            const SizedBox(height: 12),

            /// device health
            if (total >= -1)
              DeviceHealthBox(
                healthy: project.healthyDevices,
                warning: project.warningDevices,
                critical: project.criticalDevices,
              ),

            const SizedBox(height: 12),

            /// incidents
            if (project.incidents > -1)
              OpenIncidentsWarning(count: project.incidents),

            const Spacer(),

            /// updated date
            Text(
              "Updated ${_formatDate(project.lastUpdated)}",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
