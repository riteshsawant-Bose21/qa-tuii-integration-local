import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(left: 10),
          // color: Colors.grey[50],
          child: Column(
            children: <Widget>[
              _buildSubItem(
                Icons.volume_up_outlined,
                'Listening Area',
                isSelected: serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode,
                onTap: () {
                  serviceLocator<ProjectViewModel>().setListeningAreaSelectionMode(!serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode);
                },
              ),
              _buildSubItem(
                Icons.layers_outlined,
                'Zone',
                isSelected: serviceLocator<ProjectViewModel>().isInZoneSelectionMode,
                onTap: () {
                  serviceLocator<ProjectViewModel>().setZoneSelectionMode(!serviceLocator<ProjectViewModel>().isInZoneSelectionMode);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    required Function() onTap,
  }) {
    return Container(
      // margin: const EdgeInsets.only(bottom: 2),
      //if selected is true change background color to light blue
      color: isSelected ? Colors.blue[100] : Colors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        leading: Icon(
          icon,
          size: 14,
          color: Colors.black87,
        ),
        title: FusionAppText(
          text: title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.add,
          size: 14,
          color: Colors.black87,
        ),
        onTap: () {
          onTap();
        },
      ),
    );
  }
}
