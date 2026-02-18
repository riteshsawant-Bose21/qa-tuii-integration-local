import 'package:flutter/material.dart';
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';

enum DetailTab { incidents, devices, activity }

class ProjectDetailPage extends StatefulWidget {
  final ProjectEntity project;
  final ProjectsViewModel viewModel;

  const ProjectDetailPage({
    super.key,
    required this.project,
    required this.viewModel,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  DetailTab _selectedTab = DetailTab.incidents;

  late ProjectsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.viewModel;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}, '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour >= 12 ? "PM" : "AM"}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    final totalDevices =
        p.healthyDevices + p.warningDevices + p.criticalDevices;

    final healthyPct = totalDevices == 0
        ? 0
        : ((p.healthyDevices / totalDevices) * 100).round();
    final warningPct = totalDevices == 0
        ? 0
        : ((p.warningDevices / totalDevices) * 100).round();
    final criticalPct = totalDevices == 0
        ? 0
        : ((p.criticalDevices / totalDevices) * 100).round();

    return Scaffold(
      body: Container(
        color: const Color(0xFFF7F7F7),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Back to Projects",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 24),
      
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _statusPill(p.status),
                            const SizedBox(width: 8),
                            _typePill("installation"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.description,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProjectActionsMenu(
                    onEdit: () => ProjectActionsHandler.edit(
                      context: context,
                      project: p,
                      viewModel: viewModel, // inject properly
                    ),
                    onInvite: () => ProjectActionsHandler.invite(
                      context: context,
                      project: p,
                    ),
                    onArchive: () => ProjectActionsHandler.archive(
                      context: context,
                      project: p,
                      viewModel: viewModel,
                    ),
                    onDelete: () => ProjectActionsHandler.delete(
                      context: context,
                      project: p,
                      viewModel: viewModel,
                    ),
                  ),
                ],
              ),
      
              const SizedBox(height: 32),
      
              // ================= CARDS =================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle("Project Details"),
                          const SizedBox(height: 24),
                          _detail("Organization", "SoundTech Solutions"),
                          _detail("Customer", p.clientName),
                          const Divider(height: 32),
                          _detail("Region", p.region),
                          const Divider(height: 32),
                          _detail("Created", "Nov 5, 2024, 06:30 PM"),
                          _detail("Last Updated", _formatDate(p.lastUpdated)),
                          const Divider(height: 32),
                          _detail("Assigned Users", "3 users"),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.people_outline, size: 16),
                              label: const Text("Manage Users"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle("Project Summary"),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _statBox("Total Devices", "$totalDevices"),
                              const SizedBox(width: 16),
                              _statBox("Open Incidents", "${p.incidents}"),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Device Health Status",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _healthTile(
                                "Healthy",
                                p.healthyDevices,
                                healthyPct,
                                Colors.green,
                              ),
                              const SizedBox(width: 12),
                              _healthTile(
                                "Warning",
                                p.warningDevices,
                                warningPct,
                                Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              _healthTile(
                                "Critical",
                                p.criticalDevices,
                                criticalPct,
                                Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      
              const SizedBox(height: 32),
      
              // ================= TABS =================
              Row(
                children: [
                  _tabButton("Incidents (${p.incidents})", DetailTab.incidents),
                  const SizedBox(width: 8),
                  _tabButton("Devices (0)", DetailTab.devices),
                  const SizedBox(width: 8),
                  _tabButton("Activity (0)", DetailTab.activity),
                ],
              ),
      
              const SizedBox(height: 24),
      
              // ================= TAB CONTENT =================
              if (_selectedTab == DetailTab.incidents) ...[
                _incidentCard(
                  "Intermittent Network Dropout",
                  "Connectivity",
                  "medium",
                  "open",
                ),
                _incidentCard(
                  "Speaker Calibration Drift",
                  "Performance",
                  "low",
                  "resolved",
                ),
                _incidentCard(
                  "Power Supply Voltage Low",
                  "Hardware",
                  "high",
                  "in_progress",
                ),
              ],
      
              if (_selectedTab == DetailTab.devices)
                _placeholder("No devices found."),
      
              if (_selectedTab == DetailTab.activity)
                _placeholder("No activity yet."),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _cardTitle(String text) => Text(
    text,
    style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500]),
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
    ),
  );

  Widget _statBox(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _healthTile(String label, int count, int pct, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 13, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$pct%",
            style: GoogleFonts.montserrat(fontSize: 12, color: color),
          ),
        ],
      ),
    ),
  );

  Widget _incidentCard(
    String title,
    String category,
    String priority,
    String status,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          _smallPill(priority),
          const SizedBox(width: 8),
          _smallPill(status),
        ],
      ),
    );
  }

  Widget _tabButton(String text, DetailTab tab) {
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

  Widget _placeholder(String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey),
    ),
  );

  Widget _statusPill(String text) => _smallPill(text);
  Widget _typePill(String text) => _smallPill(text);

  Widget _smallPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: GoogleFonts.montserrat(fontSize: 12)),
  );

  Widget _actionButton(IconData icon, String text, {bool danger = false}) =>
      OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? Colors.red : Colors.black,
        ),
      );
}
