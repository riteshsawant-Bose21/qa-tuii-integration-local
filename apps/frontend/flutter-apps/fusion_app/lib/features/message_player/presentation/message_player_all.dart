import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/message_player/models/message_view_model.dart';
import 'package:fusion_app/features/message_player/widgets/message_player_view_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MessagePlayerView extends StatefulWidget {
  final bool showAppbar;
  const MessagePlayerView({super.key,this.showAppbar=true});

  @override
  State<MessagePlayerView> createState() => _MessagePlayerViewState();
}

class _MessagePlayerViewState extends State<MessagePlayerView> {
  final List<MessageViewModel> list = [
    MessageViewModel(
      title: "Message Player 1",
      showCard: true,
    ),
    MessageViewModel(title: "Message Player 2"),
    MessageViewModel(title: "Message Player 3"),
    MessageViewModel(title: "Message Player 4"),
    MessageViewModel(title: "Message Player 5"),
    MessageViewModel(title: "Message Player 6"),
    MessageViewModel(title: "Message Player 7"),
  ];

  int indexSelected = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: widget.showAppbar ? CommonAppBar(
          title: "Message Player"
        ):null,
        body: ListView.builder(
          itemCount: list.length,
            itemBuilder: (context,int index){
          return MessagePlayerViewItem(
            onTap: (){
              indexSelected = index;
              Navigator.pushNamed(
                  context,
                  Routes.messagePlayerPlayingPage,
                  arguments: {'title': list[index].title}
              );
              // setState(() {
              //
              // });
            },
            title: list[index].title,
            showActiveCard: index == indexSelected,
          );
        }
        ),
      ),
    );
  }
}