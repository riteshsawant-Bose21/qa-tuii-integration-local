import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';

enum DeviceDetailTab { overview, incidents, activity, telemetry }

class DeviceDetailPage extends StatefulWidget {
  final String id;

  const DeviceDetailPage({super.key, required this.id});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  DeviceDetailTab _selectedTab = DeviceDetailTab.overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// BACK BUTTON
            InkWell(
              onTap: () => context.go(AppConstants.devicesRoute),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Back to Devices",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Auditorium - Line Array L",
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Serial: SM10-20001  •  ID: ${widget.id}",
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                /// STATUS PILL
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "healthy",
                        style: GoogleFonts.montserrat(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 28),

            /// TOP SUMMARY CARDS
            Row(
              children: [
                _statCard("Model", "ShowMatch SM10", "Speaker"),
                const SizedBox(width: 16),
                _statCard("Firmware Version", "2.1.0", "Up to date"),
                const SizedBox(width: 16),
                _statCard("Last Seen", "Feb 6, 2026, 02:45 PM", "Online"),
                const SizedBox(width: 16),
                _statCard("Open Incidents", "0", "0 total"),
              ],
            ),

            const SizedBox(height: 32),

            /// TABS
            Row(
              children: [
                _tabButton("Overview", DeviceDetailTab.overview),
                const SizedBox(width: 8),
                _tabButton("Incidents", DeviceDetailTab.incidents),
                const SizedBox(width: 8),
                _tabButton("Activity", DeviceDetailTab.activity),
                const SizedBox(width: 8),
                _tabButton("Telemetry", DeviceDetailTab.telemetry),
              ],
            ),

            const SizedBox(height: 24),

            if (_selectedTab == DeviceDetailTab.overview)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// DEVICE IDENTITY CARD
                  Expanded(
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle("Device Identity"),
                          const SizedBox(height: 20),

                          _detail("Name", "Auditorium - Line Array L"),
                          const SizedBox(height: 16),
                          _detail("Model Name", "ShowMatch SM10"),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                  child:
                                      _detail("Serial Number", "SM10-20001")),
                              Expanded(child: _detail("Device ID", widget.id)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _detail("Last Seen", "Feb 6, 2026, 02:45 PM"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  /// TELEMETRY CARD
                  Expanded(
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle("Device Status / Telemetry"),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              const Icon(Icons.wifi, color: Colors.green),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Online",
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _telemetryRow("Temperature", "N/A"),
                          const SizedBox(height: 16),
                          _telemetryRow("CPU Usage", "N/A"),
                          const SizedBox(height: 16),
                          _telemetryRow("RAM Usage", "N/A"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// COMPONENTS

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style:
          GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.thermostat_outlined, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.montserrat(fontSize: 14),
        )
      ],
    );
  }

  Widget _statCard(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String text, DeviceDetailTab tab) {
    final selected = _selectedTab == tab;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}