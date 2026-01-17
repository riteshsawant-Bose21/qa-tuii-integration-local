import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? assetPath;
  final Widget? trailing;

  const SectionHeader({required this.title, this.trailing, super.key, this.assetPath});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'section_header_$title'),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
          bottom: BorderSide(width: 1, color: context.colorScheme.primaryBlack),
          ),
        ),
        child: Row(
          children: <Widget>[
            if (assetPath != null && assetPath!.isNotEmpty) ...<Widget>[
              FusionImage.asset(
                assetPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
            ],

            Expanded(
              child: FusionAppText(
                text: title,
                style: Theme.of(context).textTheme.bodySmall,
                maxLine: 1,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
