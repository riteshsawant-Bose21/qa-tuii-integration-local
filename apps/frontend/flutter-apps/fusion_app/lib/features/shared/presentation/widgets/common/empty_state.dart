import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CommonEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const CommonEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Icon Circle
            CommonCircleIcon(
              icon: icon,
              size: 72,
              iconSize: 33,
              iconColor: context.colorScheme.iconDefault,
              bgColor: context.colorScheme.elevation2,
            ),

            const SizedBox(height: 24),

            /// Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.h5BoldMobile.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            /// Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.b3Regular!.copyWith(
                fontWeight: FontWeight.w400,
                color: context.colorScheme.textBody,
              ),
            ),

            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}