import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SearchNoResultScreen extends StatelessWidget {
  const SearchNoResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Circle Icon
            Container(
              padding: EdgeInsets.all(20),
              decoration:  BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorScheme.elevation2,
              ),
              child:  Icon(
                Icons.search_off,
                size: 40,
                color: context.colorScheme.iconDefault,
              ),
            ),

            const SizedBox(height: 28),

            /// Title
            Text(
              "No result found",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .h5BoldMobile
                  .copyWith(
                fontWeight: FontWeight.w700,
                color:
                context.colorScheme.textPrimary
              ),
            ),

            const SizedBox(height: 12),

            /// Subtitle
            Text(
              "We can’t find any projects matching your search",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .b3Regular
                  .copyWith(
                fontWeight: FontWeight.w400,
                color:
                context.colorScheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}