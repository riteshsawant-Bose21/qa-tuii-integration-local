import 'package:flutter/material.dart';
import 'package:fusion_app/features/events/presentation/schedule_event_tab.dart';
import 'package:fusion_app/features/events/presentation/upcoming_event_tab.dart';
import 'package:fusion_app/features/events/widgets/event_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/tab_switcher.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_app/features/events/models/event_model.dart';
enum EventTab { scheduled, upcoming }

class EventsScreen extends StatefulWidget {
  final bool showAppbar;
  const EventsScreen({super.key,this.showAppbar=true});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
   EventTab _selectedTab = EventTab.scheduled;

    List<EventModel> events = [];

    List<EventModel> upcomingEvents = [];


   @override
  void initState() {

     Future.delayed(Duration(seconds: 3)).then((value) {
       if(mounted){
         events = [
           EventModel(
               time: '6:00 AM',
               title: 'Yoga Session',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '7:00 AM',
               title: 'Morning Stretch',
               subtitle: 'Studio Silver',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '8:00 AM',
               title: 'Cardio Session',
               subtitle: 'Fitness',
               accentColor: Color(0xFFF47B3A),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '9:00 AM',
               title: 'Gym Session',
               subtitle: 'Studio Platinum',
               accentColor: Color(0xFF3A6FD8),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '10:00 AM',
               title: 'Strength Training',
               subtitle: 'Power Zone',
               accentColor: Color(0xFFC878D8),
               enabled: false,
               showSwitchIcon: true
           ),
           EventModel(
               time: '11:00 AM',
               title: 'Pilates',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '12:00 PM',
               title: 'Core Workout',
               subtitle: 'Fitness',
               accentColor: Color(0xFFF47B3A),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '1:00 PM',
               title: 'Cross Training',
               subtitle: 'Studio Platinum',
               accentColor: Color(0xFF3A6FD8),
               enabled: false,
               showSwitchIcon: true
           ),
           EventModel(
               time: '2:00 PM',
               title: 'HIIT Blast',
               subtitle: 'Power Zone',
               accentColor: Color(0xFFF47B3A),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '3:00 PM',
               title: 'Mobility Flow',
               subtitle: 'Studio Silver',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '4:00 PM',
               title: 'Endurance Ride',
               subtitle: 'Cycling Arena',
               accentColor: Color(0xFF3A6FD8),
               enabled: false,
               showSwitchIcon: true
           ),
           EventModel(
               time: '5:00 PM',
               title: 'Functional Training',
               subtitle: 'Power Zone',
               accentColor: Color(0xFFC878D8),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '6:00 PM',
               title: 'Evening Yoga',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '7:00 PM',
               title: 'Zumba',
               subtitle: 'Dance Floor',
               accentColor: Color(0xFFF47B3A),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '8:00 PM',
               title: 'Boxing Basics',
               subtitle: 'Combat Zone',
               accentColor: Color(0xFF3A6FD8),
               enabled: false,
               showSwitchIcon: true
           ),
           EventModel(
               time: '9:00 PM',
               title: 'Night Burn',
               subtitle: 'Fitness',
               accentColor: Color(0xFFC878D8),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '10:00 PM',
               title: 'Late Gym',
               subtitle: 'Studio Platinum',
               accentColor: Color(0xFF3A6FD8),
               enabled: false,
               showSwitchIcon: true
           ),
           EventModel(
               time: '11:00 PM',
               title: 'Recovery Stretch',
               subtitle: 'Studio Silver',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
           EventModel(
               time: '12:00 AM',
               title: 'Midnight Cardio',
               subtitle: 'Fitness',
               accentColor: Color(0xFFF47B3A),
               enabled: false,
               showSwitchIcon: true
           ),
           EventModel(
               time: '1:00 AM',
               title: 'Flexibility Flow',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               enabled: true,
               showSwitchIcon: true
           ),
         ];
         upcomingEvents = [
           EventModel(
               time: '6:00 AM',
               title: 'Yoga Session',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               showDeleteIcon: true
           ),
           EventModel(
               time: '7:00 AM',
               title: 'Morning Stretch',
               subtitle: 'Studio Silver',
               accentColor: Color(0xFF3E996E),
               showDeleteIcon: true
           ),
           EventModel(
               time: '8:00 AM',
               title: 'Cardio Session',
               subtitle: 'Fitness',
               accentColor: Color(0xFFF47B3A),
               showDeleteIcon: true
           ),
           EventModel(
               time: '9:00 AM',
               title: 'Gym Session',
               subtitle: 'Studio Platinum',
               accentColor: Color(0xFF3A6FD8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '12:00 PM',
               title: 'Core Workout',
               subtitle: 'Fitness',
               accentColor: Color(0xFFF47B3A),
               showDeleteIcon: true
           ),
           EventModel(
               time: '1:00 PM',
               title: 'Cross Training',
               subtitle: 'Studio Platinum',
               accentColor: Color(0xFF3A6FD8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '2:00 PM',
               title: 'HIIT Blast',
               subtitle: 'Power Zone',
               accentColor: Color(0xFFF47B3A),
               showDeleteIcon: true
           ),
           EventModel(
               time: '3:00 PM',
               title: 'Mobility Flow',
               subtitle: 'Studio Silver',
               accentColor: Color(0xFF3E996E),
               showDeleteIcon: true
           ),
           EventModel(
               time: '4:00 PM',
               title: 'Endurance Ride',
               subtitle: 'Cycling Arena',
               accentColor: Color(0xFF3A6FD8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '5:00 PM',
               title: 'Functional Training',
               subtitle: 'Power Zone',
               accentColor: Color(0xFFC878D8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '6:00 PM',
               title: 'Evening Yoga',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               showDeleteIcon: true
           ),
           EventModel(
               time: '7:00 PM',
               title: 'Zumba',
               subtitle: 'Dance Floor',
               accentColor: Color(0xFFF47B3A),
               showDeleteIcon: true
           ),
           EventModel(
               time: '8:00 PM',
               title: 'Boxing Basics',
               subtitle: 'Combat Zone',
               accentColor: Color(0xFF3A6FD8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '9:00 PM',
               title: 'Night Burn',
               subtitle: 'Fitness',
               accentColor: Color(0xFFC878D8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '10:00 PM',
               title: 'Late Gym',
               subtitle: 'Studio Platinum',
               accentColor: Color(0xFF3A6FD8),
               showDeleteIcon: true
           ),
           EventModel(
               time: '11:00 PM',
               title: 'Recovery Stretch',
               subtitle: 'Studio Silver',
               accentColor: Color(0xFF3E996E),
               showDeleteIcon: true
           ),
           EventModel(
               time: '12:00 AM',
               title: 'Midnight Cardio',
               subtitle: 'Fitness',
               accentColor: Color(0xFFF47B3A),
               showDeleteIcon: true
           ),
           EventModel(
               time: '1:00 AM',
               title: 'Flexibility Flow',
               subtitle: 'Studio Gold',
               accentColor: Color(0xFF3E996E),
               showDeleteIcon: true
           ),
         ];
         setState(() {

         });
       }

     });
    super.initState();
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: widget.showAppbar ? CommonAppBar(title: 'Events') :null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CommonTabSwitcher<EventTab>(
              values: EventTab.values,
              initialValue: EventTab.scheduled,
              labelBuilder: (tab) {
                switch (tab) {
                  case EventTab.scheduled:
                    return "Scheduled";
                  case EventTab.upcoming:
                    return "Upcoming";
                }
              },
              onChanged: (tab) {
                print("Selected: $tab");
                setState(() {
                  _selectedTab = tab;
                });
              },
            ),
            const SizedBox(height: 16),
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
      case EventTab.scheduled:
        return  ScheduledEventsScreen(events: events,);
      case EventTab.upcoming:
        return  UpcomingEventsScreen(events: upcomingEvents);
    }
  }

}

