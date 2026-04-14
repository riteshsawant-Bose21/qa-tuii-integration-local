import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ActiveMessageCard extends StatelessWidget {
  const ActiveMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          border: Border.all(color: context.colorScheme.elevation2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            /// Stop Button Circle
            FusionContainer(
              borderRadius: 24,
              raised: true,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: context.colorScheme.elevation1,
                child: Icon(Icons.stop,color: context.colorScheme.iconWhite,size: 24),
              ),
            ),
            const SizedBox(width: 16),

            /// Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Morning ...",
                    style: Theme.of(context).textTheme.b3SemiBold.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Reception",
                    style: Theme.of(context).textTheme.l1Regular.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colorScheme.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}