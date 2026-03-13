import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class WifiBanner extends StatelessWidget {
  const WifiBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.infoFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: context.colorScheme.infoText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Join the building's Wi-Fi network to continue",
              style: Theme.of(context).textTheme.b3Regular!.copyWith(
                fontWeight: FontWeight.w400,
                color: context.colorScheme.textPrimary,
              ),
            ),
          )
        ],
      ),
    );
  }
}