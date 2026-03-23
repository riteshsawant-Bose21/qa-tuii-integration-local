import 'package:flutter/material.dart';

class ProjectTableHeader extends StatelessWidget {
  const ProjectTableHeader({super.key});

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
          /// PROJECT
          Expanded(
            flex: 3,
            child: Text(
              "Project",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// client name
          Expanded(
            flex: 3,
            child: Text(
              "Client",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// PHASE (renamed)
          Expanded(
            flex: 2,
            child: Text("Phase", style: TextStyle(fontWeight: FontWeight.w600)),
          ),

          SizedBox(width: 12),

          /// STATUS 
          SizedBox(
            width: 70,
            child: Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// INCIDENTS
          Expanded(
            flex: 2,
            child: Text(
              "Incidents",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// HEALTH
          Expanded(
            flex: 2,
            child: Text(
              "Health",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 12),

          /// UPDATED
         SizedBox(
            width: 70,
            child: Text(
              "Updated",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(width: 48),
        ],
      ),
    );
  }
}
