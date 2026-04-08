import 'package:flutter/material.dart';
import 'package:fusion_app/features/events/presentation/events_screen.dart';
import 'package:fusion_app/features/message_player/presentation/message_player_all.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/bottom_app_bar.dart';
import 'package:fusion_app/features/snapshots/presentation/snapshots_screen.dart';
import 'package:fusion_app/features/zones/presentation/controller_zone.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../models/control_pal_model.dart' show BottomNavItemModel;

enum ControlPalTab { zones, snapshots, events, messages }

extension ControlPalTabExtension on ControlPalTab {
  String get title {
    switch (this) {
      case ControlPalTab.zones:
        return "Zones";
      case ControlPalTab.snapshots:
        return "Snapshots";
      case ControlPalTab.events:
        return "Events";
      case ControlPalTab.messages:
        return "Messages";
    }
  }
}

class ControlPalScreen extends StatefulWidget {
  const ControlPalScreen({super.key});

  @override
  State<ControlPalScreen> createState() => _ControlPalScreenState();
}

class _ControlPalScreenState<T> extends State<ControlPalScreen> {

  ValueNotifier<ControlPalTab> _selectedTab = ValueNotifier(ControlPalTab.zones);

  final List<BottomNavItemModel> bottomNavItems = [
    const BottomNavItemModel(
      selected: ControlPalTab.zones,
      icon: Icons.square_outlined,
      label: "Zones",
    ),
    const BottomNavItemModel(
      selected: ControlPalTab.snapshots,
      icon: Icons.schema,
      label: "Snapshots",
    ),
    const BottomNavItemModel(
      selected: ControlPalTab.events,
      icon: Icons.calendar_today,
      label: "Events",
    ),
    const BottomNavItemModel(
      selected: ControlPalTab.messages,
      icon: Icons.messenger_outline,
      label: "Messages",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      bottom: false,
      child:  ValueListenableBuilder<ControlPalTab>(
          valueListenable: _selectedTab,
          builder: (_, current, __) {
          return Scaffold(
            appBar: CommonAppBar( title: _selectedTab.value.title,leadingIcon: SizedBox.shrink()),
            backgroundColor: context.colorScheme.primaryBlack,
              body: _buildTabContent(),
            bottomNavigationBar: CommonBottomNavigation(selectedTab: _selectedTab, bottomNavItems: bottomNavItems),
          );
        }
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab.value) {
      case ControlPalTab.zones:
        return  ControllerZones();
      case ControlPalTab.snapshots:
        return   SnapshotsScreen();
      case ControlPalTab.events:
        return  EventsScreen(showAppbar: false);
      case ControlPalTab.messages:
        return  MessagePlayerView(showAppbar: false);
    }
  }

}



