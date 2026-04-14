import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'config_aes67_state.dart';

class ConfigAes67Viewmodel extends Cubit<ConfigAes67State> {
  final ProjectViewModel _projectViewModel;

  ConfigAes67Viewmodel({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(const ConfigAes67Initial()) {
    _loadData();
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    _loadData();
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  void _loadData() {
    emit(const ConfigAes67Loading());

    try {
      // Load streams from ProjectViewModel
      final List<Aes67Config> inputStreams = _projectViewModel.getAllAes67InputStreams();
      final List<Aes67Config> outputStreams = _projectViewModel.getAllAes67OutputStreams();

      emit(
        ConfigAes67Loaded(
          clockLeader: 'Main DSP (FM6)',
          globalStatus: true,
          inputStreams: inputStreams,
          outputStreams: outputStreams,
        ),
      );
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void toggleInputStreamEnabled(String id) {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;

    try {
      _projectViewModel.toggleAes67InputStreamEnabled(id);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void toggleOutputStreamEnabled(String id) {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;

    try {
      _projectViewModel.toggleAes67OutputStreamEnabled(id);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void toggleGlobalStatus() {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;
    emit(current.copyWith(globalStatus: !current.globalStatus));
  }

  void addInputStream(Aes67Config stream) {
    try {
      _projectViewModel.addAes67InputStream(stream: stream);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void addOutputStream(Aes67Config stream) {
    try {
      _projectViewModel.addAes67OutputStream(stream: stream);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void updateInputStream(Aes67Config stream) {
    try {
      _projectViewModel.updateAes67InputStream(stream: stream);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void updateOutputStream(Aes67Config stream) {
    try {
      _projectViewModel.updateAes67OutputStream(stream: stream);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void deleteInputStream(String id) {
    try {
      _projectViewModel.removeAes67InputStream(id);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  void deleteOutputStream(String id) {
    try {
      _projectViewModel.removeAes67OutputStream(id);
      syncWithProjectViewModel();
    } catch (e) {
      emit(ConfigAes67Error(message: e.toString()));
    }
  }

  Aes67Config? getInputStreamById(String id) {
    return _projectViewModel.getAes67InputStreamById(id);
  }

  Aes67Config? getOutputStreamById(String id) {
    return _projectViewModel.getAes67OutputStreamById(id);
  }
}
