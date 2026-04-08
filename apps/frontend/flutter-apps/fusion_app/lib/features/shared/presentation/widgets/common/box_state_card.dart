import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'circle_icon.dart';

class BoxStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onPressed;
  final Widget? action;

  const BoxStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onPressed,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colorScheme.elevation2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Icon Circle
          CommonCircleIcon(
            size: 72,
            icon:icon,
            iconColor: context.colorScheme.iconDefault,
            bgColor:context.colorScheme.elevation2,
            iconSize: 33,
          ),

          const SizedBox(height: 24),

          /// Title
          Text(
            title,
            style: Theme.of(context).textTheme.h5Bold.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          /// Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.b3Regular.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textBody,
            ),
          ),

          if (buttonText != null || action != null) ...[
            const SizedBox(height: 20),

            /// Button OR custom widget
            action ??
                CustomButton(
                  bottomPadding: 0,
                  enabled: ValueNotifier(true),
                  buttonText: buttonText!,
                  onPressed: onPressed,
                ),
          ]
        ],
      ),
    );
  }
}