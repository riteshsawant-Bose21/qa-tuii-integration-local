import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

/// Users overview widget showing user statistics and role breakdown
class UsersOverviewWidget extends StatelessWidget {
  final UsersOverviewEntity? usersOverview;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const UsersOverviewWidget({
    super.key,
    this.usersOverview,
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
                  text: 'Users Overview',
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

          if (isLoading && usersOverview == null)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )

          else if (usersOverview != null) ...[
            const SizedBox(height: 24),

            /// MAIN METRICS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMainMetric(
                      context,
                      usersOverview!.totalUsers.toString(),
                      'Total Users',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMainMetric(
                      context,
                      usersOverview!.usersJoinedLast30Days.toString(),
                      'Joined (30 days)',
                      Icons.person_add,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// STATUS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatusCard(context, usersOverview!.activeUsers.toString(), 'Active', Colors.green, Icons.check_circle),
                  _buildStatusCard(context, usersOverview!.invitedUsers.toString(), 'Invited', Colors.blue, Icons.mail),
                  _buildStatusCard(context, usersOverview!.inactiveUsers.toString(), 'Inactive', Colors.grey, Icons.person_off),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// USERS BY ROLE
            if (usersOverview!.usersByRole.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FusionAppText(
                  text: 'Users by Role',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.elevation6,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRoleChart(context),
              ),

              const SizedBox(height: 24),
            ],

            /// USER TYPES
            if (usersOverview!.usersByType.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: context.colorScheme.elevation3),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FusionAppText(
                  text: 'User Types Distribution',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.elevation6,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: usersOverview!.usersByType.entries
                      .map((e) => _buildTypeChip(context, e.key, e.value))
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ]

          else
            const SizedBox(
              height: 200,
              child: Center(child: Text('No user data available')),
            ),
        ],
      ),
    );
  }

  /// MAIN CARD
  Widget _buildMainMetric(BuildContext context, String value, String label, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 12),
          FusionAppText(
            text: value,
            style: GoogleFonts.inter(
              fontSize: 24,
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

  /// STATUS CARD
  Widget _buildStatusCard(BuildContext context, String count, String label, Color accent, IconData icon) {
    return SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation3,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 6),
            FusionAppText(
              text: count,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.elevation6,
              ),
            ),
            FusionAppText(
              text: label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.colorScheme.elevation6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ROLE CHART
  Widget _buildRoleChart(BuildContext context) {
    final max = usersOverview!.usersByRole.values.fold<int>(0, (m, v) => v > m ? v : m);

    return Column(
      children: usersOverview!.usersByRole.entries.map((e) {
        final percent = max == 0 ? 0 : e.value / max;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Row(
                children: [
                  Expanded(
                    child: FusionAppText(
                      text: e.key,
                      style: GoogleFonts.inter(color: context.colorScheme.elevation6),
                    ),
                  ),
                  FusionAppText(
                    text: e.value.toString(),
                    style: GoogleFonts.inter(color: context.colorScheme.elevation6),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation3,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: percent.toDouble(),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// TYPE CHIP
  Widget _buildTypeChip(BuildContext context, String type, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FusionAppText(
        text: '$type ($count)',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: context.colorScheme.elevation6,
        ),
      ),
    );
  }
}