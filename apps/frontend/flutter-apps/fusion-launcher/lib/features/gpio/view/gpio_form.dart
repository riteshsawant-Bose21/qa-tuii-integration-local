import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../viewmodel/gpio_form_viewmodel.dart';
import '../viewmodel/gpio_viewmodel.dart';

class GpioForm extends StatelessWidget {
  const GpioForm({super.key, required this.viewModel, this.initial});

  final GpioViewmodel viewModel;
  final GpioConfig? initial;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
      child: ChangeNotifierProvider<GpioFormViewModel>(
        create: (BuildContext context) => GpioFormViewModel(viewModel: viewModel, initial: initial),
        child: Material(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const SizedBox(width: 10),
                    Text(
                      initial == null ? "Create GPIO" : "Edit GPIO",
                      style: context.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "close_gpio_form_button"),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Consumer<GpioFormViewModel>(
                  builder: (BuildContext context, GpioFormViewModel vm, Widget? child) {
                    return Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: SingleChildScrollView(
                        child: Form(
                          key: vm.key,
                          child: Column(
                            spacing: 24,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Name field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  FusionAppText(
                                    text: "GPIO Name",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 400),
                                    child: FusionTextField(
                                      controller: vm.name,
                                      hintText: "Enter GPIO name",
                                      decoration: FusionInputDecoration.fusionDense(
                                        colorScheme: Theme.of(context).colorScheme,
                                        hintText: 'Enter GPIO name',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Direction selector
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  FusionAppText(
                                    text: "Direction",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  RadioGroup<GpioDirection>(
                                    groupValue: vm.direction,
                                    onChanged: (GpioDirection? value) => vm.direction = value!,
                                    child: Row(
                                      spacing: 40,
                                      children: <Widget>[
                                        ...GpioDirection.values.map((GpioDirection d) {
                                          return Row(
                                            children: <Widget>[
                                              Radio<GpioDirection>(
                                                value: d,
                                                activeColor: Colors.black,
                                              ),
                                              Text(d.name.toUpperCase()),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Action based on direction
                              Builder(
                                builder: (BuildContext context) {
                                  if (vm.direction == GpioDirection.input) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        FusionAppText(
                                          text: "GPI Action",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 400,
                                          child: DropdownButtonFormField<GpiAction>(
                                            initialValue: vm.gpiAction,
                                            items:
                                                vm.gpiActions
                                                    .map(
                                                      (GpiAction e) => DropdownMenuItem<GpiAction>(
                                                        value: e,
                                                        child: Text(
                                                          e.displayName,
                                                          style: context.textTheme.bodySmall,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged: (GpiAction? value) => vm.gpiAction = value,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(4.0),
                                              ),
                                            ),
                                            validator: (GpiAction? value) {
                                              if (value == null) return 'Please select a GPI action';
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      FusionAppText(
                                        text: "GPO Action",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 400,
                                        child: SemanticHelper.button(
                                          testId: SemanticHelper.createTestId(SemanticTypes.button, "gpo_action_dropdown_button"),
                                          child: DropdownButtonFormField<GpoAction>(
                                            initialValue: vm.gpoAction,
                                            items:
                                                vm.gpoActions
                                                    .map(
                                                      (GpoAction e) => DropdownMenuItem<GpoAction>(
                                                        value: e,
                                                        child: Text(e.displayName, style: context.textTheme.bodySmall),
                                                      ),
                                                    )
                                                    .toList(),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(4.0),
                                              ),
                                            ),
                                            onChanged: (GpoAction? value) => vm.gpoAction = value,
                                            validator: (GpoAction? value) {
                                              if (value == null) return 'Please select a GPO action';
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              // Invert and Status controls
                              Row(
                                spacing: 24,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Checkbox(
                                        value: vm.invert,
                                        onChanged: (bool? value) => vm.invert = value ?? false,
                                      ),
                                      Text('Invert', style: context.textTheme.bodyMedium),
                                    ],
                                  ),
                                  // Row(
                                  //   children: <Widget>[
                                  //     Switch(
                                  //       value: vm.status,
                                  //       onChanged: (bool value) => vm.status = value,
                                  //     ),
                                  //     Text('Status', style: context.textTheme.bodyMedium),
                                  //   ],
                                  // ),
                                ],
                              ),

                              // Footer actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  FusionOutlinedButton(
                                    label: "Cancel",
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(width: 12),
                                  FusionButton(
                                    label: "Done",
                                    isActive: vm.canEnableSubmit,
                                    onTap: () async {
                                      try {
                                        final bool result = await vm.submit();
                                        if (result) {
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        FusionToast.error(context, message: e.toString());
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, GpioViewmodel viewModel, {GpioConfig? initial}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return GpioForm(viewModel: viewModel, initial: initial);
      },
    );
  }
}
