import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FusionAppText(
        text: title,
        style: context.textTheme.titleMedium?.copyWith(
          color: context.colorScheme.textBody,
          fontWeight: FontWeight.w500
        ),
      ),
    );
  }
}