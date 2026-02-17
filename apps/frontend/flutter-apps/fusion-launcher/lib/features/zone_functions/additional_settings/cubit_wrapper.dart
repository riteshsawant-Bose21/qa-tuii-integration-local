import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/models/project_entities/zone_functions.dart';

import '../viewmodel/additional_settings_viewmodel.dart';

class ZoneFunctionAdditionalSettingsViewModelCubitWrapper extends StatelessWidget {
  final Widget Function(BuildContext context, ZoneFunctionAdditionalSettingsViewmodelState state, ZoneFunctionAdditionalSettingsViewModel vm) builder;
  final String zoneID;
  final ZoneFunctions? zoneFunction;

  const ZoneFunctionAdditionalSettingsViewModelCubitWrapper({
    super.key,
    required this.builder,
    required this.zoneID,
    this.zoneFunction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ZoneFunctionAdditionalSettingsViewModel>(
      create: (_) => ZoneFunctionAdditionalSettingsViewModel()..init(zoneFunctionsType: zoneFunction!.type, zoneID: zoneID),
      child: BlocBuilder<ZoneFunctionAdditionalSettingsViewModel, ZoneFunctionAdditionalSettingsViewmodelState>(
        builder: (BuildContext context, ZoneFunctionAdditionalSettingsViewmodelState state) {
          final ZoneFunctionAdditionalSettingsViewModel vm = context.watch<ZoneFunctionAdditionalSettingsViewModel>();
          return builder(context, state, vm);
        },
      ),
    );
  }
}
