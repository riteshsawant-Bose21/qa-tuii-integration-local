import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class CoveragePanel extends StatefulWidget {
  const CoveragePanel({super.key});

  @override
  CoveragePanelState createState() => CoveragePanelState();
}

class CoveragePanelState extends State<CoveragePanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.grey[50],
      child: Column(
        children: <Widget>[
          _buildSubItem(
            Icons.volume_up_outlined,
            'Listening Area',
            onTap: () {
              serviceLocator<ProjectViewModel>().setListeningAreaSelectionMode(!serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode);
            },
            hasAddButton: true,
          ),
          _buildSubItem(
            Icons.layers_outlined,
            'Zone',
            hasAddButton: true,
            onTap: () {
              print(" Zone tapped");
              serviceLocator<ProjectViewModel>().setZoneSelectionMode(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(
    IconData icon,
    String title, {
    bool hasAddButton = false,
    required Function() onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        title: FusionAppText(
          text: title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        trailing:
            hasAddButton
                ? Icon(
                  Icons.add,
                  size: 18,
                  color: Colors.grey[400],
                )
                : null,
        onTap: () {
          onTap();
        },
      ),
    );
  }
}
