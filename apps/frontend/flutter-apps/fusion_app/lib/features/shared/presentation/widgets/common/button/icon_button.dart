import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class CustomOutlineIconButton extends StatelessWidget {
  final IconData icon;
  final String? buttonText;
  final ValueNotifier<bool>? enabled;
  final VoidCallback? onPressed;
  final bool isNeumorphic;
  final Color? backGroundColor;

  const CustomOutlineIconButton({
    required this.icon,
    this.buttonText,
    this.enabled,
    this.onPressed,
    this.isNeumorphic = false,
    this.backGroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isNeumorphic) {
      return FusionContainer(
        raised: true,
        child: _button(context),
      );
    }

    return _button(context);
  }

  Widget _button(BuildContext context) {
    final notifier = enabled ?? ValueNotifier(false);

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, value, _) {
          final isEnabled = value == true;

          return ElevatedButton.icon(
            onPressed: isEnabled ? onPressed : null,
            icon: Icon(
              icon,
              color: isEnabled
                  ? context.colorScheme.textPrimary
                  : context.colorScheme.textDisabled,
            ),
            label: buttonText != null
                ? Text(
              buttonText!,
              style: TextStyle(
                fontSize: context.textTheme.b2SemiBold.fontSize,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? context.colorScheme.textPrimary
                    : context.colorScheme.textDisabled,
              ),
            )
                : const SizedBox.shrink(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              backGroundColor ?? context.colorScheme.elevation2,
              disabledBackgroundColor:
              backGroundColor ?? context.colorScheme.elevation2,
              foregroundColor: context.colorScheme.elevation3,
              side: BorderSide(
                color: isNeumorphic
                    ? Colors.transparent
                    : context.colorScheme.elevation3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      ),
    );
  }
}