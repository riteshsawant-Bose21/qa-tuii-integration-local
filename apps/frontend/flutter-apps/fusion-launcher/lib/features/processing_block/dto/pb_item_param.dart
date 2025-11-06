import 'dart:convert';

import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

part 'params/pb_empty_param.dart';
part 'params/pb_graph_param.dart';
part 'params/pb_indicator_param.dart';
part 'params/pb_slider_param.dart';
part 'params/pb_switch_param.dart';
part 'params/pb_text_param.dart';
part 'params/pb_meter_param.dart';

abstract class PBItemParam {
  Map<String, dynamic> toMap();

  PBItemParam loadMap(Map<String, dynamic> map);
}
