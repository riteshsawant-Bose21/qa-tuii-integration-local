import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Header extends StatelessWidget {
  final VoidCallback onClose;
  const Header({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.strokeLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FusionAppText(
            text: 'AES 67',
            style: context.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
          InkWell(
            onTap: onClose,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(LucideIcons.x, size: 18, color: context.colorScheme.iconDefault),
            ),
          ),
        ],
      ),
    );
  }
}
