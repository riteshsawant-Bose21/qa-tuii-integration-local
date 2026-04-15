import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/project/presentation/configuration/sources_tab.dart';
import 'package:fusion_app/features/project/presentation/configuration/zones_tab.dart' show ZonesTabScreen;
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
enum ConfigurationTab { sources, zones }

class ConfigurationScreen extends StatefulWidget {

   const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  ConfigurationTab _selectedTab = ConfigurationTab.sources;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonAppBar(title: 'Configuration'),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            _tabs(),
            SizedBox(height: 10),
            CommonDivider(paddingValue: 16,),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case ConfigurationTab.sources:
        return  SourcesTabScreen();
      case ConfigurationTab.zones:
        return  SourcesTabScreen();
       // return  ZonesTabScreen();
    }
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabItem(
            title: 'Sources',
            isSelected: _selectedTab == ConfigurationTab.sources,
            onTap: () => setState(() {
              _selectedTab = ConfigurationTab.sources;
            }),
          ),
          const SizedBox(width: 12),
          _tabItem(
            title: 'Zones',
            isSelected: _selectedTab == ConfigurationTab.zones,
            onTap: () => setState(() {
              _selectedTab = ConfigurationTab.zones;
            }),
          ),
        ],
      ),
    );
  }

  Widget _tabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2A2A2A)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
