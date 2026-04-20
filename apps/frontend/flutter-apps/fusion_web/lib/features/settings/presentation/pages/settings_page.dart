import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/theme/theme_cubit.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:http/http.dart';

enum SettingsTab {
  profile,
  appearance,
  network,
  behavior,
  projectDefaults,
  support,
  about,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  //Language & Appearance
  String _selectedLanguage = "English";
  // String _selectedTheme = "Dark";
  //Behavior
  String _startupOption = "Open last project";
  String _autoSaveOption = "Every 5 minutes";
  bool _inAppNotifications = true;
  bool _emailNotifications = false;
  String _autoUpdate = "Automatic update";
  // Network
  bool _isEditingNetwork = false;
  String _apiUrl = "https://api.fusion.com";
  String _environment = "Production";
  final TextEditingController _apiController = TextEditingController(
    text: "https://api.fusion.com",
  );
  //project defaults
  String _saveLocation = "Local directory";
  String _localPath = "/user/projects";
  String _region = "India";

  SettingsTab _selectedTab = SettingsTab.profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// EXISTING HEADER
          const PageHeader(
            title: 'Settings',
            subtitle: 'This is a Settings page',
          ),

          const SizedBox(height: 20),

          /// NEW TABS (added below header)
          _tabs(),
          // _optionsRows(),

          const SizedBox(height: 20),

          /// TAB CONTENT
          Expanded(child: _tabContent()),
        ],
      ),
    );
  }

  /// ---------------- TABS ----------------
  Widget _tabs() {
    return Row(
      children: [
        _tabButton("My Profile", SettingsTab.profile),
        const SizedBox(width: 8),
        _tabButton("Language & Appearance", SettingsTab.appearance),
        const SizedBox(width: 8),
        _tabButton("Network", SettingsTab.network),
        const SizedBox(width: 8),
        _tabButton("Behavior", SettingsTab.behavior),
        const SizedBox(width: 8),
        _tabButton("Project Defaults", SettingsTab.projectDefaults),
        const SizedBox(width: 8),
        _tabButton("Support & Diagnostics", SettingsTab.support),
        const SizedBox(width: 8),
        _tabButton("About", SettingsTab.about),
      ],
    );
  }

  Widget _optionsRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        _clickableRow("My Profile", "/profile"),
        SizedBox(height: 10),
        _clickableRow("Language & Appearance", "/appearance"),
        SizedBox(height: 10),
        _clickableRow("Network", "/network"),
        SizedBox(height: 10),
        _clickableRow("Behavior", "/behavior"),
        SizedBox(height: 10),
        _clickableRow("Project Defaults", "/project-defaults"),
        SizedBox(height: 10),
        _clickableRow("Support & Diagnostics", "/support"),
        SizedBox(height: 10),
        _clickableRow("About", "/about"),
      ],
    );
  }

  Widget _tabButton(String text, SettingsTab tab) {
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

  /// ---------------- TAB CONTENT ----------------
  Widget _tabContent() {
    switch (_selectedTab) {
      case SettingsTab.profile:
        return _profileTab();
      case SettingsTab.appearance:
        return _appearanceTab();
      case SettingsTab.network:
        return _networkTab();
      case SettingsTab.behavior:
        return _behaviorTab();
      case SettingsTab.projectDefaults:
        return _projectDefaultsTab();
      case SettingsTab.support:
        return _supportTab();
      case SettingsTab.about:
        return _aboutTab();
    }
  }

  /// TEMP CONTENT CARD (you can expand later)
  Widget _simpleCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FusionAppText(text: text),
    );
  }

  Widget _appearanceTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -------- LANGUAGE --------
          FusionAppText(
            text: "Language",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _radioOption("English"),
              _radioOption("Japanese"),
              _radioOption("Mandarin"),
              _radioOption("German"),
              _radioOption("French"),
              _radioOption("Spanish"),
              _radioOption("UAE Arabic"),
            ],
          ),

          const SizedBox(height: 32),

          /// -------- APPEARANCE --------
          FusionAppText(
            text: "Appearance",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _themeOption("Light"),
              const SizedBox(width: 20),
              _themeOption("Dark"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _radioOption(String label) {
    return InkWell(
      onTap: () => setState(() => _selectedLanguage = label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: label,
            groupValue: _selectedLanguage,
            onChanged: (val) {
              setState(() => _selectedLanguage = val!);
            },
          ),
          FusionAppText(text: label),
        ],
      ),
    );
  }

  Widget _themeOption(String label) {
    final themeMode = context.watch<ThemeCubit>().state;

    final isSelected =
        (label == "Dark" && themeMode == ThemeMode.dark) ||
        (label == "Light" && themeMode == ThemeMode.light);

    return InkWell(
      onTap: () {
        if (label == "Dark") {
          context.read<ThemeCubit>().setDark();
        } else {
          context.read<ThemeCubit>().setLight();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool>(
            value: label == "Dark",
            groupValue: themeMode == ThemeMode.dark,
            onChanged: (_) {
              if (label == "Dark") {
                context.read<ThemeCubit>().setDark();
              } else {
                context.read<ThemeCubit>().setLight();
              }
            },
          ),
          FusionAppText(text: label),
        ],
      ),
    );
  }

  Widget _supportTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -------- FEEDBACK --------
          FusionAppText(
            text: "Submit Feedback / Report Issue",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () => _openFeedbackDialog(),
            child: const Text("Open"),
          ),

          const SizedBox(height: 32),

          /// -------- SYSTEM DIAGNOSTICS --------
          FusionAppText(
            text: "System Diagnostics",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: View logs logic
                },
                child: const Text("View System Logs"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: Export logs logic
                },
                child: const Text("Export for Support"),
              ),
            ],
          ),

          const SizedBox(height: 32),

          FusionAppText(
            text: "Account and Data",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: View logs logic
                },
                child: const Text("Download my data"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  // TODO: Export logs logic
                },
                child: const Text("Delete my account"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedType = "Feedback";
        TextEditingController controller = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Submit Feedback / Report Issue"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// TYPE SELECTION
                  Row(
                    children: [
                      Radio<String>(
                        value: "Feedback",
                        groupValue: selectedType,
                        onChanged: (val) => setState(() => selectedType = val!),
                      ),
                      const Text("Feedback"),

                      const SizedBox(width: 20),

                      Radio<String>(
                        value: "Issue",
                        groupValue: selectedType,
                        onChanged: (val) => setState(() => selectedType = val!),
                      ),
                      const Text("Issue"),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// INPUT FIELD
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Enter details...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: handle submit
                    Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _aboutTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Role
          _infoRow("User Role", "Reseller Admin"),
          const SizedBox(height: 20),

          /// -------- VERSION --------
          _infoRow("Application Version", "v0.5.0-1"),

          const SizedBox(height: 20),

          /// -------- LICENSE --------
          _infoRow("License / Subscription", "Pro Tier"),

          const SizedBox(height: 24),

          /// -------- DESCRIPTION --------
          FusionAppText(
            text:
                "The Fusion Web Portal is the cloud-based administrative hub for the Fusion ecosystem. It provides a unified interface for managing organizations, users, roles, projects, and analytical visibility across regions and partner networks. The platform emphasizes governance, collaboration, and insight-driven decision-making rather than low-level device operations.",
            style: TextStyle(
              fontSize: 13,
              color: context.colorScheme.elevation6,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FusionAppText(
          text: label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        FusionAppText(
          text: value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _behaviorTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Startup"),

            const SizedBox(height: 12),

            _clickableRow(
              "Open last project",
              "/projects", // your route
            ),

            const SizedBox(height: 8),

            _clickableRow(
              "Open Home Page",
              "/dashboard", // your route
            ),

            const SizedBox(height: 28),

            /// -------- AUTO SAVE --------
            _sectionTitle("Auto-save Frequency"),
            const SizedBox(height: 12),

            _radioOptionGroup(
              options: ["Automatic update", "Manual check for updates"],
              groupValue: _autoUpdate,
              onChanged: (val) => setState(() => _autoUpdate = val!),
            ),

            const SizedBox(height: 28),

            /// -------- UPDATE --------
            _sectionTitle("Update Preferences"),
            const SizedBox(height: 12),

            _radioOptionGroup(
              options: ["Automatic update", "Manual check for updates"],
              groupValue: _autoSaveOption,
              onChanged: (val) => setState(() => _autoSaveOption = val!),
            ),
            const SizedBox(height: 28),

            /// -------- NOTIFICATIONS --------
            _sectionTitle("Notification Preferences"),
            const SizedBox(height: 12),

            _toggleOption(
              "In-app alerts",
              _inAppNotifications,
              (val) => setState(() => _inAppNotifications = val),
            ),
            const SizedBox(height: 8),

            _toggleOption(
              "Email notifications",
              _emailNotifications,
              (val) => setState(() => _emailNotifications = val),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return FusionAppText(
      text: text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _radioOptionGroup({
    required List<String> options,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: options.map((option) {
        return InkWell(
          onTap: () => onChanged(option),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: option,
                groupValue: groupValue,
                onChanged: onChanged,
              ),
              FusionAppText(text: option),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _toggleOption(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FusionAppText(text: label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _clickableRow(String label, String route) {
    return InkWell(
      onTap: () {
        // Navigate
        // If using go_router:
        // context.push(route);

        // TEMP (for now)
        print("Navigate to $route");
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation3,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FusionAppText(text: label),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _networkTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -------- HEADER --------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FusionAppText(
                text: "IP Configuration",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              /// EDIT BUTTON
              TextButton(
                onPressed: () {
                  if (_isEditingNetwork) {
                    // cancel edit → reset values
                    _apiController.text = _apiUrl;
                  }
                  setState(() {
                    _isEditingNetwork = !_isEditingNetwork;
                  });
                },
                child: Text(_isEditingNetwork ? "Cancel" : "Edit"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// -------- API URL --------
          FusionAppText(text: "API Base URL"),
          const SizedBox(height: 6),

          _isEditingNetwork
              ? TextField(
                  controller: _apiController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                )
              : _infoText(_apiUrl),

          const SizedBox(height: 20),

          /// -------- ENVIRONMENT --------
          FusionAppText(text: "Environment"),
          const SizedBox(height: 6),

          _isEditingNetwork
              ? DropdownButtonFormField<String>(
                  value: _region,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ["India", "Europe", "US", "Middle East"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _region = val!);
                  },
                )
              : _infoText(_environment),

          const SizedBox(height: 24),

          /// -------- SAVE BUTTON --------
          if (_isEditingNetwork)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _apiUrl = _apiController.text;
                      _isEditingNetwork = false;
                    });

                    /// TODO: Save to backend / config
                  },
                  child: const Text("Save"),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _apiController.text = _apiUrl;
                      _isEditingNetwork = false;
                    });
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FusionAppText(text: text),
    );
  }

  Widget _projectDefaultsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -------- SAVE LOCATION --------
            _sectionTitle("Default Save Location"),
            const SizedBox(height: 12),

            _radioOptionGroup(
              options: ["Local directory", "Cloud workspace"],
              groupValue: _saveLocation,
              onChanged: (val) => setState(() => _saveLocation = val!),
            ),

            const SizedBox(height: 12),

            /// Show path only if local selected
            if (_saveLocation == "Local directory") ...[
              FusionAppText(text: "Local Directory Path"),
              const SizedBox(height: 6),
              TextField(
                controller: TextEditingController(text: _localPath),
                onChanged: (val) => _localPath = val,
                decoration: InputDecoration(
                  hintText: "/user/projects",
                  filled: true,
                  fillColor: context.colorScheme.onSurface.withValues(
                    alpha: 0.05,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            /// -------- REGION --------
            _sectionTitle("Region-Based Defaults"),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _region,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.colorScheme.onSurface.withValues(
                  alpha: 0.05,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                "India",
                "Europe",
                "US",
                "Middle East",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() => _region = val!);
              },
            ),

            const SizedBox(height: 12),

            /// -------- INFO --------
            FusionAppText(
              text:
                  "Compliance settings such as voltage standards and fire safety requirements will be applied based on the selected region.",
              style: TextStyle(
                fontSize: 13,
                color: context.colorScheme.elevation6,
              ),
            ),

            const SizedBox(height: 32),

            /// -------- ACTION BUTTONS --------
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Save logic (API / local storage)

                    print("Saved:");
                    print("Save Location: $_saveLocation");
                    print("Path: $_localPath");
                    print("Region: $_region");

                    // Optional: show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Project defaults saved")),
                    );
                  },
                  child: const Text("Save"),
                ),

                const SizedBox(width: 12),

                OutlinedButton(
                  onPressed: () {
                    // Reset values (optional)
                    setState(() {
                      _saveLocation = "Local directory";
                      _localPath = "/user/projects";
                      _region = "India";
                    });
                  },
                  child: const Text("Reset"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -------- HEADER --------
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.colorScheme.elevation3,
                child: const Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "John Doe",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text("Reseller Admin"),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          /// -------- OPTIONS --------
          _clickableRow("Personal Information", "/profile/personal"),

          const SizedBox(height: 10),

          _clickableRow("Account Credentials", "/profile/credentials"),

          const SizedBox(height: 10),

          _clickableRow("Contact & Location", "/profile/contact"),

          const SizedBox(height: 10),

          _clickableRow("Preferences", "/profile/preferences"),

          const SizedBox(height: 10),

          _clickableRow("Cost Management", "/profile/costing"),

          const SizedBox(height: 10),

          _clickableRow("Organization & Team", "/profile/Organization"),
        ],
      ),
    );
  }
}
