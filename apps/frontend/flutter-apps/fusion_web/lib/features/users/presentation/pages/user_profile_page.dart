import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/presentation/widgets/edit_user_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/users/presentation/widgets/user_ui_helpers.dart';

enum UserTab { projects, permissions, activity }

class UserProfilePage extends StatefulWidget {
  final UserEntity user;
  final VoidCallback? onEdit;
  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;
  final VoidCallback? onResendInvite;

  const UserProfilePage({
    super.key,
    required this.user,
    this.onEdit,
    this.onActivate,
    this.onDeactivate,
    this.onResendInvite,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late UserEntity _user;
  UserTab _selectedTab = UserTab.projects;
  final List<Map<String, dynamic>> _dummyProjects = [
    {
      "name": "Skyline Downtown Conference Center",
      "meta": "Skyline Hotels • North America • 49 devices",
      "incidents": "2 open incidents",
    },
    {
      "name": "Skyline Resort & Spa",
      "meta": "Skyline Hotels • North America • 62 devices",
      "incidents": "3 open incidents",
    },
  ];

  final List<String> _dummyPermissions = [
    "View assigned projects",
    "Manage devices in assigned projects",
    "View project analytics",
    "Submit support requests",
  ];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: context.colorScheme.elevation1,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// BACK BUTTON
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: context.colorScheme.elevation6,
                ),
                label: FusionAppText(text: "Back to Users"),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return context.colorScheme.elevation2; // hover background
                    }
                    return Colors.transparent;
                  }),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 24),

                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildUserDetailsCard()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildActivityCard()),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// 🔥 ADD THIS
                      _buildTabs(),

                      const SizedBox(height: 16),

                      /// 🔥 AND THIS
                      SizedBox(
                        width: double.infinity,
                        child: _buildTabContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = _user;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blue,
          child: FusionAppText(
            text: user.name.substring(0, 2).toUpperCase(),
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FusionAppText(
                text: user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  buildRoleChips(user.roles, context),
                  const SizedBox(width: 8),
                  buildStatusChip(user.status),
                ],
              ),
              const SizedBox(height: 6),
              FusionAppText(text: user.email),
              if (user.phone != null) FusionAppText(text: user.phone!),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: () async {
            final updatedUser = await showDialog<UserEntity>(
              context: context,
              builder: (context) => EditUserDialog(
                user: _user,
                onUpdate: (updatedUser) {
                  Navigator.pop(context, updatedUser);
                },
              ),
            );

            if (updatedUser != null) {
              setState(() {
                _user = updatedUser;
              });
            }
          },
          icon: const Icon(Icons.edit),
          label: Text(
            'Edit User',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.primaryColor,
            foregroundColor: context.colorScheme.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailsCard() {
    final user = _user;

    return _card(
      title: "User Details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row("Organization", user.organizationId ?? "-"),
          _row("Department", user.roles.join(", ")),
          _row("Location", "N/A"),
          _row("Member Since", user.createdAt.toString()),
          _row("Last Active", user.lastLoginAt?.toString() ?? "Never"),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {

    return _card(
      title: "Activity Overview",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                _statBox(
                  "Assigned Projects",
                  // user.associatedProjects.length,
                  2,
                  context.colorScheme.elevation3,
                  context.colorScheme.white,
                ),
                _statBox(
                  "Active Projects",
                  // user.associatedProjects.length,
                  2,
                  context.colorScheme.elevation3,
                  context.colorScheme.white,
                ),
                _statBox(
                  "Permissions",
                  // user.permissions.length,
                  4,
                  context.colorScheme.elevation3,
                  context.colorScheme.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const FusionAppText(
            text: "Role Permissions",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _dummyPermissions.map((p) {
              return _permissionPill(p);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FusionAppText(
            text: title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: FusionAppText(
                  text: label,
                  style: TextStyle(color: context.colorScheme.elevation6),
                ),
              ),
              Expanded(child: FusionAppText(text: value)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(String title, int value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FusionAppText(
              text: title,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 6),
            FusionAppText(
              text: "$value",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _tabButton("Projects (${_dummyProjects.length})", UserTab.projects),
        const SizedBox(width: 8),
        _tabButton("All Permissions", UserTab.permissions),
        const SizedBox(width: 8),
        _tabButton("Recent Activity", UserTab.activity),
      ],
    );
  }

  Widget _tabButton(String text, UserTab tab) {
    final selected = _selectedTab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? context.colorScheme.elevation4
                : context.colorScheme.elevation3,
          ),
        ),
        child: FusionAppText(text: text),
      ),
    );
  }

  Widget _projectsSection() {
    return _card(
      title: "Assigned Projects",
      child: Column(
        children: _dummyProjects.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colorScheme.elevation3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FusionAppText(
                        text: p["name"],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      FusionAppText(text: p["meta"]),
                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FusionAppText(
                          text: p["incidents"],
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const FusionAppText(
                    text: "active",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  
  Widget _activitySection() {
    return _card(
      title: "Recent Activity",
      child: Column(
        children: [
          _timelineItem(
            "Logged in to Fusion Web Portal",
            "February 5, 2026 at 08:00 PM",
            Icons.monitor_heart,
            Colors.blue,
          ),
          _timelineItem(
            "Updated project: Skyline Downtown Conference Center",
            "February 3, 2026 at 07:50 PM",
            Icons.folder,
            Colors.green,
          ),
          _timelineItem(
            "Updated project: Skyline Resort & Spa",
            "February 6, 2026 at 03:15 PM",
            Icons.folder,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String title, String date, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 16, color: color),
            ),
            Container(
              width: 2,
              height: 40,
              color: context.colorScheme.elevation3,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FusionAppText(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                FusionAppText(
                  text: date,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  

  Widget _permissionsSection() {
    return _card(
      title: "Complete Permission List",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _dummyPermissions.map((p) {
          return _permissionPill(p);
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case UserTab.projects:
        return _projectsSection();
      case UserTab.permissions:
        return _permissionsSection();
      case UserTab.activity:
        return _activitySection();
    }
  }

  Widget _permissionPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(999), // 🔥 pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          FusionAppText(text: text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
