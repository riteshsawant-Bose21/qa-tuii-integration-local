import 'package:flutter/material.dart';
import 'package:fusion_app/features/message_player/models/message_view_model.dart';
import 'package:fusion_app/features/message_player/widgets/active_message_item.dart';
import 'package:fusion_app/features/message_player/widgets/message_player_item.dart';
import 'package:fusion_app/features/message_player/widgets/message_player_view_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MessagePlayerPlaying extends StatefulWidget {
    final String title;
   const MessagePlayerPlaying({super.key,required this.title});

  @override
  State<MessagePlayerPlaying> createState() => _MessagePlayerPlayingState();
}

class _MessagePlayerPlayingState extends State<MessagePlayerPlaying> {
  final List<MessageViewModel> list = [
    MessageViewModel(
      title: "Message 1",
      showCard: true,
    ),
    MessageViewModel(title: "Message 2"),
    MessageViewModel(title: "Message 3"),
    MessageViewModel(title: "Message 4"),
    MessageViewModel(title: "Message 5"),
    MessageViewModel(title: "Message 6"),
    MessageViewModel(title: "Message 7"),
  ];

  int? indexSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(
          title: widget.title
        ),
        bottomNavigationBar: indexSelected!=null ? Container(
          margin: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActiveMessageCard(),
            ],
          ),
        ):SizedBox.shrink(),
        body: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context,int index){
          return MessagePlayerItem(
            onTap: (){
              if(indexSelected == index) {
                indexSelected = null;
              }else{
                indexSelected = index;
              }


              setState(() {

              });
            },
            title: list[index].title,
            playing: index == indexSelected,
          );
        }
        ),
      ),
    );
  }
}