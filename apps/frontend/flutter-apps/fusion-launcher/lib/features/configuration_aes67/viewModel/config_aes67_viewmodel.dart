import 'package:flutter_bloc/flutter_bloc.dart';

part 'config_aes67_state.dart';

class ConfigAes67Viewmodel extends Cubit<ConfigAes67State> {
  ConfigAes67Viewmodel() : super(const ConfigAes67Initial()) {
    _loadData();
  }

  void _loadData() {
    emit(const ConfigAes67Loading());

    // Simulated loaded state with mock data matching the screenshot
    emit(
      const ConfigAes67Loaded(
        clockLeader: 'Main DSP (FM6)',
        globalStatus: true,
        inputStreams: <Aes67Stream>[
          Aes67Stream(
            id: 'in_1',
            name: 'Mixer Feed',
            device: 'Yamaha DX5',
            streamOrAdvertisement: 'Main_Mix_LR',
            addressPort: '10.1.23.101:5001',
            channels: 2,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
          Aes67Stream(
            id: 'in_2',
            name: 'Mixer Feed_2',
            device: 'EX-4ML',
            streamOrAdvertisement: 'TableMics',
            addressPort: '10.1.23.104:5001',
            channels: 4,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
          Aes67Stream(
            id: 'in_3',
            name: 'Mixer Feed_2',
            device: 'EX-4ML',
            streamOrAdvertisement: 'TableMics',
            addressPort: '10.1.23.104:5001',
            channels: 4,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
          Aes67Stream(
            id: 'in_4',
            name: 'Mixer Feed_2',
            device: 'EX-4ML',
            streamOrAdvertisement: 'TableMics',
            addressPort: '10.1.23.104:5001',
            channels: 4,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
          Aes67Stream(
            id: 'in_5',
            name: 'Mixer Feed_2',
            device: 'EX-4ML',
            streamOrAdvertisement: 'TableMics',
            addressPort: '10.1.23.104:5001',
            channels: 4,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
          Aes67Stream(
            id: 'in_2',
            name: 'Mixer Feed_2',
            device: 'EX-4ML',
            streamOrAdvertisement: 'TableMics',
            addressPort: '10.1.23.104:5001',
            channels: 4,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
        ],
        outputStreams: <Aes67Stream>[
          Aes67Stream(
            id: 'out_1',
            name: 'Auditorium Out',
            device: 'Auditorium_LR',
            streamOrAdvertisement: 'Dante (mDNS)',
            addressPort: '10.1.23.101:5001',
            channels: 2,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
          Aes67Stream(
            id: 'out_2',
            name: 'Mixer Feed_3',
            device: 'FM8Y_1',
            streamOrAdvertisement: 'TableMics',
            addressPort: '10.1.23.104:5001',
            channels: 4,
            bitDepth: '24 bit',
            packetTime: '1ms',
            isEnabled: true,
          ),
        ],
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

  void addInputStream() {
    // Hook for adding a new input stream
  }

  void addOutputStream() {
    // Hook for adding a new output stream
  }
}
