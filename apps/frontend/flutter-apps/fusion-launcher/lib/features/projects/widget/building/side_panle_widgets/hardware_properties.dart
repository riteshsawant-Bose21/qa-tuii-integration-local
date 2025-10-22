import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class HardwareComponentProperties extends StatefulWidget {
  final HardwareComponent selectedHardware;
  final VoidCallback? onSpeakerParametersChanged;

  const HardwareComponentProperties({
    super.key,
    required this.selectedHardware,
    this.onSpeakerParametersChanged,
  });

  @override
  State<HardwareComponentProperties> createState() => _HardwareComponentPropertiesState();
}

class _HardwareComponentPropertiesState extends State<HardwareComponentProperties> {
  final TextEditingController gainController = TextEditingController();

  final TextEditingController rollController = TextEditingController();
  final TextEditingController pitchController = TextEditingController();
  final TextEditingController yawController = TextEditingController();

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

        // Divide by 100 for display
        xController.text = (widget.selectedHardware.pos.dx / 100).toStringAsFixed(2);
        yController.text = (widget.selectedHardware.pos.dy / 100).toStringAsFixed(2);
        zController.text = (widget.selectedHardware.zAxis / 100).toStringAsFixed(2);

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
                      viewModel.removeHardware(hardwareId: widget.selectedHardware.id);
                    },
                  ),
                ],
              ),

              // Hardware name input field
              TextFormField(
                initialValue: widget.selectedHardware.name,
                maxLength: 24,
                decoration: const InputDecoration(
                  counterText: "",
                  hintText: 'Hardware Name',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onFieldSubmitted: (String v) {
                  // Validate that the name is not empty or just whitespace
                  final String trimmedName = v.trim();
                  if (trimmedName.isNotEmpty) {
                    final HardwareComponent updated = widget.selectedHardware.copyWith(name: trimmedName);
                    viewModel.updateHardware(hardware: updated);
                  } else {
                    // Show a snackbar to inform user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hardware name cannot be empty'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

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
                            IntrinsicWidth(
                              child: TextFormField(
                                controller: xController,
                                maxLength: 24,
                                decoration: const InputDecoration(
                                  counterText: "",
                                  hintText: 'X',
                                  border: InputBorder.none,
                                  suffixText: "m",
                                  isDense: true,
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? xValue = double.tryParse(v.trim());
                                  if (xValue != null) {
                                    // Multiply by 100 when submitting
                                    final HardwareComponent updated = widget.selectedHardware.copyWith(
                                      pos: Offset(xValue * 100, widget.selectedHardware.pos.dy),
                                    );
                                    viewModel.updateHardware(hardware: updated);
                                    if (widget.selectedHardware is Speaker) {
                                      widget.onSpeakerParametersChanged?.call();
                                    }
                                  } else {
                                    // Reset to previous value if invalid
                                    xController.text = (widget.selectedHardware.pos.dx / 100).toStringAsFixed(2);
                                    // Show validation error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('X position must be a valid decimal number'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
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
                            IntrinsicWidth(
                              child: TextFormField(
                                controller: yController,
                                maxLength: 24,
                                decoration: const InputDecoration(
                                  counterText: "",
                                  hintText: 'Y',
                                  border: InputBorder.none,
                                  isDense: true,
                                  suffixText: "m",
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? yValue = double.tryParse(v.trim());
                                  if (yValue != null) {
                                    // Multiply by 100 when submitting
                                    final HardwareComponent updated = widget.selectedHardware.copyWith(
                                      pos: Offset(widget.selectedHardware.pos.dx, yValue * 100),
                                    );
                                    viewModel.updateHardware(hardware: updated);
                                    if (widget.selectedHardware is Speaker) {
                                      widget.onSpeakerParametersChanged?.call();
                                    }
                                  } else {
                                    // Reset to previous value if invalid
                                    yController.text = (widget.selectedHardware.pos.dy / 100).toStringAsFixed(2);
                                    // Show validation error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Y position must be a valid decimal number'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
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
                            IntrinsicWidth(
                              child: TextFormField(
                                controller: zController,
                                maxLength: 24,
                                decoration: const InputDecoration(
                                  counterText: "",
                                  hintText: 'Z',
                                  border: InputBorder.none,
                                  isDense: true,
                                  suffixText: "m",
                                ),
                                style: textStyleBlack,
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (String v) {
                                  final double? zValue = double.tryParse(v.trim());
                                  if (zValue != null) {
                                    // Multiply by 100 when submitting
                                    final HardwareComponent updated = widget.selectedHardware.copyWith(zAxis: zValue * 100);
                                    viewModel.updateHardware(hardware: updated);
                                    if (widget.selectedHardware is Speaker) {
                                      widget.onSpeakerParametersChanged?.call();
                                    }
                                  } else {
                                    // Reset to previous value if invalid
                                    zController.text = (widget.selectedHardware.zAxis / 100).toStringAsFixed(2);
                                    // Show validation error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Z position must be a valid decimal number'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
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

                // Roll field
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 80,
                      child: Text("Roll", style: textStyleGrey?.copyWith(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: rollController,
                        decoration: const InputDecoration(
                          hintText: 'Roll',
                          border: InputBorder.none,
                          isDense: true,
                          suffixText: "°",
                        ),
                        style: textStyleBlack,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (String v) {
                          final double? roll = double.tryParse(v.trim());
                          if (roll != null) {
                            final Speaker updated = (widget.selectedHardware as Speaker).copyWith(roll: roll);
                            viewModel.updateHardware(hardware: updated);
                            widget.onSpeakerParametersChanged?.call();
                          } else {
                            // Reset to previous value if invalid
                            rollController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).roll.toString() : '0.0';
                            // Show validation error
                            // Trigger SPL update for speaker orientation changes
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Roll must be a valid decimal number'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Pitch field
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 80,
                      child: Text("Pitch", style: textStyleGrey?.copyWith(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: pitchController,
                        decoration: const InputDecoration(
                          hintText: 'Pitch',
                          border: InputBorder.none,
                          isDense: true,
                          suffixText: "°",
                        ),
                        style: textStyleBlack,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (String v) {
                          final double? pitch = double.tryParse(v.trim());
                          if (pitch != null) {
                            final Speaker updated = (widget.selectedHardware as Speaker).copyWith(pitch: pitch);
                            viewModel.updateHardware(hardware: updated);
                            widget.onSpeakerParametersChanged?.call();
                          } else {
                            // Reset to previous value if invalid
                            pitchController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).pitch.toString() : '0.0';
                            // Show validation error
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pitch must be a valid decimal number'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Yaw field
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 80,
                      child: Text("Yaw", style: textStyleGrey?.copyWith(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: yawController,
                        decoration: const InputDecoration(
                          hintText: 'Yaw',
                          border: InputBorder.none,
                          isDense: true,
                          suffixText: "°",
                        ),
                        style: textStyleBlack,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (String v) {
                          final double? yaw = double.tryParse(v.trim());
                          if (yaw != null) {
                            final Speaker updated = (widget.selectedHardware as Speaker).copyWith(yaw: yaw);
                            viewModel.updateHardware(hardware: updated);
                            widget.onSpeakerParametersChanged?.call();
                          } else {
                            // Reset to previous value if invalid
                            yawController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).yaw.toString() : '0.0';
                            // Show validation error
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Yaw must be a valid decimal number'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Gain field
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 80,
                      child: Text("Gain", style: textStyleGrey?.copyWith(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          IntrinsicWidth(
                            child: TextFormField(
                              controller: gainController,
                              decoration: const InputDecoration(
                                hintText: 'Gain',
                                border: InputBorder.none,
                                isDense: true,
                                suffixText: "dB",
                              ),
                              style: textStyleBlack,
                              keyboardType: TextInputType.number,
                              onFieldSubmitted: (String v) {
                                final double? gain = double.tryParse(v.trim());
                                if (gain != null) {
                                  final Speaker updated = (widget.selectedHardware as Speaker).copyWith(gain: gain);
                                  viewModel.updateHardware(hardware: updated);
                                  widget.onSpeakerParametersChanged?.call();
                                } else {
                                  // Reset to previous value if invalid
                                  gainController.text = widget.selectedHardware is Speaker ? (widget.selectedHardware as Speaker).gain.toString() : '0.0';
                                  // Show validation error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gain must be a valid decimal number'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
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

              // Properties section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (widget.selectedHardware.lockListeningArea) ...<Widget>[
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              // Left: Label
                              FusionAppText(
                                text: "Area",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
                                ),
                              ),
                              // Right: Value + Arrow
                              Tooltip(
                                message: "Listening area is locked",
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FusionAppText(
                                        text: viewModel.getListeningAreaForHardware(hardwareId: widget.selectedHardware.id)?.name ?? "N/A",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...<Widget>[
                        Expanded(
                          child: _buildHardwarePropertyRow(
                            context: context,
                            label: "Area ",
                            value: viewModel.getListeningAreaForHardware(hardwareId: widget.selectedHardware.id)?.name ?? "N/A",
                            options:
                                widget.selectedHardware.lockListeningArea
                                    ? <String>[]
                                    : viewModel.listeningAreas.map((ListeningArea listeningArea) => listeningArea.name).toList(),
                            onOptionSelected: (int selectedIndex) {
                              if (!widget.selectedHardware.lockListeningArea) {
                                final ListeningArea? selectedArea = viewModel.listeningAreas.isNotEmpty ? viewModel.listeningAreas[selectedIndex] : null;
                                if (selectedArea != null) {
                                  print("Selected Area: ${selectedArea.name}");
                                  final LocationModel updated = widget.selectedHardware.locationEntity.copyWith(
                                    listeningAreaId: selectedArea.id,
                                  );
                                  viewModel.updateHardwareLocation(hardwareId: widget.selectedHardware.id, newLocation: updated);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Lock Listening Area",
                        child: GestureDetector(
                          onTap: () {
                            viewModel.updateHardware(
                              hardware: widget.selectedHardware.copyWith(
                                lockListeningArea: !widget.selectedHardware.lockListeningArea,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: widget.selectedHardware.lockListeningArea ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.selectedHardware.lockListeningArea ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.selectedHardware.lockListeningArea ? Icons.lock : Icons.lock_open,
                              size: 16,
                              color: widget.selectedHardware.lockListeningArea ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
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
