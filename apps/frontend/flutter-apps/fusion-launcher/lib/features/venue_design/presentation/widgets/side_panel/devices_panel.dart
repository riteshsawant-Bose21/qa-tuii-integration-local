import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class DevicesPanel extends StatelessWidget {
  const DevicesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SpeakerData speakerData = const SpeakerData(
      assetPath: 'assets/images/speakers/DM_pendant.png',
      name: 'DesignMax DM6PE',
      sku: 'MSA12XOHS',
      type: OutputType.analogOutput,
      price: 700.0,
    );
    return Column(
      children: <Widget>[
        _buildSubItem(
          Icons.speaker_outlined,
          hasAddButton: true,
          'Loudspeaker',
          onTap: () {
            final Speaker speaker = Speaker(
              name: speakerData.name,
              speakerSKU: speakerData.sku,
              gain: 0,
              pos: Offset.zero,
              rotation: 0.0,
              assetImagePath: speakerData.assetPath,
              type: speakerData.type,
              locationEntity: LocationModel(
                floorId: serviceLocator<ProjectViewModel>().currentFloor.id,
              ),
              price: speakerData.price,
            );
            serviceLocator<ProjectViewModel>().addHardware(speaker);
          },
        ),
        _buildSubItem(Icons.mic_outlined, 'Sources'),
        _buildSubItem(Icons.tune_outlined, 'Controls'),
        _buildSubItem(Icons.hub_outlined, 'Endpoints'),
        _buildSubItem(Icons.dns_outlined, 'Racks'),
      ],
    );
  }

  Widget _buildSubItem(IconData icon, String title, {bool hasAddButton = false, Function()? onTap}) {
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
          if (onTap != null) {
            onTap();
          }
          // Handle item tap
          print('Tapped on $title');
        },
      ),
    );
  }
}
