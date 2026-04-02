import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/features/devices/presentation/handlers/devices_action_handler.dart';
import 'package:fusion_web/features/devices/presentation/widgets/common_widgets/status_indicator.dart';
import '../../../data/models/devices_model.dart';

class DevicesGridView extends StatelessWidget {
  final List<Device> devices;
  final Function(Device) onDeviceTap;

  const DevicesGridView({
    super.key,
    required this.devices,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final device = devices[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            // hoverColor: Colors.grey[100],
            onTap: () => onDeviceTap(device),
            child: Container(
              decoration: BoxDecoration(
                color: context.colorScheme.elevation3,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // color: Colors.black.withOpacity(0.06),
                    // blurRadius: 12,
                    // offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      device.image,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// TITLE ROW
                          Row(
                            children: [
                              Expanded(
                                child: FusionAppText(
                                  text: device.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  switch (value) {
                                    case "view":
                                      onDeviceTap(device);
                                      break;
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
                            ],
                          ),

                          const SizedBox(height: 4),

                          /// MODEL
                          FusionAppText(
                            text: device.model,
                            style: TextStyle(
                              // color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// STATUS CHIP
                          StatusIndicator(status: device.status),

                          const SizedBox(height: 12),

                          /// DEVICE META
                          FusionAppText(
                            text: "Type: ${device.type}",
                            style: TextStyle(
                              // color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 2),

                          FusionAppText(
                            text: "Firmware: 2.1.0",
                            style: TextStyle(
                              // color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 2),

                          FusionAppText(
                            text: "Location: ${device.location}",
                            style: TextStyle(
                              // color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Divider(color: context.colorScheme.elevation6),

                          const SizedBox(height: 8),

                          /// PROJECT LINK
                          FusionAppText(
                            text: device.project,
                            style: const TextStyle(
                              // color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
