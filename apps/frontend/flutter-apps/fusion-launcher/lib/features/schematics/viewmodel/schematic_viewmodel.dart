// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fusion_launcher/core/service_locator.dart';
// import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
// import 'package:fusion_lib/fusion_lib.dart';

// class SchematicViewmodel extends Cubit<int> {
//   SchematicViewmodel() : super(0);

//   ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

//   List<Source> getSources({String? query}) {
//     if (query == null || query.isEmpty) return projectViewModel.sources;
//     return projectViewModel.sources.where((Source s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
//   }
// }
