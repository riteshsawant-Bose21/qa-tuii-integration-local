import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class FloorProperties extends StatelessWidget {
  final FloorModel selectedFloor;

  const FloorProperties({
    super.key,
    required this.selectedFloor,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyleGrey = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );
    final TextStyle? textStyleBlack = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 9,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
    );
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, Object? state) {
        final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

        return Container(
          padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: TextFormField(
                      initialValue: selectedFloor.name,
                      decoration: const InputDecoration(
                        hintText: 'Floor Name',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onFieldSubmitted: (String v) {
                        final FloorModel updated = selectedFloor.copyWith(name: v);
                        viewModel.updateFloor(updated);
                      },
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 15,
                      ),
                      disabledColor: Theme.of(context).colorScheme.grey,

                      onPressed:
                          viewModel.floors.length > 1
                              ? () {
                                viewModel.removeFloor(selectedFloor.id);
                              }
                              : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              _buildHardwarePropertyTextRow(
                context: context,
                label: "Total LA",
                value: "${viewModel.getListeningAreasForFloor(selectedFloor.id).length}",
              ),
              _buildHardwarePropertyTextRow(
                context: context,
                label: "Total H/W",
                value: "${viewModel.getHardwareForFloor(selectedFloor.id).length}",
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a dropdown row displaying a property label and its selectable value.
  Widget _buildHardwarePropertyRow({
    required BuildContext context,
    required String label,
    required String value,
    List<String>? options,
    required Function(int selectedIndex) onOptionSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: (String newValue) {
        final int selectedIndex = options?.indexOf(newValue) ?? -1;
        if (selectedIndex != -1) {
          onOptionSelected(selectedIndex);
        }
      },
      constraints: const BoxConstraints(maxHeight: 600, minWidth: 200),
      padding: EdgeInsets.zero,
      offset: const Offset(50, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
      ),
      color: Theme.of(context).colorScheme.white,
      elevation: 1,
      itemBuilder: (BuildContext context) {
        if (options == null || options.isEmpty) {
          return <PopupMenuEntry<String>>[];
        }

        return options.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: FusionAppText(
              text: option,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left: Label
            FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
              ),
            ),
            // Right: Value + Arrow
            Container(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: <Widget>[
                  FusionAppText(
                    text: value,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.fusionTextViewColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a dropdown row displaying a property label and its selectable value.
  Widget _buildHardwarePropertyTextRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Left: Label
          FusionAppText(
            text: label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
            ),
          ),

          // Right: Value + Arrow
          FusionAppText(
            text: value,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
