import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/broadcast_controllers.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/gpio/gpio_view_model.dart';
import 'package:fusion_launcher/features/scheduling/view/scheduling_page.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../configuration_page/widgets/snapshots/action_drop_down.dart';
import '../state/gpio_state.dart';
import '../viewmodel/gpio_viewmodel.dart';

class GpioPage extends StatelessWidget {
  const GpioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GpioViewmodel>(
      create:
          (BuildContext context) => GpioViewmodel(
            serviceLocator<ProjectViewModel>(),
          ),
      child: BlocListener<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, Object? state) {
          BlocProvider.of<GpioViewmodel>(context).refresh();
        },
        child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState? _) {
            return BlocBuilder<GpioViewmodel, GpioState>(
              builder: (BuildContext context, GpioState state) {
                return Column(
                  children: <Widget>[
                    Container(
                      color: Colors.grey[200]!,
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        spacing: 10,
                        children: <Widget>[
                          SvgPicture.asset('assets/icons/gpio/gpio.svg', width: 25, height: 25),
                          Text(
                            "GPIO",
                            style: context.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  state.availableGPIOPorts < 0 ? "Need" : "Available",
                                  style: context.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: state.availableGPIOPorts >= 0 ? Colors.black : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                  child: Text(
                                    "${state.availableGPIOPorts.abs()}",
                                    style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),

                          InkWell(
                            onTap: () {
                              if (state.availableGPIOPorts <= 0) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => FusionDialog(
                                        primaryButtonWidth: 120,
                                        title: 'Not Enough GPIO Ports',
                                        description: "You have used all available GPIO ports. Adding more GPIO needs more hardware resources.",
                                        primaryButtonLabel: 'Add Anyways',
                                        secondaryButtonLabel: 'Cancel',
                                        onSecondaryPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        onPrimaryPressed: () {
                                          Navigator.of(context).pop();
                                          // GpioForm.show(context, context.read<GpioViewmodel>());
                                          context.read<GpioViewmodel>().projectViewModel.addGPIOConfig(
                                            config: GpioConfig(
                                              name: "Gpio ${state.gpios.length}",
                                              direction: GpioDirection.input,
                                              invert: false,
                                              status: false,
                                            ),
                                          );
                                        },
                                      ),
                                );
                                return;
                              }
                              context.read<GpioViewmodel>().projectViewModel.addGPIOConfig(
                                config: GpioConfig(
                                  name: "Gpio ${state.gpios.length}",
                                  direction: GpioDirection.input,
                                  invert: false,
                                  status: false,
                                ),
                              );
                              // GpioForm.show(context, context.read<GpioViewmodel>());
                            },
                            child: const Icon(
                              Icons.add,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (BuildContext context) {
                          if (state.gpios.isEmpty) {
                            return Center(
                              child: Text(
                                "No GPIOs Configured",
                                style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            );
                          }
                          return FusionTable(
                            headers: <FusionTableHeader>[
                              FusionTableHeader(flex: 1, title: "Name"),
                              FusionTableHeader(flex: 3, title: "In/Out"),
                              FusionTableHeader(flex: 2, title: "Action"),
                              FusionTableHeader(
                                flex: 1,
                                title: "Invert",
                                aligment: Alignment.center,
                              ),
                              FusionTableHeader(
                                flex: 1,
                                title: "Status",
                                aligment: Alignment.center,
                              ),
                              FusionTableHeader(flex: 1, title: ""),
                              FusionTableHeader(flex: 1, title: ""),
                              FusionTableHeader(flex: 1, title: ""),
                            ],
                            itemCount: state.gpios.length,
                            itemBuilder: (BuildContext context, int index) {
                              final GpioConfig gpio = state.gpios[index];
                              return <Widget>[
                                _TitleTextFieldSwitcher(
                                  value: gpio.name,
                                  style: context.textTheme.bodyMedium!,
                                  save: (String value) {
                                    context.read<GpioViewmodel>().updateGpio(gpio.copyWith(name: value));
                                  },
                                ),
                                RadioGroup<GpioDirection>(
                                  groupValue: gpio.direction,
                                  onChanged: (GpioDirection? value) {
                                    context.read<GpioViewmodel>().updateGpio(gpio.copyWith(direction: value));
                                  },
                                  child: Row(
                                    spacing: 20,
                                    children: <Widget>[
                                      ...GpioDirection.values.map((GpioDirection direction) {
                                        return Row(
                                          children: <Widget>[
                                            Radio<GpioDirection>(
                                              value: direction,
                                              activeColor: Colors.black,
                                            ),
                                            Text(
                                              direction.name.toUpperCase(),
                                              style: context.textTheme.bodySmall!,
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                // Container(
                                //   decoration: BoxDecoration(
                                //     border: Border.all(color: Colors.black),
                                //     borderRadius: BorderRadius.circular(10),
                                //   ),
                                //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                //   child: Row(
                                //     children: <Widget>[
                                //       Expanded(
                                //         child: Text(
                                //           gpio.gpiAction?.displayName ?? gpio.gpoAction?.displayName ?? "-",
                                //           style: context.textTheme.bodyMedium,
                                //         ),
                                //       ),
                                //       const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                                //     ],
                                //   ),
                                // ),
                                switch (gpio.direction) {
                                  // TODO: Handle this case.
                                  GpioDirection.input => FusionDropdown<GpiAction>(
                                    value: gpio.gpiAction,
                                    display: (GpiAction action) => action.displayName,
                                    hint: "Select Action",
                                    items: GpiAction.values,
                                    onChanged: (GpiAction? action) {
                                      context.read<GpioViewmodel>().updateGpio(gpio.copyWith(gpiAction: action));
                                    },
                                  ),
                                  // TODO: Handle this case.
                                  GpioDirection.output => FusionDropdown<GpoAction>(
                                    value: gpio.gpoAction,
                                    display: (GpoAction action) => action.displayName,
                                    hint: "Select Action",
                                    items: GpoAction.values,
                                    onChanged: (GpoAction? action) {
                                      context.read<GpioViewmodel>().updateGpio(gpio.copyWith(gpoAction: action));
                                    },
                                  ),
                                },
                                Checkbox(
                                  value: gpio.invert,
                                  onChanged: (bool? value) {
                                    context.read<GpioViewmodel>().updateGpio(gpio.copyWith(invert: value));
                                  },
                                  activeColor: Colors.black,
                                ),
                                if (gpio.direction == GpioDirection.output)
                                  const SizedBox()
                                else
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: gpio.status ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                if (gpio.direction == GpioDirection.output)
                                  Switch(
                                    value: false,
                                    onChanged: (_) {},
                                    // activeThumbColor: Colors.black,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Theme.of(context).colorScheme.white;
                                      }
                                      return Theme.of(context).colorScheme.greyDark;
                                    }),
                                    trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Theme.of(context).colorScheme.black;
                                      }
                                      return Theme.of(context).colorScheme.grey;
                                    }),
                                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                  )
                                else
                                  FusionButton(label: "Test", onTap: () {}),

                                if (gpio.direction == GpioDirection.input)
                                  InkWell(
                                    onTap: () {
                                      /// getEventsForGPI if existis this directly navigate to Configuration tab
                                      final FusionEvent? eventsForGPI = serviceLocator<ProjectViewModel>().getEventsForGPI(
                                        gpiId: gpio.id,
                                      );
                                      if (eventsForGPI != null) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          /// Set the selected event ID to the existing event for this GPI
                                          serviceLocator<ProjectViewModel>().setSelectedEventId(eventsForGPI.id);
                                        });
                                      } else {
                                        /// Add the event to the project
                                        serviceLocator<ProjectViewModel>().addEventForGPI(
                                          gpiId: gpio.id,
                                        );
                                      }

                                      /// Navigate to Configuration tab (index 3)
                                      projectTabBroadcastController.add(3);

                                      /// Switch to Events sub-tab within Configuration
                                      serviceLocator<ProjectViewModel>().setConfigurationMenuMode(
                                        ConfigurationMenuMode.events,
                                      );
                                    },
                                    child: Center(
                                      child: SvgPicture.asset(
                                        "assets/icons/scheduler/run.svg",
                                        width: 25,
                                        height: 25,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(),

                                IconButton(
                                  onPressed: () {
                                    context.read<GpioViewmodel>().removeGpio(gpio);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                  ),
                                ),
                              ];
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TitleTextFieldSwitcher extends StatefulWidget {
  const _TitleTextFieldSwitcher({
    super.key,
    required this.save,
    required this.style,
    required this.value,
  });
  final String value;
  final ValueChanged<String> save;
  final TextStyle style;
  @override
  State<_TitleTextFieldSwitcher> createState() => __TitleTextFieldSwitcherState();
}

class __TitleTextFieldSwitcherState extends State<_TitleTextFieldSwitcher> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isEditing = false;
  late String currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
    controller.text = widget.value;

    focusNode.addListener(() {
      if (!focusNode.hasFocus && isEditing) {
        _saveValue();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      isEditing = true;
      controller.text = currentValue;
    });

    // Focus and select all text after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  void _saveValue() {
    if (isEditing) {
      if (controller.text.isEmpty) {
        _cancelEditing();
        return;
      }
      setState(() {
        currentValue = controller.text;
        isEditing = false;
      });
      widget.save(controller.text);
    }
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      controller.text = currentValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _cancelEditing();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: widget.style,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onSubmitted: (_) => _saveValue(),
          onTapOutside: (_) => _saveValue(),
        ),
      );
    }

    return InkWell(
      onTap: _startEditing,
      child: Text(
        currentValue,
        style: widget.style,
      ),
    );
  }
}
