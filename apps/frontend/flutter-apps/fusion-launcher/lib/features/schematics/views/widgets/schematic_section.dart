import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/state/search_state.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:nested/nested.dart';

import '../../state/device_listing_state.dart';
import '../../viewmodel/search_control_viewmodel.dart';

class SchematicSection<T, VM extends DeviceListingViewModel<T>> extends StatelessWidget {
  const SchematicSection({super.key, required this.create, required this.builder});

  final VM Function(BuildContext context) create;

  final Widget Function(BuildContext context, DeviceListingState<T> state) builder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VM>(
      create: create,
      child: MultiBlocListener(
        listeners: <SingleChildWidget>[
          BlocListener<SearchControlViewModel, SearchState>(
            listener: (BuildContext context, SearchState state) {
              context.read<VM>().search(state);
              context.read<SearchResultsViewModel>().onSearch(state);
            },
          ),
          BlocListener<ProjectViewModel, ProjectViewModelState>(
            listener: (BuildContext context, ProjectViewModelState state) {
              context.read<VM>().refresh();
              context.read<SearchResultsViewModel>().refresh();
            },
          ),
        ],
        child: BlocBuilder<VM, DeviceListingState<T>>(
          builder: (BuildContext context, DeviceListingState<T> state) {
            return builder(context, state);
          },
        ),
      ),
    );
  }
}
