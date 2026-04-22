import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MessagePlayerItem extends StatelessWidget {
  final String title;
  final bool playing;
  final Function? onTap;

  const MessagePlayerItem({super.key,
    required this.title,
     this.onTap,
    this.playing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: (){
            onTap!();
          },
          child: Container(
            padding:  EdgeInsets.only(left: 16,right: 16, top: 12,bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.colorScheme.elevation1,
                  child: Icon(playing ? Icons.stop : Icons.play_arrow,color: context.colorScheme.iconWhite,size: 18),
                ),
                SizedBox(width: 16,),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.b2Regular.copyWith(
                      fontWeight: FontWeight.w400,
                      color: playing ? context.colorScheme.primary : context.colorScheme.textPrimary,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        CommonDivider()
      ],
    );
  }
}