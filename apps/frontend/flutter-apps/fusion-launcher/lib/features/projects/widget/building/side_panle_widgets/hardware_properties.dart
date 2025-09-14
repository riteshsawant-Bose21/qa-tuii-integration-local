import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class HardwareComponentProperties extends StatelessWidget {
  final HardwareComponent selectedHardware;

  HardwareComponentProperties({
    super.key,
    required this.selectedHardware,
  });

  final TextEditingController gainController = TextEditingController();
  final TextEditingController rotationController = TextEditingController();

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
        gainController.text = selectedHardware is Speaker ? (selectedHardware as Speaker).gain.toString() : '0.0';
        rotationController.text = selectedHardware is Speaker ? (selectedHardware as Speaker).rotation.toString() : '0.0';

        return Container(
          padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
          child: Column(
            children: <Widget>[
              //A Row with Speaker icon, name and price
              Row(
                children: <Widget>[
                  //Speaker image from selected hardware assetPath
                  Image.asset(
                    selectedHardware.assetImagePath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          selectedHardware.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          '\$${selectedHardware.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 15,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      viewModel.removeHardware(selectedHardware.id);
                    },
                  ),
                ],
              ),

              Row(
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: TextFormField(
                      initialValue: selectedHardware.name,
                      decoration: const InputDecoration(
                        hintText: 'Hardware Name',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onFieldSubmitted: (String v) {
                        final HardwareComponent updated = selectedHardware.copyWith(name: v);
                        viewModel.updateHardware(updated);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: <Widget>[
                        Text("X", style: textStyleGrey),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          selectedHardware.pos.dx.toStringAsFixed(2),
                          style: textStyleBlack,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Row(
                      children: <Widget>[
                        Text("Y", style: textStyleGrey),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          selectedHardware.pos.dy.toStringAsFixed(2),
                          style: textStyleBlack,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Row(
                      children: <Widget>[
                        Text("Z", style: textStyleGrey),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          "${0.0}",
                          style: textStyleBlack,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (selectedHardware is Speaker) ...<Widget>[
                const SizedBox(
                  height: 8,
                ),

                //for rotation
                Row(
                  children: <Widget>[
                    Text("Rotation", style: textStyleGrey),
                    const SizedBox(
                      width: 2,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: rotationController,
                        decoration: const InputDecoration(
                          hintText: 'Rotation',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: textStyleBlack,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (String v) {
                          final double? rotation = double.tryParse(v);
                          if (rotation != null) {
                            final Speaker updated = (selectedHardware as Speaker).copyWith(rotation: rotation);
                            viewModel.updateHardware(updated);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: <Widget>[
                    Text("Gain", style: textStyleGrey),
                    const SizedBox(
                      width: 2,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: gainController,
                        decoration: const InputDecoration(
                          hintText: 'Gain',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        style: textStyleBlack,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (String v) {
                          final double? gain = double.tryParse(v);
                          if (gain != null) {
                            final Speaker updated = (selectedHardware as Speaker).copyWith(gain: gain);
                            viewModel.updateHardware(updated);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(
                height: 8,
              ),
              _buildHardwarePropertyRow(
                context: context,
                label: "Listening Area",
                value: viewModel.getListeningAreaForHardware(selectedHardware.id)?.name ?? "N/A",
                options: viewModel.listeningAreas.map((ListeningArea listeningArea) => listeningArea.name).toList(),
                onOptionSelected: (int selectedIndex) {
                  final ListeningArea? selectedArea = viewModel.listeningAreas.isNotEmpty ? viewModel.listeningAreas[selectedIndex] : null;
                  if (selectedArea != null) {
                    print("Selected Area: ${selectedArea.name}");
                    final LocationModel updated = selectedHardware.locationEntity.copyWith(
                      listeningAreaId: selectedArea.id,
                    );
                    viewModel.updateHardwareLocation(selectedHardware.id, updated);
                  }
                },
              ),

              _buildHardwarePropertyTextRow(
                context: context,
                label: "Color",
                value: "Black",
              ),
              _buildHardwarePropertyTextRow(
                context: context,
                label: "Type",
                value: "Ceiling",
              ),
              _buildHardwarePropertyTextRow(
                context: context,
                label: "Impedance",
                value: "Low",
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
