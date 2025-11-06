import '../blocks/pb_widgets.dart';
import 'pb_item_param.dart';

class PBParamFactory {
  static PBItemParam build(Map<String, dynamic> map, String type) {
    return PbWidgets.getFor(type)?.paramFactory(map) ?? PBEmptyParam();
  }
}
