import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'algo_layout/agc.dart';
part 'algo_layout/compressor.dart';
part 'algo_layout/delay.dart';
part 'algo_layout/ducker.dart';
part 'algo_layout/feedback_suppression.dart';
part 'algo_layout/gain.dart';
part 'algo_layout/gate.dart';
part 'algo_layout/graphic_eq.dart';
part 'algo_layout/limiter.dart';
part 'algo_layout/peq.dart';
part 'algo_layout/tone_control.dart';

class AlgorithmLayoutData {
  static PBLayout? getForAlgorithm(String algorithmId) {
    // return PBLayout.fromMap(SampleData.sampleData);
    _initPreferences();
    final String? layoutJson = _preferences?.getString("layout_$algorithmId");
    if (layoutJson != null) {
      try {
        return PBLayout.fromJson(layoutJson);
      } catch (e) {}
    }
    final Map<String, dynamic> layout = switch (algorithmId) {
      'delay' => _delay,
      'compressor' => _compressor,
      'limiter' => _limiter,
      'agc' => _agc,
      'feedback_suppression' => _feedbackSuppression,
      'graphic_eq' => _graphicEQ,
      'tone_control' => _toneControl,
      'peq' => _peq,
      'gain' => _gain,
      'gate' => _gate,
      'ducker' => _ducker,
      _ => <String, dynamic>{
        'width': 200,
        'height': 100,
        'children': <Map<String, dynamic>>[],
      },
    };
    return PBLayout.fromMap(layout);
  }

  static Future<void> saveLayout(String algorithmId, PBLayout layout) async {
    await _initPreferences();
    await _preferences?.setString("layout_$algorithmId", layout.toJson());
  }

  static SharedPreferences? _preferences;
  static bool isInitilizing = false;
  static Future<void> _initPreferences() async {
    if (isInitilizing) return;
    isInitilizing = true;
    _preferences ??= await SharedPreferences.getInstance();
  }
}
