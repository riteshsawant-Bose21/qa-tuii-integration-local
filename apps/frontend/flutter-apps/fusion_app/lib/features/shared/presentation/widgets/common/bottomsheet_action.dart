import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';
class FusionConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? content;
  final IconData icon;
  final Color? iconBackgroundColor;
  final List<FusionBottomSheetButton> buttons;

  const FusionConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttons,
     this.content,
    this.icon = Icons.question_mark,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBackgroundColor ??
                  context.colorScheme.zone1Fill,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 32,
              color: context.colorScheme.primaryBlack,
            ),
          ),

          const SizedBox(height: 24),

          /// Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.h5Bold.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          /// Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.l1Regular.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textBody,
            ),
          ),

          if (content != null) ...[
            const SizedBox(height: 24),
            content!,
          ],

          const SizedBox(height: 24),

          /// Dynamic Buttons
          Row(
            children: buttons
                .map(
                  (btn) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: CustomButton(
                    bottomPadding: 0,
                    padding: EdgeInsets.zero,
                    enabled: ValueNotifier(true),
                    backGroundColor: btn.isPrimary
                        ? null
                        : Colors.transparent,
                    buttonText: btn.text,
                    onPressed: btn.onPressed,
                  ),
                )
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}
class FusionBottomSheetButton {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool enabled;

  const FusionBottomSheetButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.enabled = true,
  });
}