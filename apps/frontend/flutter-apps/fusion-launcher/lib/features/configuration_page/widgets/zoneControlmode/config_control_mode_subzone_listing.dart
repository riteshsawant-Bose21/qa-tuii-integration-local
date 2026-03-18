import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../control_dashboard/presentation/widgets/zones/subzone_dashboard_content.dart';

class ConfigControlModeSubzoneListing extends StatelessWidget {
  final List<SubZone> subZones;

  const ConfigControlModeSubzoneListing({
    super.key,
    required this.subZones,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        ),
      ),
      child: Column(
        children: <Widget>[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subZones.length,
            itemBuilder: (BuildContext context, int index) {
              final SubZone subZone = subZones[index];
              final bool isLastItem = index == subZones.length - 1;
              return SubzoneDashboardContent(
                subZone: subZone,
                isLast: isLastItem,
              );
            },
          ),
        ],
      ),
    );
  }
}
