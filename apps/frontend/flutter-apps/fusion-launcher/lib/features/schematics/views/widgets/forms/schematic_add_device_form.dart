import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../state/device_form_state.dart';
import '../../../viewmodel/form_viewmodel/add_device_form_viewmodel.dart';
import 'listening_area_dropdown_widget.dart';

class SchematicAddDeviceForm<T> extends StatelessWidget {
  const SchematicAddDeviceForm({
    super.key,
    required this.products,
    required this.itemLabel,
    required this.itemImage,
    required this.semanticsId,
    this.title = "Select Device",
    required this.onSubmit,
  });
  final List<T> products;
  final String Function(T item) itemLabel;
  final String Function(T item) itemImage;

  final String semanticsId;
  final String title;

  final bool Function(String areaId, String floorId, T device) onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddDeviceFormViewModel<T>>(
      create: (_) => AddDeviceFormViewModel<T>(),
      child: BlocBuilder<
        AddDeviceFormViewModel<T>,
        DeviceFormState<DeviceFormData<T>>
      >(
        builder: (
          BuildContext context,
          DeviceFormState<DeviceFormData<T>> state,
        ) {
          final AddDeviceFormViewModel<T> viewModel =
              context.watch<AddDeviceFormViewModel<T>>();
          return SizedBox(
            width: 250,
            child: Form(
              key: viewModel.formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: title,
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: context.colorScheme.strokeLight),
                    const SizedBox(height: 8),
                    SemanticHelper.radioGroup(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.section,
                        "${semanticsId}_radio_group",
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children:
                            products.map((T item) {
                              final String label = itemLabel(item);
                              final bool value =
                                  state.formData.selectedDevice == item;
                              return SemanticHelper.radio(
                                testId: SemanticHelper.createTestId(
                                  SemanticTypes.radio,
                                  "${semanticsId}_radio_${label.toLowerCase()}",
                                ),
                                value: value,
                                label: label,
                                child: InkWell(
                                  onTap: () {
                                    viewModel.selectDevice(item);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),

                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            value
                                                ? context
                                                    .colorScheme
                                                    .strokeLight
                                                : context
                                                    .colorScheme
                                                    .elevation2,
                                        width: value ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Image.asset(
                                          itemImage(item),
                                          width: 16,
                                          height: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FusionAppText(
                                            text: label,
                                            style: context.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  // color: context.colorScheme.textBody,
                                                ),
                                          ),
                                        ),

                                        const SizedBox(width: 24),
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color:
                                              value
                                                  ? context.colorScheme.primary
                                                  : Colors.transparent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FusionAppText(
                      text: "Select Location",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        // fontSize: 10,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ListeningAreaDropdownWidget(
                        listeningAreas:
                            serviceLocator<ProjectViewModel>().listeningAreas,
                        selectedListeningAreaIds: <String>[
                          if (state.formData.selectedLocation != null)
                            state.formData.selectedLocation!,
                        ],
                        onSelectionChanged: (
                          List<String> selectedIds,
                          String floorId,
                        ) {
                          if (selectedIds.isNotEmpty)
                            viewModel.selectLocation(
                              selectedIds.first,
                              floorId,
                            );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FusionButton(
                      accessLabel: 'add_device',
                      label: "Add Device",
                      width: double.infinity,
                      isActive: state.isComplete,
                      onTap: () {
                        onSubmit(
                          state.formData.selectedLocation!,
                          state.formData.floorId!,
                          state.formData.selectedDevice as T,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
