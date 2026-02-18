import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../state/device_form_state.dart';
import '../../../viewmodel/form_viewmodel/add_device_form_viewmodel.dart';

class SchematicAddDeviceForm<T> extends StatelessWidget {
  const SchematicAddDeviceForm({
    super.key,
    required this.products,
    required this.itemLabel,
    required this.itemImage,
  });
  final List<T> products;
  final String Function(T item) itemLabel;
  final String Function(T item) itemImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddDeviceFormViewModel<T>>(
      create: (_) => AddDeviceFormViewModel<T>(),
      child: BlocBuilder<AddDeviceFormViewModel<T>, DeviceFormState<DeviceFormData<T>>>(
        builder: (BuildContext context, DeviceFormState<DeviceFormData<T>> state) {
          final AddDeviceFormViewModel<T> viewModel = context.watch<AddDeviceFormViewModel<T>>();
          return Form(
            key: viewModel.formKey,
            child:  Column(
              children: [
                SemanticHelper.formControl(testId: testId, child: child)
              ],
            ),
          );
        },
      ),
    );
  }
}
