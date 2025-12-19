import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

import '../../../../../core/service_locator.dart';

enum SourceOption {
  singleSource("Single Source"),
  multipleSources("Multiple Sources");

  const SourceOption(this.displayName);
  final String displayName;
}

class AddSourcePopup extends StatefulWidget {
  const AddSourcePopup({super.key});

  @override
  State<AddSourcePopup> createState() => AddSourcePopupState();
}

class AddSourcePopupState extends State<AddSourcePopup> {
  @override
  Widget build(BuildContext context) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF292826),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          FusionRadio<SourceOption>(
            selected: SourceOption.singleSource,
            options: SourceOption.values,
            labelBuilder: (SourceOption option) {
              return FusionAppText(
                text: option.displayName,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              );
            },
            onChanged: (SourceOption value) {},
          ),
        ],
      ),
    );
  }
}
