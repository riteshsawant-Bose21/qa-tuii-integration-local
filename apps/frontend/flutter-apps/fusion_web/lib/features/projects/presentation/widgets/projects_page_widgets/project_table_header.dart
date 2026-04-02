import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class ProjectTableHeader extends StatelessWidget {
  const ProjectTableHeader({super.key});


          
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
              color: Colors.transparent,

        // color: Colors.grey[50],
      // color: context.colorScheme.onSurface.withValues(alpha: 0.05),
        // borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: context.colorScheme.elevation3)),
      ),
      child: Row(
        children: [
          /// PROJECT
          Expanded(
            flex: 3,
            child: FusionAppText(
              text: 'project',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 12),

          /// client name
          Expanded(
            flex: 2,
            child: FusionAppText(
              text: 'client',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 12),

          /// PHASE (renamed)
          Expanded(
            flex: 2,
            child: FusionAppText(
              text: 'Phase',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 12),

          /// STATUS
          SizedBox(
            width: 70,
            child: FusionAppText(
              text: 'Status',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 12),

          /// INCIDENTS
          Expanded(
            flex: 2,
            child: FusionAppText(
              semanticId: 'incidents_header',
              text: 'Incidents',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 12),

          /// HEALTH
          Expanded(
            flex: 2,
            child: FusionAppText(
              semanticId: 'health_header',
              text: 'Health',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 12),

          /// UPDATED
          SizedBox(
            width: 70,
            child: FusionAppText(
              text: 'Updated',
              style: context.textTheme.labelLarge
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
