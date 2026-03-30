import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_container.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/features/devices/presentation/handlers/devices_action_handler.dart';
import 'package:fusion_web/features/devices/presentation/widgets/common_widgets/status_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/devices_model.dart';

class DeviceRow extends StatelessWidget {
  final Device device;
  final bool isLast;
  final Function(Device) onTap;

  const DeviceRow({
    super.key,
    required this.device,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.elevation2,
      child: InkWell(
        hoverColor: context.colorScheme.elevation3,
        onTap: () => onTap(device),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.zero,
          ),
          child: Row(
            children: [
              /// DEVICE
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        device.image,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FusionAppText(
                            text: device.name,
                            softWrap: true,
                            style: context.textTheme.bodyMedium,
                          ),
                          FusionAppText(
                            text: "ID: ${device.deviceId}",
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: context.colorScheme.elevation6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// PROJECT
              Expanded(
                flex: 2,
                child: FusionAppText(
                  text: device.project,
                  style: context.textTheme.bodyMedium,
                ),
              ),

              const SizedBox(width: 12),

              // /// LOCATION
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FusionAppText(
                      text: device.location,
                      style: context.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// STATUS
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusIndicator(status: device.status),

                    if (device.incidents > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FusionAppText(
                            text:
                                "${device.incidents} incident${device.incidents > 1 ? 's' : ''}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == "view") {
                      onTap(device);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "view",
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined),
                          SizedBox(width: 8),
                          FusionAppText(text: "View Details"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
