import 'dart:convert';

part 'params/pb_empty_param.dart';
part 'params/pb_graph_param.dart';
part 'params/pb_indicator_param.dart';
part 'params/pb_slider_param.dart';
part 'params/pb_switch_param.dart';
part 'params/pb_text_param.dart';
part 'params/pb_meter_param.dart';

abstract class PBItemParam {
  Map<String, dynamic> toMap() => <String, dynamic>{};
}
