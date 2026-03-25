import 'package:flutter/material.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Text(
                  'Incident Snapshot',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  GestureDetector(
                    onTap: isLoading ? null : onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Color(0xFF64748B),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                    ),
                  ),
              ],
            ),
          ),

          if (isLoading && incidentSnapshot == null)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFEF4444)),
                ),
              ),
            )
          else if (incidentSnapshot != null) ...[
            const SizedBox(height: 24),

            // Main metrics row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMainMetric(
                      incidentSnapshot!.totalOpenIncidents.toString(),
                      'Open Incidents',
                      const Color(0xFFF59E0B),
                      Icons.warning_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMainMetric(
                      incidentSnapshot!.criticalAlerts.toString(),
                      'Critical Alerts',
                      const Color(0xFFEF4444),
                      Icons.priority_high_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Trend visualization
            if (incidentSnapshot!.incidentTrendData.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident Trend (Last 7 Days)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrendChart(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],

            // Top incident categories
            if (incidentSnapshot!.topIncidentCategories.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: Color(0xFFE2E8F0)),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Top Incident Categories',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCategoriesChart(),
              ),
            ],

            const SizedBox(height: 24),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.report_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No incident data available',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainMetric(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (incidentSnapshot!.incidentTrendData.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'No trend data available',
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      );
    }

    final maxCount = incidentSnapshot!.incidentTrendData
        .map((point) => point.count)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: incidentSnapshot!.incidentTrendData.map((point) {
          final height = maxCount > 0 ? (point.count / maxCount) * 80 : 0.0;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF4444),
                          const Color(0xFFEF4444).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriesChart() {
    final maxCount = incidentSnapshot!.topIncidentCategories.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );

    return Column(
      children: incidentSnapshot!.topIncidentCategories.entries.take(5).map((
        entry,
      ) {
        final percentage = (entry.value / maxCount * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
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
