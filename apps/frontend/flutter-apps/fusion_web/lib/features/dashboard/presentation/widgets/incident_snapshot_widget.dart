import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

/// Incident snapshot widget showing incident statistics
class IncidentSnapshotWidget extends StatelessWidget {
  final IncidentSnapshotEntity? incidentSnapshot;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const IncidentSnapshotWidget({
    super.key,
    this.incidentSnapshot,
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
                  text: 'Incident Snapshot',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.elevation6,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation3,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 16),
                  ),
              ],
            ),
          ),

          if (isLoading && incidentSnapshot == null)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (incidentSnapshot != null) ...[
            const SizedBox(height: 24),

            /// MAIN METRICS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      context,
                      incidentSnapshot!.totalOpenIncidents.toString(),
                      'Open Incidents',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      context,
                      incidentSnapshot!.criticalAlerts.toString(),
                      'Critical Alerts',
                      Icons.priority_high,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// TREND
            if (incidentSnapshot!.incidentTrendData.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FusionAppText(
                        text: 'Incident Trend (Last 7 Days)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.elevation6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrendChart(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            /// CATEGORIES
            if (incidentSnapshot!.topIncidentCategories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: context.colorScheme.elevation3),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FusionAppText(
                  text: 'Top Incident Categories',
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
                child: _buildCategoriesChart(context),
              ),
            ],

            const SizedBox(height: 24),
          ] else
            const SizedBox(
              height: 200,
              child: Center(child: Text('No incident data available')),
            ),
        ],
      ),
    );
  }

  /// METRIC
  Widget _buildMetric(
    BuildContext context,
    String value,
    String label,
    IconData icon,
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
        children: [
          Icon(icon, color: accent),
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

  /// TREND CHART
  Widget _buildTrendChart(BuildContext context) {
    final max = incidentSnapshot!.incidentTrendData
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: incidentSnapshot!.incidentTrendData.map((point) {
          final double height = max == 0 ? 0.0 : (point.count / max) * 80;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FusionAppText(
                  text: point.count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: context.colorScheme.elevation6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// CATEGORY CHART
  Widget _buildCategoriesChart(BuildContext context) {
    final max = incidentSnapshot!.topIncidentCategories.values.fold<int>(
      0,
      (m, v) => v > m ? v : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: incidentSnapshot!.topIncidentCategories.entries.map((e) {
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

                      style: GoogleFonts.inter(
                        color: context.colorScheme.elevation6,
                      ),
                    ),
                  ),
                  FusionAppText(
                    text: e.value.toString(),
                    style: GoogleFonts.inter(
                      color: context.colorScheme.elevation6,
                    ),
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
                      color: Colors.red,
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
}
