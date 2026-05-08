import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/CommonWidgets/create_zone_hover_text_buttton.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/CommonWidgets/create_zone_icon_text-button.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/inline_floor_dropdown.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/CommonWidgets/zone_name_field_with_color.dart';
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

class CreateZoneContent extends StatefulWidget {
  final bool isFromBuildingPage;
  final ValueNotifier<bool> saveEnabledNotifier;
  final bool autoOpenSubzone;

  const CreateZoneContent({
    super.key,
    required this.isFromBuildingPage,
    required this.saveEnabledNotifier,
    this.autoOpenSubzone = false,
  });

  @override
  State<CreateZoneContent> createState() => _CreateZoneContentState();
}

class _CreateZoneContentState extends State<CreateZoneContent> {
  void _revalidate(CreateZoneViewModelState state) {
    final bool isCreatingSubzones = state.subzones.isNotEmpty;

    if (!isCreatingSubzones) {
      widget.saveEnabledNotifier.value = state.zoneListeningAreas.isNotEmpty;
    } else {
      widget.saveEnabledNotifier.value = state.subzones.length >= 2 && state.subzones.every((AddListeningAreaToSubzoneModel s) => s.listeningAreas.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateZoneViewModel, CreateZoneViewModelState>(
      listenWhen: (CreateZoneViewModelState p, CreateZoneViewModelState c) => p.zoneListeningAreas != c.zoneListeningAreas || p.subzones != c.subzones,
      listener: (BuildContext context, CreateZoneViewModelState state) => _revalidate(state),
      child: BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
        builder: (BuildContext context, CreateZoneViewModelState state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                _CreateSubzoneWidget(
                  autoOpenSubzone: widget.autoOpenSubzone,
                  saveEnabledNotifier: widget.saveEnabledNotifier,
                  onRevalidate: () => _revalidate(context.read<CreateZoneViewModel>().state), // ← pass revalidate down
                ),
                const SizedBox(height: 20),
                if (state.subzones.isEmpty) ...<Widget>[
                  Divider(thickness: 0.5, height: 0, color: context.colorScheme.strokeLight),
                  const SizedBox(height: 12),
                  _ZoneListeningAreaSection(
                    isFromBuildingPage: widget.isFromBuildingPage,
                    subzoneIndex: null,
                    onAddingAreaChanged: (bool isAdding) {
                      if (isAdding) {
                        widget.saveEnabledNotifier.value = false;
                      } else {
                        _revalidate(context.read<CreateZoneViewModel>().state);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
