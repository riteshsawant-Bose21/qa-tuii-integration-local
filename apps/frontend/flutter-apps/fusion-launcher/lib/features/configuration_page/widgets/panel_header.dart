import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class PanelHeader extends StatelessWidget {
  final String title;

  const PanelHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.menu, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.greyDark),
              maxLine: 1,
            ),
          ),
        ],
      ),
    );
  }
}
