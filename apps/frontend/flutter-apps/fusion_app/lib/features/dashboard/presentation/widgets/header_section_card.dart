import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class HomeHeaderSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showViewAll;
  final Function? viewAllTap;
  const HomeHeaderSection({this.title = 'Section Header',required this.child,this.viewAllTap,this.showViewAll=false,super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12,bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:  EdgeInsets.only(left: 16,right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(title, style:  context.textTheme.b3Medium.copyWith(
                     fontWeight: FontWeight.w500,
                     color: context.colorScheme.textPrimary
                 )),
                 if(showViewAll)
                 GestureDetector(
                   onTap: (){
                     viewAllTap!();
                   },
                     child:  Text('View All',
                       style: context.textTheme.l1SemiBold.copyWith(
                         fontWeight: FontWeight.w600,
                         color: context.colorScheme.textPrimary
                       )
                     )
                 ),
              ],
            ),
          ),
          SizedBox(height: 16),
          child
        ],
      ),
    );
  }
}



