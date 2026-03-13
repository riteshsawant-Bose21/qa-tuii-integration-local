import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/dashboard/presentation/pages/home_screen.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/stat_item_card.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/stat_item_card_new.dart';
import 'package:fusion_lib/fusion_lib.dart';
class StatsSection extends StatelessWidget {

   StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<StatsCardModel> items = [
      StatsCardModel(title: 'Total Devices',value: 25,
          bgColor:context.colorScheme.zone1Fill,
          icon: Icons.monitor,
          route: Routes.devicePage),
      StatsCardModel(title: 'Total Zones',value: 7,
          bgColor:context.colorScheme.zone3Fill,
          icon: Icons.zoom_in_map_rounded,route: Routes.zonePage),
    ];
    return GridView.builder(
      padding: EdgeInsets.only(left: 16,right: 16),
      itemCount: items.length,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,      // columns
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,   // square items
      ),
      itemBuilder: (context, index) {
        StatsCardModel item = items[index];

        return  showData ? DashStatCardNEw(data: item) : DashStatCard(data: item);
      },
    );

  }

}

class StatsCardModel {
  final String title;
  final IconData icon;
  final int value;
  final String? route;
  final Color? bgColor;


  StatsCardModel(
      {required this.title,required this.bgColor, required this.icon, required this.value,this.route});

}