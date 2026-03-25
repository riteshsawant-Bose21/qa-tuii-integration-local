import 'package:flutter_bloc/flutter_bloc.dart';

part 'config_aes67_state.dart';

class ConfigAes67Viewmodel extends Cubit<ConfigAes67State> {
  ConfigAes67Viewmodel() : super(const ConfigAes67Initial()) {
    _loadData();
  }

  void _loadData() {
    emit(const ConfigAes67Loading());

    // Start with empty streams - data will be added via dialogs
    emit(
      const ConfigAes67Loaded(
        clockLeader: 'Main DSP (FM6)',
        globalStatus: true,
        inputStreams: <Aes67Stream>[],
        outputStreams: <Aes67Stream>[],
      ),
    );
  }

  void toggleInputStreamEnabled(String id) {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;
    final List<Aes67Stream> updated =
        current.inputStreams.map((Aes67Stream s) {
          return s.id == id ? s.copyWith(isEnabled: !s.isEnabled) : s;
        }).toList();
    emit(current.copyWith(inputStreams: updated));
  }

  void toggleOutputStreamEnabled(String id) {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;
    final List<Aes67Stream> updated =
        current.outputStreams.map((Aes67Stream s) {
          return s.id == id ? s.copyWith(isEnabled: !s.isEnabled) : s;
        }).toList();
    emit(current.copyWith(outputStreams: updated));
  }

  void toggleGlobalStatus() {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;
    emit(current.copyWith(globalStatus: !current.globalStatus));
  }

  void addInputStream(Aes67Stream stream) {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;
    final List<Aes67Stream> updated = <Aes67Stream>[...current.inputStreams, stream];
    emit(current.copyWith(inputStreams: updated));
  }

  void addOutputStream(Aes67Stream stream) {
    final ConfigAes67State current = state;
    if (current is! ConfigAes67Loaded) return;
    final List<Aes67Stream> updated = <Aes67Stream>[...current.outputStreams, stream];
    emit(current.copyWith(outputStreams: updated));
  }
}
