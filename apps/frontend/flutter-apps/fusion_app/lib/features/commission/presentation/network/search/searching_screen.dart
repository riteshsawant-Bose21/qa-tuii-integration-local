import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class SearchingScreen extends StatelessWidget {
  const SearchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:  [
          Spacer(flex: 2,),
          // 🔍 Search Icon
          Icon(
            Icons.search,
            size: 33,
            color: colorScheme.iconWhite,
          ),

          Spacer(flex: 1),

          // 🔹 Title
          Text(
            'Hold on, searching for Fusion system',
            textAlign: TextAlign.center,
            style:  Theme.of(context).textTheme.b2SemiBold!.copyWith(
              fontWeight: FontWeight.w600,
              color:  colorScheme.textPrimary,
            ),
          ),

          SizedBox(height: 8),

          // 🔹 Subtitle
          Text(
            'Make sure you are connected to right network',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.l1Regular!.copyWith(
              fontWeight: FontWeight.w400,
              color:  colorScheme.textSecondary,
            ),
          ),
          Spacer(flex: 2,),
        ],
      ),
    );
  }
}
