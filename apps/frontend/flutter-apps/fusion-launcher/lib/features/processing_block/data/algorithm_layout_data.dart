import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';

part 'algo_layout/agc.dart';
part 'algo_layout/compressor.dart';
part 'algo_layout/ducker.dart';

class AlgorithmLayoutData {
  static PBLayout? getForAlgorithm(String algorithmId) {
    // return PBLayout.fromMap(SampleData.sampleData);
    final Map<String, dynamic> layout = switch (algorithmId) {
      'ducker' => _duckerLayout,
      'agc' => _agc,
      'compressor' => _compressor,
      _ => <String, dynamic>{
        'width': 200,
        'height': 100,
        'children': <Map<String, dynamic>>[],
      },
    };
    return PBLayout.fromMap(layout);
  }
}
