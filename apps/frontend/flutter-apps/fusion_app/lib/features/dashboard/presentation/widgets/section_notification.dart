import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/notification/models/notification_model.dart';
import 'package:fusion_app/features/notification/widgets/notification_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NotificationsSection extends StatefulWidget {

  const NotificationsSection({super.key});

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  final double sizeReducer=0.12;

   List<AppNotification> items = [];

  @override
  void initState() {
    // TODO: implement initState

    Future.delayed(Duration(seconds: 2),(){
      items = [
        AppNotification(
          type: NotificationType.critical,
          timeLabel: 'Just now',
          title: 'Open Circuit Fault Channel',
          zone: 'Zone: Reception, Circuit: DM5SE',
          device: 'Powersmart 8300',
          location: 'Reception',
          dateTime: DateTime.now(),
        ),
        AppNotification(
          type: NotificationType.warning,
          timeLabel: '10:00 PM',
          title: 'Impedance Warning',
          zone: 'Zone: Lobby, Circuit: DM2',
          device: 'Powersmart 8300',
          location: 'Lobby',
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        ),
        AppNotification(
          type: NotificationType.neutral,
          timeLabel: '11:00 AM',
          title: 'System Check Completed',
          zone: 'All zones operational',
          device: 'Powersmart 8300',
          location: 'System',
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
        ),
      ];
      setState(() {

      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(items.isEmpty){
      return noNotification(context);
    }

    const double cardHeight = 120; // height of NotificationCard
    const double gap = 18;
    final double extraHeight =  (cardHeight/8) * (items.length-1);
    final double stackHeight = cardHeight + extraHeight;
    //
    // print("stackHeight");
    // print(stackHeight);
    // print(extraHeight);
    //print(stackHeight * (1-sizeReducer));

    return Container(
      height: stackHeight ,
      margin: EdgeInsets.only(left: 16,right: 16),
      padding: EdgeInsets.only(top: 1,bottom: 1),
      child: GestureDetector(
        onTap: (){
          Navigator.pushNamed(context, Routes.notificationPage);
        },
        child: Stack(
            fit: StackFit.expand,
          children: items.reversed.toList().asMap().entries.map((entry){
              final index = entry.key;
              final item = entry.value;
              final int lastIndex = items.length - 1;
              final double scale = (1.0 - ((lastIndex - index) * sizeReducer)).clamp(0.0, 1.0);
              //final scale = (1.0 - (index * 0.05)).clamp(0.0, 1.0);
              double top = (((items.length-1) - index )* (cardHeight/8) * 1);
              print((top*2).toString() + " index: "+ index.toString() + " scale : "+scale.toString());

              Widget card = Container();

              if((index == lastIndex  )){
               // card = getCard(item,cardHeight * scale);
                card = getCard(item,cardHeight * scale,context);
              }else{
                card = noDataCard(item.type,cardHeight * scale,context);
              }


              if(items.length == 1){
                return NotificationCard(data: item);
              }

              return Container(
                child: Positioned(
                  top: (top * 2),
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                        child: card),
                  ),
                ),
              );
            }).toList()
        ),
      ),
    );

  }

  Widget getCard(data,height,BuildContext context){

    final config = getConfig(data.type,context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonCircleIcon(
                icon: config.icon,
                iconColor: config.iconColor,
                bgColor:  config.iconBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:context.textTheme.b3Medium.copyWith(
                              fontWeight: FontWeight.w500,
                              color:config.titleColor,
                            ),
                          ),
                        ),
                        Text(
                          data.timeLabel,
                          style:context.textTheme.l2Regular.copyWith(
                            fontWeight: FontWeight.w400,
                            color:context.colorScheme.textBody,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.zone,
                      style:context.textTheme.l1Regular.copyWith(
                        fontWeight: FontWeight.w400,
                        color:context.colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
           SizedBox(height: 16),
            Text(
              "5 More Notifications".toUpperCase(),
              style:context.textTheme.l2SemiBold.copyWith(
                fontWeight: FontWeight.w600,
                color:context.colorScheme.textBody,
              ),
            ),
        ],
      ),
    );
  }

  Widget noDataCard(NotificationType type,double height,context){

    final config = getConfig(type,context);


    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.border),
      ),
    );
  }

  noNotification(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A18),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonCircleIcon(
            icon: Icons.notifications_paused_outlined,
            iconColor: context.colorScheme.iconWhite,
            bgColor:  context.colorScheme.zone5Fill,
          ),

          const SizedBox(width: 16),

          /// Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Notifications Yet',
                  style: context.textTheme.b3Bold.copyWith(
                    fontWeight: FontWeight.w700,
                    color:context.colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You're all caught up!",
                  style: context.textTheme.l1Regular.copyWith(
                    fontWeight: FontWeight.w400,
                    color:context.colorScheme.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}
