import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';

part 'algo_layout/ducker.dart';

class AlgorithmLayoutData {
  static PBLayout? getForAlgorithm(String algorithmId) {
    final Map<String, dynamic> layout = switch (algorithmId) {
      'ducker' => _duckerLayout,
      _ => <String, dynamic>{
        'width': 100,
        'height': 100,
        'children': <Map<String, dynamic>>[],
      },
    };
    return PBLayout.fromMap(layout);
  }
}
