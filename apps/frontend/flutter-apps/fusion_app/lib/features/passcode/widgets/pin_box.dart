import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PinBoxes extends StatelessWidget {
  final String pin;
  final bool hasError;

  const PinBoxes({
    super.key,
    required this.pin,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// PIN BOXES
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = index < pin.length;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 60,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError
                      ? context.colorScheme.errorText
                      : context.colorScheme.elevation2,
                  width: 1.5,
                ),
              ),
              child: filled
                  ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.colorScheme.textPrimary,
                  shape: BoxShape.circle,
                ),
              )
                  : null,
            );
          }),
        ),

        const SizedBox(height: 12),

        /// ERROR TEXT
        if (hasError)
          Container(
            width: 276,
            child: Row(
              children: [
                Text(
                  "Incorrect Passcode",
                  style: Theme.of(context).textTheme.l1Regular!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.colorScheme.errorText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}