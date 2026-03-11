import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/presentation/handlers/devices_action_handler.dart';
import 'package:fusion_web/features/devices/presentation/widgets/status_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/devices_model.dart';

class DeviceRow extends StatelessWidget {
  final Device device;
  final bool isLast;

  const DeviceRow({super.key, required this.device, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        hoverColor: Colors.grey[100],
        onTap: () {
          DeviceActionsHandler.viewDetails(context: context, device: device);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
                          Text(
                            device.name,
                            softWrap: true,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "ID: ${device.deviceId}",
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[500],
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
                child: Text(
                  device.project,
                  style: GoogleFonts.montserrat(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// LOCATION
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.location),
                    Text(
                      device.type,
                      style: TextStyle(color: Colors.grey[500]),
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
                          child: Text(
                            "${device.incidents} incident${device.incidents > 1 ? 's' : ''}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case "view":
                      DeviceActionsHandler.viewDetails(
                        context: context,
                        device: device,
                      );
                      break;

                    case "download":
                      DeviceActionsHandler.downloadReport(
                        context: context,
                        device: device,
                      );
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
                        Text("View Details"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "download",
                    enabled: false,
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined),
                        SizedBox(width: 8),
                        Text("Download Report"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
