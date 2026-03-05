import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class PanelHeader extends StatelessWidget {
  final String title;

  const PanelHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        border: Border(bottom: BorderSide(color: context.colorScheme.strokeLight)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.menu, color: context.colorScheme.onSurface, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: context.colorScheme.primaryBlack),
              maxLine: 1,
            ),
          ),
        ],
      ),
    );
  }
}
