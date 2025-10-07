import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/assets_constants.dart';

class CoveragePanel extends StatefulWidget {
  final Function(bool selected) onModeSelection;

  const CoveragePanel({
    super.key,
    required this.onModeSelection,
  });

  @override
  CoveragePanelState createState() => CoveragePanelState();
}

class CoveragePanelState extends State<CoveragePanel> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return SizedBox(
          // color: Colors.grey[50],
          child: Column(
            children: <Widget>[
              _buildSubItem(
                SvgPicture.asset(
                  Assets.listeningAreaSvg,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
                'Listening Area',
                isSelected: serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode,
                onTap: () {
                  serviceLocator<ProjectViewModel>().setListeningAreaSelectionMode(!serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode);
                  widget.onModeSelection(serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode);
                },
                onAddTap: () {
                  serviceLocator<ProjectViewModel>().enterListeningAreaSelectionMode();
                },
              ),
              _buildSubItem(
                const Icon(
                  Icons.layers_outlined,
                  size: 14,
                  color: Colors.black87,
                ),
                'Zone',
                isSelected: serviceLocator<ProjectViewModel>().isInZoneSelectionMode,
                onTap: () {
                  serviceLocator<ProjectViewModel>().setZoneSelectionMode(!serviceLocator<ProjectViewModel>().isInZoneSelectionMode);
                  widget.onModeSelection(serviceLocator<ProjectViewModel>().isInZoneSelectionMode);
                },
                onAddTap: () {
                  final Zone newZone = Zone(
                    name: 'Zone ${serviceLocator<ProjectViewModel>().zones.length + 1}',
                  );
                  serviceLocator<ProjectViewModel>().addZone(newZone);
                  serviceLocator<ProjectViewModel>().enterZoneSelectionMode(newZone);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubItem(
    Widget icon,
    String title, {
    bool isSelected = false,
    required Function() onTap,
    required Function() onAddTap,
  }) {
    return Container(
      // margin: const EdgeInsets.only(bottom: 2),
      //if selected is true change background color to light blue
      color: isSelected ? Colors.grey[200] : Colors.transparent,
      child: Stack(
        children: <Widget>[
          // a black half circle on the left side of the container if selected is true
          if (isSelected)
            Container(
              width: 4,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            leading: icon,
            title: FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            trailing:
                isSelected
                    ? Visibility(
                      visible: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
                      child: IconButton(
                        onPressed: () {
                          onAddTap();
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.black87,
                        ),
                      ),
                    )
                    : null,
            onTap: () {
              onTap();
            },
          ),
        ],
      ),
    );
  }
}
