import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/models/project_entities/circuit_model.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';

import '../../configuration/presentation/usecase/device_suggestion_usecase.dart';
import '../../speaker_selection_popup/viewmodel/product_query_view_model.dart';

class DeviceSuggestionViewModel extends Cubit<DeviceSuggestionResult?> {
  final ProductQueryViewModel productQueryModel;
  DeviceSuggestionViewModel({required this.productQueryModel}) : super(null) {
    refresh();
  }

  void refresh() {
    final DeviceSuggestionUseCase usecase = DeviceSuggestionUseCase(productQueryVM: productQueryModel);
    final List<Source> sources = serviceLocator<ProjectViewModel>().sources;
    final List<CircuitModel> circuits = serviceLocator<ProjectViewModel>().circuits;
    final DeviceSuggestionResult result = usecase.suggest(
      sources: sources,
      circuits: circuits,
    );
    emit(result);
  }
}
