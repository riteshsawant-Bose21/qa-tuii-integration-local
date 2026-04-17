import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/dashboard/domain/entities/dashboard_entities.dart';

class DeviceHealthWidget extends StatelessWidget {
  final DeviceHealthSummaryEntity? deviceHealth;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const DeviceHealthWidget({
    super.key,
    this.deviceHealth,
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
                  text: 'Device Health',
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
          if (isLoading && deviceHealth == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          /// DATA
          else if (deviceHealth != null) ...[
            const SizedBox(height: 24),

            /// TOP SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  /// TOTAL DEVICES
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.router_outlined,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FusionAppText(
                                text: deviceHealth!.totalDevices.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: context.colorScheme.elevation6,
                                ),
                              ),
                              FusionAppText(
                                text: 'Total Devices',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.colorScheme.elevation6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// HEALTH BAR
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildHealthBar(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// STATUS CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildHealthCard(
                    context,
                    deviceHealth!.healthyDevicesCount.toString(),
                    'Healthy',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildHealthCard(
                    context,
                    deviceHealth!.warningDevicesCount.toString(),
                    'Warning',
                    Colors.orange,
                    Icons.warning,
                  ),
                  _buildHealthCard(
                    context,
                    deviceHealth!.criticalDevicesCount.toString(),
                    'Critical',
                    Colors.red,
                    Icons.error,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// INCIDENT CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildIncidentCard(
                      context,
                      deviceHealth!.incidentsLast7Days,
                      '7 Days',
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildIncidentCard(
                      context,
                      deviceHealth!.incidentsLast30Days,
                      '30 Days',
                      Colors.cyan,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),

            /// 🔥 ADD THIS BLOCK HERE
            if (deviceHealth!.topDeviceModels.isNotEmpty) ...[
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: context.colorScheme.elevation3),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FusionAppText(
                  text: 'Top Device Models',
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
                child: _buildDeviceModelsChart(context),
              ),
            ],

            const SizedBox(height: 24),
          ]
          /// EMPTY
          else
            Expanded(
              child: Center(
                child: FusionAppText(
                  text: 'No device data available',
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

  /// HEALTH BAR
  Widget _buildHealthBar(BuildContext context) {
    final total = deviceHealth!.totalDevices.toDouble();
    final healthy = deviceHealth!.healthyDevicesCount / total;
    final warning = deviceHealth!.warningDevicesCount / total;
    final critical = deviceHealth!.criticalDevicesCount / total;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (healthy > 0)
                Expanded(
                  flex: (healthy * 100).round(),
                  child: Container(color: Colors.green),
                ),
              if (warning > 0)
                Expanded(
                  flex: (warning * 100).round(),
                  child: Container(color: Colors.orange),
                ),
              if (critical > 0)
                Expanded(
                  flex: (critical * 100).round(),
                  child: Container(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legend(context, 'Healthy', Colors.green),
            _legend(context, 'Warning', Colors.orange),
            _legend(context, 'Critical', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        FusionAppText(
          text: text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: context.colorScheme.elevation6,
          ),
        ),
      ],
    );
  }

  /// HEALTH CARD
  Widget _buildHealthCard(
    BuildContext context,
    String count,
    String label,
    Color accent,
    IconData icon,
  ) {
    return SizedBox(
      width: 120,
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
                fontSize: 18,
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

  /// INCIDENT CARD
  Widget _buildIncidentCard(
    BuildContext context,
    int count,
    String label,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_outlined, color: accent, size: 18),
          const SizedBox(height: 10),
          FusionAppText(
            text: count.toString(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.elevation6,
            ),
          ),
          FusionAppText(
            text: 'Incidents ($label)',

            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.colorScheme.elevation6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceModelsChart(BuildContext context) {
    final maxCount = deviceHealth!.topDeviceModels.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );

    return Column(
      children: deviceHealth!.topDeviceModels.entries.take(5).map((entry) {
        final percentage = maxCount == 0 ? 0 : entry.value / maxCount;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// NAME + COUNT
              Row(
                children: [
                  Expanded(
                    child: FusionAppText(
                      text: entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.colorScheme.elevation6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FusionAppText(
                    text: entry.value.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.elevation6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              /// BAR
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation3,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: percentage.toDouble(),
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
