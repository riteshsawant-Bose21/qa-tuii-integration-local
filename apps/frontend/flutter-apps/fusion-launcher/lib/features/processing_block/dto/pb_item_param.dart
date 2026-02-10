import 'dart:convert';

import 'package:fusion_lib/fusion_utils/deserialization_util.dart';

part 'params/pb_empty_param.dart';
part 'params/pb_graph_param.dart';
part 'params/pb_indicator_param.dart';
part 'params/pb_slider_param.dart';
part 'params/pb_switch_param.dart';
part 'params/pb_text_param.dart';
part 'params/pb_meter_param.dart';
part 'params/pb_dropdown_param.dart';
part 'params/pb_button_param.dart';
part 'params/pb_textfield_param.dart';
abstract class PBItemParam {
  Map<String, dynamic> toMap();

  PBItemParam loadMap(Map<String, dynamic> map);

  PBItemParam clone();
}
