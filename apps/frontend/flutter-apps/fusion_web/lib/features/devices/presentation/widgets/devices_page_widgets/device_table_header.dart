import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class DeviceTableHeader extends StatelessWidget {
  const DeviceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: context.colorScheme.elevation3)),
      ),
      child: Row(
        children: [

          /// DEVICE
          Expanded(
            flex: 3,
            child: Row(
              children: [
                FusionAppText(
                  text: "Device",
                  style: context.textTheme.labelLarge
                ),
              ],
            ),
          ),
      

          const SizedBox(width: 12),

          /// PROJECT
          Expanded(
            flex: 2,
            child: FusionAppText(
                  text: "Project",
                  style: context.textTheme.labelLarge
                ),
          ),

          const SizedBox(width: 12),

          // /// LOCATION
          Expanded(
            flex: 2,
            child: FusionAppText(
                  text: "Location",
                  style: context.textTheme.labelLarge
                ),
          ),

          const SizedBox(width: 12),

          /// STATUS
          Expanded(
            flex: 2,
            child: FusionAppText(
                  text: "Status",
                  style: context.textTheme.labelLarge
                ),
          ),

          const SizedBox(width: 12),

          /// ACTION COLUMN SPACE
          const SizedBox(width: 48), // matches icon width area
        ],
      ),
    );
  }
}