import 'package:flutter/material.dart';

class DeviceTableHeader extends StatelessWidget {
  const DeviceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        children: [

          /// DEVICE
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // SizedBox(width: 42), // image space
                // SizedBox(width: 12), // gap after image
                Text(
                  "Device",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          /// PROJECT
          Expanded(
            flex: 2,
            child: Text(
              "Project",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// LOCATION
          Expanded(
            flex: 2,
            child: Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// STATUS
          Expanded(
            flex: 2,
            child: Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// ACTION COLUMN SPACE
          SizedBox(width: 24), // matches icon width area
        ],
      ),
    );
  }
}