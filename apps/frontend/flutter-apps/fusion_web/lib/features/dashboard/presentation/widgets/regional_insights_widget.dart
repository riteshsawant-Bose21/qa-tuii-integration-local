import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

class RegionalInsightsWidget extends StatelessWidget {
  final RegionalInsightsEntity? regionalInsights;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const RegionalInsightsWidget({
    super.key,
    this.regionalInsights,
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
                  text: 'Regional Insights',
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

          if (isLoading && regionalInsights == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))

          else if (regionalInsights != null) ...[
            const SizedBox(height: 24),

            /// GLOBAL COVERAGE CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, color: Colors.purple),
                        const SizedBox(width: 8),
                        FusionAppText(
                          text: 'Global Coverage',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.elevation6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            context,
                            regionalInsights!.projectsByRegion.length.toString(),
                            'Regions',
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            regionalInsights!.activePartnersByRegion.length.toString(),
                            'Partners',
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            regionalInsights!.devicesByGeography.values
                                .fold(0, (a, b) => a + b)
                                .toString(),
                            'Devices',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// TOP REGIONS
            if (regionalInsights!.projectsByRegion.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FusionAppText(
                  text: 'Top Performing Regions',
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
                child: Column(
                  children: regionalInsights!.projectsByRegion.entries
                      .take(5)
                      .map((e) => _buildRegionCard(context, e.key, e.value))
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
            ],

            /// DISTRIBUTION
            if (regionalInsights!.activePartnersByRegion.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: context.colorScheme.elevation3),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FusionAppText(
                  text: 'Active Partners by Region',
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
                child: _buildDistributionChart(context),
              ),
            ],

            const SizedBox(height: 24),
          ]

          else
            Expanded(
              child: Center(
                child: FusionAppText(
                  text: 'No regional data available',
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

  /// METRIC
  Widget _buildMetric(BuildContext context, String value, String label) {
    return Column(
      children: [
        FusionAppText(
          text: value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colorScheme.elevation6,
          ),
        ),
        FusionAppText(
          text: label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.colorScheme.elevation6,
          ),
        ),
      ],
    );
  }

  /// REGION CARD
  Widget _buildRegionCard(
      BuildContext context, String region, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: FusionAppText(
              text: region,
              style: GoogleFonts.inter(
                color: context.colorScheme.elevation6,
              ),
            ),
          ),
          FusionAppText(
            text: value.toString(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.elevation6,
            ),
          ),
        ],
      ),
    );
  }

  /// DISTRIBUTION CHART
  Widget _buildDistributionChart(BuildContext context) {
    final maxValue = regionalInsights!.activePartnersByRegion.values
        .fold<int>(0, (max, v) => v > max ? v : max);

    return Column(
      children: regionalInsights!.activePartnersByRegion.entries.take(6).map((entry) {
        final percent = maxValue == 0 ? 0.0 : (entry.value / maxValue).toDouble();
  
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FusionAppText(
                        text: entry.key,
                        style: GoogleFonts.inter(
                          color: context.colorScheme.elevation6,
                        ),
                      ),
                    ),
                    FusionAppText(
                      text: entry.value.toString(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
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
                    widthFactor: percent,
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
}