import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

class ProjectOverviewWidget extends StatelessWidget {
  final ProjectOverviewEntity? projectOverview;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const ProjectOverviewWidget({
    super.key,
    this.projectOverview,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                FusionAppText(
                  text: 'Project Overview',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.elevation6,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  GestureDetector(
                    onTap: isLoading ? null : onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation3,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 16),
                    ),
                  ),
              ],
            ),
          ),

          /// LOADING
          if (isLoading && projectOverview == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          /// DATA
          else if (projectOverview != null) ...[
            const SizedBox(height: 24),

            /// MAIN ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildMainMetric(
                      context,
                      projectOverview!.totalProjects.toString(),
                      'Total Projects',
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 32),

                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatusMetric(
                            context,
                            projectOverview!.activeProjects.toString(),
                            'Active',
                            const Color(0xFF10B981),
                            Icons.play_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatusMetric(
                            context,
                            projectOverview!.completedProjects.toString(),
                            'Completed',
                            const Color(0xFF3B82F6),
                            Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatusMetric(
                            context,
                            projectOverview!.archivedProjects.toString(),
                            'Archived',
                            const Color(0xFF64748B),
                            Icons.archive_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// ACTIVITY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActivityCard(
                      context,
                      projectOverview!.recentActivityCount7Days,
                      'Last 7 Days',
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActivityCard(
                      context,
                      projectOverview!.recentActivityCount30Days,
                      'Last 30 Days',
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ]
          /// EMPTY
          else
            Expanded(
              child: Center(
                child: Text(
                  'No project data available',
                  style: GoogleFonts.inter(
                    color: context.colorScheme.elevation6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainMetric(
    BuildContext context,
    String value,
    String label,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16), // match others
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [


          FusionAppText(
            text: value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.elevation6,
            ),
          ),

          FusionAppText(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.colorScheme.elevation6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(
    BuildContext context,
    String value,
    String label,
    Color accent,
    IconData icon,
  ) {
    return Container(
  
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FusionAppText(
            text: value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.elevation6,
            ),
          ),

          FusionAppText(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.colorScheme.elevation6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    int value,
    String label,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FusionAppText(
            text: value.toString(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.elevation6, 
            ),
          ),

          FusionAppText(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.colorScheme.elevation6,
            ),
          ),
        ],
      ),
    );
  }
}
