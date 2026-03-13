import 'package:fusion_app/features/events/models/event_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/bottomsheet_action.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionContainer;
import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/neumorphic_button.dart';

class EventCard extends StatefulWidget {
   EventModel event;
   Color? bgColor;
   EventCard({
    super.key,
    required this.event,
    this.bgColor
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final ValueNotifier<bool> controller = ValueNotifier(false);
  
  @override
  void initState() {
    controller.value = widget.event.enabled;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: widget.bgColor ?? context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: widget.event.accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 4),
                  padding: EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: widget.bgColor ?? context.colorScheme.elevation1,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  //padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.event.time.split(" ").first,
                                    style:Theme.of(context).textTheme.b3Regular.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: context.colorScheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 5,),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.sunny_snowing,
                                        color: context.colorScheme.onPrimary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        widget.event.time.split(" ").last,
                                        style:Theme.of(context).textTheme.l1Regular.copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: context.colorScheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              VerticalDivider(color: context.colorScheme.textPrimary,thickness: 10,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.event.title,
                                    style:Theme.of(context).textTheme.b3SemiBold.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colorScheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.event.subtitle,
                                    style:Theme.of(context).textTheme.l1Regular.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: context.colorScheme.textSecondary,
                                    ),
                                  ),
                                ],
                              )

                            ],
                          ),

                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          if(widget.event.showSwitchIcon)
            ValueListenableBuilder<bool>(
                valueListenable: controller,
                builder: (context, mode, _) {
                  return FusionSwitch(
                    height: 30,
                    width: 50,
                    radiusFactor: 0.35,
                    value: controller.value,
                    onChanged: (bool value) {
                      controller.value=value;
                      // EventModel model = widget.event.copyWith(enabled: value);
                      //
                      // widget.event = model;

                    },
                  );
                }
            ),
          if(widget.event.showDeleteIcon)
            GestureDetector(
            onTap: (){

              EventModel model = widget.event.copyWith(showDeleteIcon: false,showSwitchIcon: false);

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) {
                  return FusionConfirmationBottomSheet(
                    title: "Are you sure?",
                    subtitle:
                    "Are you sure you want to skip the upcoming event\nYoga Session",
                    content: EventCard(
                      event: model,
                      bgColor: context.colorScheme.elevation2,
                    ),
                    buttons: [
                      FusionBottomSheetButton(
                        text: "Cancel",
                        onPressed: () => Navigator.pop(context),
                      ),
                      FusionBottomSheetButton(
                        text: "Skip Session",
                        isPrimary: true,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: SizedBox(
              height: 40,
                width: 40,
                child: FusionContainer(
                  raised: true,
                  child: Icon(
                  Icons.close,
                  color: context.colorScheme.iconWhite,
                  size: 20,
                ),)),
          ),
          SizedBox(width: 16,)
        ],
      ),
    );
  }
}
