import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class HardwareComponentProperties extends StatefulWidget {
  final HardwareComponent selectedHardware;

  const HardwareComponentProperties({
    super.key,
    required this.selectedHardware,
  });

  @override
  State<HardwareComponentProperties> createState() => _HardwareComponentPropertiesState();
}

class _HardwareComponentPropertiesState extends State<HardwareComponentProperties> {
  final TextEditingController gainController = TextEditingController();

  final TextEditingController pitchController = TextEditingController();
  final TextEditingController yawController = TextEditingController();
  final TextEditingController rollController = TextEditingController();

  final TextEditingController xController = TextEditingController();

  final TextEditingController yController = TextEditingController();

  final TextEditingController zController = TextEditingController();

  //dispose controllers
  @override
  void dispose() {
    gainController.dispose();
    pitchController.dispose();
    yawController.dispose();
    rollController.dispose();
    xController.dispose();
    yController.dispose();
    zController.dispose();
    super.dispose();
  }

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
        gainController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).gain.toString() : '0.0';
        pitchController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).pitch.toString() : '0.0';
        yawController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).yaw.toString() : '0.0';
        rollController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).roll.toString() : '0.0';
        xController.text = widget.selectedHardware.pos.dx.toStringAsFixed(2);
        yController.text = widget.selectedHardware.pos.dy.toStringAsFixed(2);
        zController.text = widget.selectedHardware.zAxis.toStringAsFixed(2);

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Hardware header section with icon, name and price
              Row(
                children: <Widget>[
                  // Speaker image from selected hardware assetPath
                  Image.asset(
                    widget.selectedHardware.assetImagePath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.selectedHardware.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${widget.selectedHardware.price.toStringAsFixed(2)}',
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
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      viewModel.removeHardware(widget.selectedHardware.id);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Hardware name input field
              TextFormField(
                initialValue: widget.selectedHardware.name,
                decoration: const InputDecoration(
                  hintText: 'Hardware Name',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onFieldSubmitted: (String v) {
                  final HardwareComponent updated = widget.selectedHardware.copyWith(name: v);
                  viewModel.updateHardware(updated);
                },
              ),

              const SizedBox(height: 10),

              // Coordinates section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Position',
                    style: textStyleGrey?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Text("X", style: textStyleGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextFormField(
                                controller: xController,
                                decoration: const InputDecoration(
                                  hintText: 'X',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? xValue = double.tryParse(v);
                                  if (xValue != null) {
                                    final HardwareComponent updated = widget.selectedHardware.copyWith(pos: Offset(xValue, widget.selectedHardware.pos.dy));
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Text("Y", style: textStyleGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextFormField(
                                controller: yController,
                                decoration: const InputDecoration(
                                  hintText: 'Y',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? yValue = double.tryParse(v);
                                  if (yValue != null) {
                                    final HardwareComponent updated = widget.selectedHardware.copyWith(pos: Offset(widget.selectedHardware.pos.dx, yValue));
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Text("Z", style: textStyleGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextFormField(
                                controller: zController,
                                decoration: const InputDecoration(
                                  hintText: 'Z',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? zValue = double.tryParse(v);
                                  if (zValue != null) {
                                    final HardwareComponent updated = widget.selectedHardware.copyWith(zAxis: zValue);
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (widget.selectedHardware is Speaker) ...<Widget>[
                const SizedBox(height: 16),

                // Pitch field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: Text("Pitch", style: textStyleGrey?.copyWith(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: pitchController,
                                decoration: const InputDecoration(
                                  hintText: 'Pitch',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? pitch = double.tryParse(v);
                                  if (pitch != null) {
                                    final Speaker updated = (widget.selectedHardware as Speaker).copyWith(pitch: pitch);
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Yaw field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: Text("Yaw", style: textStyleGrey?.copyWith(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: yawController,
                                decoration: const InputDecoration(
                                  hintText: 'Yaw',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? yaw = double.tryParse(v);
                                  if (yaw != null) {
                                    final Speaker updated = (widget.selectedHardware as Speaker).copyWith(yaw: yaw);
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Roll field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: Text("Roll", style: textStyleGrey?.copyWith(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: rollController,
                                decoration: const InputDecoration(
                                  hintText: 'Roll',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? roll = double.tryParse(v);
                                  if (roll != null) {
                                    final Speaker updated = (widget.selectedHardware as Speaker).copyWith(roll: roll);
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Gain field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: Text("Gain", style: textStyleGrey?.copyWith(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: gainController,
                                decoration: const InputDecoration(
                                  hintText: 'Gain',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? gain = double.tryParse(v);
                                  if (gain != null) {
                                    final Speaker updated = (widget.selectedHardware as Speaker).copyWith(gain: gain);
                                    viewModel.updateHardware(updated);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Properties section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 12),
                  _buildHardwarePropertyRow(
                    context: context,
                    label: "Listening Area",
                    value: viewModel.getListeningAreaForHardware(widget.selectedHardware.id)?.name ?? "N/A",
                    options: viewModel.listeningAreas.map((ListeningArea listeningArea) => listeningArea.name).toList(),
                    onOptionSelected: (int selectedIndex) {
                      final ListeningArea? selectedArea = viewModel.listeningAreas.isNotEmpty ? viewModel.listeningAreas[selectedIndex] : null;
                      if (selectedArea != null) {
                        print("Selected Area: ${selectedArea.name}");
                        final LocationModel updated = widget.selectedHardware.locationEntity.copyWith(
                          listeningAreaId: selectedArea.id,
                        );
                        viewModel.updateHardwareLocation(widget.selectedHardware.id, updated);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildHardwarePropertyTextRow(
                    context: context,
                    label: "Color",
                    value: "Black",
                  ),
                  const SizedBox(height: 8),
                  _buildHardwarePropertyTextRow(
                    context: context,
                    label: "Type",
                    value: "Ceiling",
                  ),
                  const SizedBox(height: 8),
                  _buildHardwarePropertyTextRow(
                    context: context,
                    label: "Impedance",
                    value: "Low",
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
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
                  const SizedBox(width: 6),
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

  /// Builds a text row displaying a property label and its value.
  Widget _buildHardwarePropertyTextRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
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
          // Right: Value
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
