// --- 2. MAIN DASHBOARD ---

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'zone_control_widget.dart';
import 'package:fusion_lib/fusion_theme/color_scheme.dart';
import 'package:fusion_lib/models/project_entities/zone_model.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../dashboard_section_header.dart';

class ZoneDashboard extends StatelessWidget {
  const ZoneDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring we are using the colors correctly
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: scheme.elevation1,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: scheme.elevation2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          // TODO: implement listener
        },
        builder: (BuildContext context, ProjectViewModelState state) {
          return Column(
            children: <Widget>[
              const DashboardSectionHeader(
                title: 'ZONES',
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: serviceLocator<ProjectViewModel>().zones.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Zone zone = serviceLocator<ProjectViewModel>().zones[index];
                    return ZoneControlCard(
                      zone: zone,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
