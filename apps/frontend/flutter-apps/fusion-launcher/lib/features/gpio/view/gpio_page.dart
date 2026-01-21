import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/broadcast_controllers.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/gpio/gpio_view_model.dart';
import 'package:fusion_launcher/features/scheduling/view/scheduling_page.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/color_scheme.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../configuration_page/widgets/snapshots/action_drop_down.dart';
import '../state/gpio_state.dart';
import '../viewmodel/gpio_viewmodel.dart';

class GpioPage extends StatelessWidget {
  const GpioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: context.colorScheme.elevation2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BlocProvider<GpioViewmodel>(
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
                      /// GPIO Header
                      SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "gpio_header"),
                        child: Container(
                          color: context.colorScheme.elevation1,
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            spacing: 10,
                            children: <Widget>[
                              // SvgPicture.asset(
                              //   'assets/icons/gpio/gpio.svg',
                              //   width: 25,
                              //   height: 25,
                              //   color: context.colorScheme.iconWhite,
                              // ),
                              Text(
                                "GPIO",
                                style: context.textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.elevation2.withAlpha(120),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.colorScheme.elevation5),
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

                              SemanticHelper.button(
                                testId: SemanticHelper.createTestId(SemanticTypes.button, "add_gpio_button"),
                                child: InkWell(
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
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Builder(
                          builder: (BuildContext context) {
                            if (state.gpios.isEmpty) {
                              return Center(
                                child: Text(
                                  "No GPIOs Configured",
                                  style: context.textTheme.bodyMedium,
                                ),
                              );
                            }
                            return FusionTable(
                              onReorder: (int oldIndex, int newIndex) {
                                context.read<GpioViewmodel>().reOrderGpio(oldIndex, newIndex);
                              },
                              keyExtractor: (int index) => state.gpios[index].id,
                              headers: <FusionTableHeader>[
                                FusionTableHeader(flex: 1, title: "Name"),
                                FusionTableHeader(
                                  flex: 3,
                                  title: "In/Out",
                                  aligment: Alignment.center,
                                ),
                                FusionTableHeader(
                                  flex: 2,
                                  title: "Action",
                                  aligment: Alignment.center,
                                ),
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
                                  TitleTextFieldSwitcher(
                                    value: gpio.name,
                                    hintText: "Enter Name",
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        ...GpioDirection.values.map((GpioDirection direction) {
                                          return Row(
                                            children: <Widget>[
                                              Radio<GpioDirection>(
                                                value: direction,
                                                activeColor: context.colorScheme.iconDefault,
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

                                  /// Action Dropdown
                                  switch (gpio.direction) {
                                    GpioDirection.input => SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(SemanticTypes.button, "gpi_input_action_dropdown_$index"),
                                      child: FusionDropdown<GpiAction>(
                                        value: gpio.gpiAction,
                                        display: (GpiAction action) => action.displayName,
                                        hint: "Select Action",
                                        items: GpiAction.values,
                                        onChanged: (GpiAction? action) {
                                          context.read<GpioViewmodel>().updateGpio(gpio.copyWith(gpiAction: action));
                                        },
                                      ),
                                    ),
                                    GpioDirection.output => SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(SemanticTypes.button, "gpo_output_action_dropdown_$index"),
                                      child: FusionDropdown<GpoAction>(
                                        value: gpio.gpoAction,
                                        display: (GpoAction action) => action.displayName,
                                        hint: "Select Action",
                                        items: GpoAction.values,
                                        onChanged: (GpoAction? action) {
                                          context.read<GpioViewmodel>().updateGpio(gpio.copyWith(gpoAction: action));
                                        },
                                      ),
                                    ),
                                  },
                                  if ((gpio.direction == GpioDirection.output && gpio.gpoAction == GpoAction.openCollector) ||
                                      (gpio.direction == GpioDirection.input && gpio.gpiAction == GpiAction.voltageTrigger))
                                    SemanticHelper.toggle(
                                      testId: SemanticHelper.createTestId(SemanticTypes.toggle, "gpio_invert_toggle_$index"),
                                      value: gpio.invert,
                                      child: Checkbox(
                                        value: gpio.invert,
                                        onChanged: (bool? value) {
                                          context.read<GpioViewmodel>().updateGpio(gpio.copyWith(invert: value));
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        side: MaterialStateBorderSide.resolveWith(
                                          (Set<WidgetState> states) {
                                            if (states.contains(MaterialState.selected)) {
                                              return BorderSide(
                                                color: context.colorScheme.primaryWhite,
                                                width: 1,
                                              );
                                            }
                                            return BorderSide(
                                              color: context.colorScheme.primaryWhite,
                                              width: 1,
                                            );
                                          },
                                        ),
                                        activeColor: context.colorScheme.primaryBlack,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(),
                                  if (gpio.direction == GpioDirection.output)
                                    const SizedBox()
                                  else
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: gpio.status ? Colors.blue : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),

                                  if (gpio.direction == GpioDirection.output)
                                    SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(SemanticTypes.button, "gpio_output_status_switch_$index"),
                                      child: Switch(
                                        value: false,
                                        onChanged: (_) {},
                                        // activeThumbColor: Colors.black,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Theme.of(context).colorScheme.primaryWhite;
                                          }
                                          return context.colorScheme.primaryBlack;
                                        }),
                                        trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Theme.of(context).colorScheme.primaryBlack;
                                          }
                                          return context.colorScheme.primaryBlack;
                                        }),
                                        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                      ),
                                    )
                                  else
                                    FusionButton(label: "Test", onTap: () {}),

                                  if (gpio.direction == GpioDirection.input)
                                    SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(SemanticTypes.button, "gpio_input_configure_event_button_$index"),
                                      child: InkWell(
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
                                            color: context.colorScheme.iconWhite,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(),

                                  SemanticHelper.button(
                                    testId: SemanticHelper.createTestId(SemanticTypes.button, "delete_gpio_button_$index"),
                                    child: IconButton(
                                      onPressed: () {
                                        context.read<GpioViewmodel>().removeGpio(gpio);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                      ),
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
      ),
    );
  }
}
