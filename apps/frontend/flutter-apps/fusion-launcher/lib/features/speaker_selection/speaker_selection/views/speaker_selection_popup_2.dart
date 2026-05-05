import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../add_output_device_drawer/viewmodel/add_output_device_vm.dart';
import '../../../create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import '../../../create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';
import '../../../speaker_selection_popup/views/widgets/constant_enums.dart';
import '../viewmodel/speaker_selection_vm.dart';
import 'widgets/stepped_both_side_haptic_slider.dart';
import 'widgets/stepped_haptic_slider.dart';

part 'widgets/left_content.dart';
part 'widgets/right_content.dart';

class SpeakerSelectionPopup2 extends StatelessWidget {
  final bool isFromBuildingPage;
  const SpeakerSelectionPopup2({super.key, required this.isFromBuildingPage});

  static Future<void> show({required BuildContext context, required bool isFromBuildingPage}) {
    return FusionDrawer.show<void>(
      context: context,
      semanticId: 'speaker_selection',
      title: 'SPEAKERS',
      width: 836,
      scrollable: false,
      content: SpeakerSelectionPopup2(
        isFromBuildingPage: isFromBuildingPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpeakerSelectionViewModel>(
      create: (BuildContext context) => SpeakerSelectionViewModel(isFromBuildingPage: isFromBuildingPage),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
        color: context.colorScheme.elevation1,
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left Panel - Speaker Configuration
            Expanded(child: SpeakerSelectionLeftContent()),

            SizedBox(width: 10),

            // Right Panel - Speaker Selection
            Expanded(child: SpeakerSelectionRightContent()),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: title,
      style: context.textTheme.l1Medium.copyWith(
        color: context.colorScheme.textPrimary,
      ),
    );
  }
}
