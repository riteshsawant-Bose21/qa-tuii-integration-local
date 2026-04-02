import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class HardwareComponentProperties extends StatefulWidget {
  final HardwareComponent selectedHardware;
  final VoidCallback? onSpeakerParametersChanged;
  final VoidCallback? onSpeakerDeleted;

  const HardwareComponentProperties({
    super.key,
    required this.selectedHardware,
    this.onSpeakerParametersChanged,
    this.onSpeakerDeleted,
  });

  @override
  State<HardwareComponentProperties> createState() => _HardwareComponentPropertiesState();
}

class _HardwareComponentPropertiesState extends State<HardwareComponentProperties> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController gainController = TextEditingController();

  final TextEditingController rollController = TextEditingController();
  final TextEditingController pitchController = TextEditingController();
  final TextEditingController yawController = TextEditingController();

  final TextEditingController xController = TextEditingController();
  final TextEditingController yController = TextEditingController();
  final TextEditingController zController = TextEditingController();

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  bool get _isSpeaker => widget.selectedHardware is Speaker;
  Speaker? get _speaker => _isSpeaker ? widget.selectedHardware as Speaker : null;
  // - For surface speakers properties only show pitch and yaw.
  // - For ceiling/pendant speakers properties don't show any rotation properties (but keep the pitch as 90 when adding)
  bool get _rollEnabled => false;
  bool get _pitchEnabled => _speaker?.mountingType == MountingType.surface;
  bool get _yawEnabled => _speaker?.mountingType == MountingType.surface;

  //dispose controllers
  @override
  void dispose() {
    nameController.dispose();
    gainController.dispose();
    pitchController.dispose();
    yawController.dispose();
    rollController.dispose();
    xController.dispose();
    yController.dispose();
    zController.dispose();
    super.dispose();
  }

  void onHardWareNameChanged() {
    FocusScope.of(context).unfocus();
    final String v = nameController.text;

    // Validate that the name is not empty or just whitespace
    final String trimmedName = v.trim();
    if (trimmedName.isNotEmpty) {
      final HardwareComponent updated = widget.selectedHardware.copyWith(name: trimmedName);
      projectViewModel.updateHardware(hardware: updated);
    } else {
      FusionToast.error(context, message: 'Hardware name cannot be empty');
    }
  }

  void onXPositionChanged() {
    FocusScope.of(context).unfocus();
    final String v = xController.text;

    final double? xValue = double.tryParse(v.trim());
    if (xValue != null) {
      // Multiply by 100 when submitting
      final HardwareComponent updated = widget.selectedHardware.copyWith(
        pos: Offset(xValue * 100, widget.selectedHardware.pos?.dy ?? 0.0),
      );
      projectViewModel.updateHardware(hardware: updated);
      if (_isSpeaker) {
        widget.onSpeakerParametersChanged?.call();
      }
    } else {
      // Reset to previous value if invalid
      if (widget.selectedHardware.pos != null) {
        xController.text = (widget.selectedHardware.pos!.dx / 100).toStringAsFixed(2);
      }
      // Show validation error
      FusionToast.error(context, message: 'X position must be a valid decimal number');
    }
  }

  void onYPositionChanged() {
    FocusScope.of(context).unfocus();
    final String v = yController.text;

    final double? yValue = double.tryParse(v.trim());
    if (yValue != null) {
      // Multiply by 100 when submitting
      final HardwareComponent updated = widget.selectedHardware.copyWith(
        pos: Offset(
          widget.selectedHardware.pos?.dx ?? 0.0,
          yValue * 100,
        ),
      );
      projectViewModel.updateHardware(hardware: updated);
      if (_isSpeaker) {
        widget.onSpeakerParametersChanged?.call();
      }
    } else {
      // Reset to previous value if invalid
      if (widget.selectedHardware.pos != null) {
        yController.text = (widget.selectedHardware.pos!.dy / 100).toStringAsFixed(2);
      }
      // Show validation error
      FusionToast.error(context, message: 'Y position must be a valid decimal number');
    }
  }

  void onZPositionChanged() {
    FocusScope.of(context).unfocus();
    final String v = zController.text;

    final double? zValue = double.tryParse(v.trim());

    if (zValue != null) {
      // Multiply by 100 when submitting
      final HardwareComponent updated = widget.selectedHardware.copyWith(zAxis: zValue * 100);
      projectViewModel.updateHardware(hardware: updated);
      if (_isSpeaker) {
        widget.onSpeakerParametersChanged?.call();
      }
    } else {
      // Reset to previous value if invalid
      if (widget.selectedHardware.zAxis != null) {
        zController.text = (widget.selectedHardware.zAxis! / 100).toStringAsFixed(2);
      }
      // Show validation error
      FusionToast.error(context, message: 'Z position must be a valid decimal number');
    }
  }

  void onRollChanged() {
    FocusScope.of(context).unfocus();
    final String v = rollController.text;

    final double? roll = double.tryParse(v.trim());
    if (roll != null) {
      final Speaker updated = _speaker!.copyWith(roll: roll);
      projectViewModel.updateHardware(hardware: updated);
      widget.onSpeakerParametersChanged?.call();
    } else {
      // Reset to previous value if invalid
      rollController.text = _speaker?.roll.toString() ?? '0.0';
      // Show validation error
      // Trigger SPL update for speaker orientation changes
      FusionToast.error(context, message: 'Roll must be a valid decimal number');
    }
  }

  void onPitchChanged() {
    FocusScope.of(context).unfocus();
    final String v = pitchController.text;

    final double? pitch = double.tryParse(v.trim());
    if (pitch != null) {
      final Speaker updated = _speaker!.copyWith(pitch: pitch);
      projectViewModel.updateHardware(hardware: updated);
      widget.onSpeakerParametersChanged?.call();
    } else {
      // Reset to previous value if invalid
      pitchController.text = _isSpeaker ? _speaker!.pitch.toString() : '0.0';
      FusionToast.error(context, message: 'Pitch must be a valid decimal number');
    }
  }

  void onYawChanged() {
    FocusScope.of(context).unfocus();
    final String v = yawController.text;

    final double? yaw = double.tryParse(v.trim());
    if (yaw != null) {
      final Speaker updated = _speaker!.copyWith(yaw: yaw);
      projectViewModel.updateHardware(hardware: updated);
      widget.onSpeakerParametersChanged?.call();
    } else {
      // Reset to previous value if invalid
      yawController.text = _isSpeaker ? _speaker!.yaw.toString() : '0.0';
      FusionToast.error(context, message: 'Yaw must be a valid decimal number');
    }
  }

  void onGainChanged() {
    FocusScope.of(context).unfocus();
    final String v = gainController.text;

    final double? gain = double.tryParse(v.trim());
    if (gain != null) {
      final Speaker updated = _speaker!.copyWith(gain: gain);
      projectViewModel.updateHardware(hardware: updated);
      widget.onSpeakerParametersChanged?.call();
    } else {
      // Reset to previous value if invalid
      gainController.text = _isSpeaker ? _speaker!.gain.toString() : '0.0';
      FusionToast.error(context, message: 'Gain must be a valid decimal number');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyleGrey = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );

    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, Object? state) {
        nameController.text = widget.selectedHardware.name;
        gainController.text = _speaker?.gain.toString() ?? '0.0';
        pitchController.text = _speaker?.pitch.toString() ?? '0.0';
        yawController.text = _speaker?.yaw.toString() ?? '0.0';
        rollController.text = _speaker?.roll.toString() ?? '0.0';

        // Divide by 100 for display

        if (widget.selectedHardware.pos != null) {
          xController.text = (widget.selectedHardware.pos!.dx / 100).toStringAsFixed(2);
          yController.text = (widget.selectedHardware.pos!.dy / 100).toStringAsFixed(2);
        }

        if (widget.selectedHardware.zAxis != null) {
          zController.text = (widget.selectedHardware.zAxis! / 100).toStringAsFixed(2);
        }

        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "hardware_properties_panel"),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Hardware header section with icon, name and price
                Row(
                  children: <Widget>[
                    // Speaker image from selected hardware assetPath
                    SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, "hardware_image"),
                      child: FusionImage.asset(
                        widget.selectedHardware.assetImagePath,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: widget.selectedHardware.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            // overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          FusionAppText(
                            text: '\$${widget.selectedHardware.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.textPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "delete_hardware"),
                      child: IconButton(
                        icon: const Icon(LucideIcons.trash200, size: 18, color: Colors.red),
                        onPressed: () {
                          final bool isSpeaker = _isSpeaker;
                          projectViewModel.removeHardware(hardwareId: widget.selectedHardware.id);
                          if (isSpeaker) {
                            widget.onSpeakerDeleted!();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hardware name input field
                SemanticHelper.formControl(
                  testId: SemanticHelper.createTestId(SemanticTypes.textInput, "hardware_name_edit"),
                  child: PropertyTextField(
                    controller: nameController,
                    hintText: 'Hardware Name',
                    onSubmitted: (String p0) => onHardWareNameChanged(),
                    onTapOutside: (PointerDownEvent event) => onHardWareNameChanged(),
                  ),
                ),
                const SizedBox(height: 16),

                // Coordinates section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: 'Position(in meters)',
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
                              FusionAppText(text: "X :", style: textStyleGrey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: SemanticHelper.formControl(
                                  testId: SemanticHelper.createTestId(SemanticTypes.textInput, "x_position_input"),
                                  child: PropertyTextField(
                                    controller: xController,
                                    maxLength: 24,
                                    hintText: 'X',
                                    keyboardType: TextInputType.number,
                                    onTapOutside: (PointerDownEvent event) => onXPositionChanged(),
                                    onSubmitted: (String p0) => onXPositionChanged(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              FusionAppText(text: "Y :", style: textStyleGrey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: SemanticHelper.formControl(
                                  testId: SemanticHelper.createTestId(SemanticTypes.textInput, "y_position_input"),
                                  child: PropertyTextField(
                                    controller: yController,
                                    maxLength: 24,
                                    hintText: 'Y',
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (String p0) => onYPositionChanged(),
                                    onTapOutside: (PointerDownEvent event) => onYPositionChanged(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              FusionAppText(text: "Z :", style: textStyleGrey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: SemanticHelper.formControl(
                                  testId: SemanticHelper.createTestId(SemanticTypes.textInput, "z_position_input"),
                                  child: PropertyTextField(
                                    controller: zController,
                                    maxLength: 24,
                                    hintText: 'Z',
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (String p0) => onZPositionChanged(),
                                    onTapOutside: (PointerDownEvent event) => onZPositionChanged(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (_isSpeaker) ...<Widget>[
                  const SizedBox(height: 16),

                  // Roll field
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: FusionAppText(
                          text: "Roll",
                          style: textStyleGrey?.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IntrinsicWidth(
                        child: Opacity(
                          opacity: _rollEnabled ? 1.0 : 0.6,
                          child: IgnorePointer(
                            ignoring: !_rollEnabled,
                            child: SemanticHelper.formControl(
                              testId: SemanticHelper.createTestId(SemanticTypes.textInput, "roll"),
                              child: PropertyTextField(
                                controller: rollController,
                                hintText: 'Roll',
                                keyboardType: TextInputType.number,
                                suffixText: "°",
                                onSubmitted: (String p0) => onRollChanged(),
                                onTapOutside: (PointerDownEvent event) => onRollChanged(),
                              ),
                            ),
                          ),
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
                        child: FusionAppText(
                          text: "Pitch",
                          style: textStyleGrey?.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IntrinsicWidth(
                        child: Opacity(
                          opacity: _pitchEnabled ? 1.0 : 0.6,
                          child: IgnorePointer(
                            ignoring: !_pitchEnabled,
                            child: SemanticHelper.formControl(
                              testId: SemanticHelper.createTestId(SemanticTypes.textInput, "pitch"),
                              child: PropertyTextField(
                                controller: pitchController,
                                hintText: 'Pitch',
                                suffixText: "°",
                                keyboardType: TextInputType.number,
                                onTapOutside: (PointerDownEvent event) => onPitchChanged(),
                                onSubmitted: (String p0) => onPitchChanged(),
                              ),
                            ),
                          ),
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
                        child: FusionAppText(
                          text: "Yaw",
                          style: textStyleGrey?.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IntrinsicWidth(
                        child: Opacity(
                          opacity: _yawEnabled ? 1.0 : 0.6,
                          child: IgnorePointer(
                            ignoring: !_yawEnabled,
                            child: SemanticHelper.formControl(
                              testId: SemanticHelper.createTestId(SemanticTypes.textInput, "yaw"),
                              child: PropertyTextField(
                                controller: yawController,
                                hintText: 'Yaw',
                                suffixText: "°",
                                keyboardType: TextInputType.number,
                                onTapOutside: (PointerDownEvent event) => onYawChanged(),
                                onSubmitted: (String p0) => onYawChanged(),
                              ),
                            ),
                          ),
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
                        child: FusionAppText(
                          text: "Gain",
                          style: textStyleGrey?.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            IntrinsicWidth(
                              child: SemanticHelper.formControl(
                                testId: SemanticHelper.createTestId(SemanticTypes.textInput, "gain"),
                                child: PropertyTextField(
                                  controller: gainController,
                                  hintText: 'Gain',
                                  suffixText: "dB",
                                  keyboardType: TextInputType.number,
                                  onTapOutside: (PointerDownEvent event) => onGainChanged(),
                                  onSubmitted: (String p0) => onGainChanged(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // const SizedBox(height: 12),

                  // if (serviceLocator<ProjectViewModel>().getZoneForHardware(hardwareId: widget.selectedHardware.id) != null ||
                  //     serviceLocator<ProjectViewModel>().getSubZoneForHardware(hardwareId: widget.selectedHardware.id) != null)
                  //   _CircuitSelection(
                  //     speaker:  _speaker ,
                  //   ),
                ],

                // Properties section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 12),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: <Widget>[
                    //     if (widget.selectedHardware.lockListeningArea) ...<Widget>[
                    //       Expanded(
                    //         child: Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: <Widget>[
                    //             // Left: Label
                    //             FusionAppText(
                    //               text: "Area",
                    //               style: Theme.of(
                    //                 context,
                    //               ).textTheme.bodySmall?.copyWith(
                    //                 fontSize: 11,
                    //                 color: Theme.of(context).colorScheme.textPrimary.withOpacity(0.5),
                    //               ),
                    //             ),
                    //             // Right: Value + Arrow
                    //             Tooltip(
                    //               message: "Listening area is locked",
                    //               child: Container(
                    //                 alignment: Alignment.centerLeft,
                    //                 child: Row(
                    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                   children: <Widget>[
                    //                     FusionAppText(
                    //                       text:
                    //                           viewModel
                    //                               .getListeningAreaForHardware(
                    //                                 hardwareId: widget.selectedHardware.id,
                    //                               )
                    //                               ?.name ??
                    //                           "N/A",
                    //                       textAlign: TextAlign.left,
                    //                       style: Theme.of(
                    //                         context,
                    //                       ).textTheme.bodySmall?.copyWith(
                    //                         fontSize: 11,
                    //                       ),
                    //                     ),
                    //                     const SizedBox(width: 6),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ] else ...<Widget>[
                    //       Expanded(
                    //         child: _buildHardwarePropertyRow(
                    //           context: context,
                    //           label: "Area ",
                    //           value:
                    //               viewModel
                    //                   .getListeningAreaForHardware(
                    //                     hardwareId: widget.selectedHardware.id,
                    //                   )
                    //                   ?.name ??
                    //               "N/A",
                    //           options:
                    //               widget.selectedHardware.lockListeningArea
                    //                   ? <String>[]
                    //                   : projectViewModel.listeningAreas
                    //                       .map(
                    //                         (ListeningArea listeningArea) => listeningArea.name,
                    //                       )
                    //                       .toList(),
                    //           onOptionSelected: (int selectedIndex) {
                    //             if (!widget.selectedHardware.lockListeningArea) {
                    //               final ListeningArea? selectedArea = projectViewModel.listeningAreas.isNotEmpty ? projectViewModel.listeningAreas[selectedIndex] : null;
                    //               if (selectedArea != null) {
                    //                 print("Selected Area: ${selectedArea.name}");
                    //                 final LocationModel updated = widget.selectedHardware.locationEntity.copyWith(
                    //                   listeningAreaId: selectedArea.id,
                    //                 );
                    //                 projectViewModel.updateHardwareLocation(
                    //                   hardwareId: widget.selectedHardware.id,
                    //                   newLocation: updated,
                    //                 );
                    //               }
                    //             }
                    //           },
                    //         ),
                    //       ),
                    //     ],
                    //     const SizedBox(width: 8),
                    //     Tooltip(
                    //       message: "Lock Listening Area",
                    //       child: GestureDetector(
                    //         onTap: () {
                    //           projectViewModel.updateHardware(
                    //             hardware: widget.selectedHardware.copyWith(
                    //               lockListeningArea: !widget.selectedHardware.lockListeningArea,
                    //             ),
                    //           );
                    //         },
                    //         child: SemanticHelper.toggle(
                    //           value: widget.selectedHardware.lockListeningArea,
                    //           testId: SemanticHelper.createTestId(SemanticTypes.toggle, "lock_listening_area_toggle"),
                    //           child: Container(
                    //             padding: const EdgeInsets.all(6),
                    //             decoration: BoxDecoration(
                    //               color:
                    //                   widget.selectedHardware.lockListeningArea
                    //                       ? Theme.of(
                    //                         context,
                    //                       ).colorScheme.primary.withOpacity(0.1)
                    //                       : Colors.transparent,
                    //               borderRadius: BorderRadius.circular(4),
                    //               border: Border.all(
                    //                 color: widget.selectedHardware.lockListeningArea ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                    //                 width: 1,
                    //               ),
                    //             ),
                    //             child: Icon(
                    //               widget.selectedHardware.lockListeningArea ? Icons.lock : Icons.lock_open,
                    //               size: 16,
                    //               color: widget.selectedHardware.lockListeningArea ? Theme.of(context).colorScheme.primary : Colors.grey,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
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
          ),
        );
      },
    );
  }

  /// Builds a text row displaying a property label and its value.
  Widget _buildHardwarePropertyTextRow({required BuildContext context, required String label, required String value}) {
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
              color: Theme.of(
                context,
              ).colorScheme.textPrimary.withOpacity(0.5),
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

class _CircuitSelection extends StatelessWidget {
  const _CircuitSelection({
    super.key,
    required this.speaker,
  });

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState asyncSnapshot) {
        final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
        final CircuitModel? currentCicuit = viewModel.getCircuitForHardware(
          hardwareId: speaker.id,
        );
        final List<CircuitModel> compatibleCircuits = viewModel.getCompatibleCircuits(
          hardwareId: speaker.id,
          sku: speaker.speakerSKU,
        );
        return Row(
          children: <Widget>[
            FusionAppText(
              text: "Circuit",
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: context.colorScheme.textPrimary.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            Expanded(
              child: PopupMenuButton<CircuitModel?>(
                tooltip: "Change Circuit",
                color: Colors.white,
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<CircuitModel?>>[
                      for (final CircuitModel circuit in compatibleCircuits)
                        // if (circuit.id != currentCicuit?.id)
                        PopupMenuItem<CircuitModel>(
                          value: circuit,
                          height: 30,
                          onTap: () {
                            if (currentCicuit?.id == circuit.id) return;
                            if (currentCicuit != null) {
                              viewModel.removeHardwareFromCircuit(
                                hwId: speaker.id,
                                circuitId: currentCicuit.id,
                              );
                            }
                            viewModel.addHardwareToCircuit(
                              hwId: speaker.id,
                              circuitId: circuit.id,
                            );
                          },
                          child: FusionAppText(
                            text: circuit.name,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (compatibleCircuits.isNotEmpty)
                        const PopupMenuDivider(
                          height: 12,
                        ),

                      PopupMenuItem<CircuitModel?>(
                        value: null,
                        height: 30,
                        onTap: () {
                          if (currentCicuit != null) {
                            viewModel.removeHardwareFromCircuit(
                              hwId: speaker.id,
                              circuitId: currentCicuit.id,
                            );
                          }
                          viewModel.addNewCircuitWithHardware(
                            hardware: speaker,
                          );
                        },
                        child: Row(
                          spacing: 12,
                          children: <Widget>[
                            const Icon(
                              Icons.add,
                              color: Colors.black54,
                              size: 12,
                            ),
                            FusionAppText(
                              text: "Create New",
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    if (currentCicuit == null)
                      FusionAppText(
                        text: "Select Circuit",
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.end,
                      )
                    else
                      FusionAppText(
                        text: currentCicuit.name,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
