import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/event_card.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/header_section_card.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/message_player_card.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/section_notification.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/section_stats.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/wall_controller_card.dart';
import 'package:fusion_app/features/notification/models/notification_model.dart';
import 'package:fusion_app/features/notification/presentation/notification_screen.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/box_state_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_lib/fusion_lib.dart';

bool showData=false;
class DashboardScreen extends StatelessWidget {

   DashboardScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Dashboard'),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              if(showData)
              HomeHeaderSection(
                  title: 'Notifications',
                  child: NotificationsSection()
              ),
              HomeHeaderSection(
                  title: 'Devices and Zones',
                  child:  StatsSection()
              ),
              const SizedBox(height: 12),
              if(!showData)
                BoxStateCard(
                  icon: Icons.router_outlined,
                  title: "System not commissioned",
                  description:
                  "This system hasn’t been configured yet. Please complete the initial configuration before proceeding.",
                  buttonText: "Configure Now",
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.configureNetwork);
                  },
                ),
              if(showData)...[
                HomeWallControllerCard(title: 'Wall Controllers', subtitle: 'View Wall Controllers or Scan QR',),
              SizedBox(height: 12,),
              HomeHeaderSection(
                  title: 'Events',
                  showViewAll: true,
                  viewAllTap: (){
                    Navigator.pushNamed(
                        context,
                        Routes.eventPage
                    );

                  },
                  child: DashboardEventCard(dateLabel: 'Today / 24 July, 2025 / 5:00pm', title: 'System Shutdown', subtitle: 'Conference on Global Heat Wave',)
              ),
                SizedBox(height: 12,),
               HomeHeaderSection(
                    title: 'Message Player',
                    showViewAll: true,
                    viewAllTap: (){
                      Navigator.pushNamed(
                          context,
                          Routes.messagePlayerViewPage
                      );
                    },
                    child: MessagePlayerCard(
                      dateLabel: 'MESSAGE PLAYER 1',
                      title: 'Morning...',
                      subtitle: 'Now playing',)
                ),
            ]
            ],
          ),
        ),
      ),
    );
  }
}



