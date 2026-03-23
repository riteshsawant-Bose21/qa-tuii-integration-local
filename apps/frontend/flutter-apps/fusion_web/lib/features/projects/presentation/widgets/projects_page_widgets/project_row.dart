import 'package:flutter/material.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
import '../../../data/models/project_model.dart';
import '../projects_page_widgets/status_badge.dart';
import '../projects_page_widgets/health_stat.dart';
import '../projects_page_widgets/incidents_badge.dart';

class ProjectRow extends StatelessWidget {
  final ProjectModel project;
  final bool isLast;
  final Function(ProjectModel) onTap;

  const ProjectRow({
    super.key,
    required this.project,
    required this.onTap,
    this.isLast = false,
  });

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        hoverColor: Colors.grey[100],
        onTap: () => onTap(project),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.zero,
          ),
          child: Row(
            children: [
              /// PROJECT
              Expanded(
                flex: 3,
                child: Text(
                  project.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// Client
              Expanded(
                flex: 3,
                child: Text(
                  project.clientName,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// phase(status)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: project.status),
                ),
              ),

              const SizedBox(width: 12),

              /// status (region) - indoor / outdoor / hybrid
              SizedBox(
            width: 70,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    project.region,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// INCIDENTS
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IncidentsBadge(count: project.incidents),
                ),
              ),
              const SizedBox(width: 12),

              /// HEALTH
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    HealthStat(
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      count: project.healthyDevices,
                    ),
                    const SizedBox(width: 8),
                    HealthStat(
                      icon: Icons.warning,
                      color: Colors.orange,
                      count: project.warningDevices,
                    ),
                    const SizedBox(width: 8),
                    HealthStat(
                      icon: Icons.cancel,
                      color: Colors.red,
                      count: project.criticalDevices,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// UPDATED
             SizedBox(
            width: 65,
                child: Text(
                  _formatDate(project.lastUpdated),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),

              SizedBox(
                width: 48, 
                child: Align(
                  alignment: Alignment.centerRight,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
