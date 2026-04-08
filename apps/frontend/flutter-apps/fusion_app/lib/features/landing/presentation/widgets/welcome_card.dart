
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return  RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Welcome,",
            style: Theme.of(context).textTheme.h5RegularMobile.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textPrimary,
            ),
          ),
          TextSpan(
            text: "Steve",
            style: Theme.of(context).textTheme.h5BoldMobile.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.textPrimary
            ),
          ),
        ],
      ),
    );
  }
}

