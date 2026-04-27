import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/create_new_listening_area.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/inline_floor_dropdown.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/zone_name_field_with_color.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_app_button.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_checkbox.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/canvas/fusion_canvas_point.dart';
import 'package:fusion_lib/models/project_entities/floor_model.dart';
import 'package:fusion_lib/models/project_entities/floor_plan_model.dart';
import 'package:fusion_lib/models/project_entities/listening_area_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../view_model/create_zone_viewmodel.dart';
import '../view_model/create_zone_viewmodel_state.dart';
part 'widgets/zone_listening_area_section.dart';
part 'widgets/create_subzone_widget.dart';

class CreateZoneContent extends StatelessWidget {
  final bool isFromBuildingPage;

  const CreateZoneContent({super.key, required this.isFromBuildingPage});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
      builder: (BuildContext context, CreateZoneViewModelState state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Zone Name + Color ──────────────────────────────────────
              BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
                buildWhen: (CreateZoneViewModelState p, CreateZoneViewModelState c) => p.zoneName != c.zoneName || p.zoneColor != c.zoneColor,
                builder: (BuildContext context, CreateZoneViewModelState state) {
                  return ZoneNameFieldWithColor(
                    zoneName: state.zoneName,
                    zoneColor: state.zoneColor,
                    onNameChanged: context.read<CreateZoneViewModel>().setZoneName,
                    onColorChanged: context.read<CreateZoneViewModel>().setZoneColor,
                  );
                },
              ),
              const SizedBox(height: 20),
              // ── Add SubZones ────────────────────────────────────────────
              const _CreateSubzoneWidget(),
              const SizedBox(height: 20),
              // ── Zone-level Listening Areas ──────────────────────────────
              if (state.subzones.isEmpty) ...<Widget>[
                Divider(thickness: 0.5, height: 0, color: context.colorScheme.strokeLight),
                const SizedBox(height: 12),
                _ZoneListeningAreaSection(
                  isFromBuildingPage: isFromBuildingPage,
                  subzoneIndex: null,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
