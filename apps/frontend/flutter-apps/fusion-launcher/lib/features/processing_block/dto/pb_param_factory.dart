import 'pb_item_param.dart';

class PBParamFactory {
  static PBItemParam build(Map<String, dynamic> map, String type) {
    switch (type) {
      case 'indicator':
        return PBIndicatorParam.fromMap(map);
      case 'slider':
        return PBSliderParam.fromMap(map);
      case 'switch':
        return PBSwitchParam.fromMap(map);
      case 'text':
        return PBTextParam.fromMap(map);
      case 'graph':
        return PBGraphParam.fromMap(map);
      case 'meter':
        return PBMeterParam.fromMap(map);
      default:
        return PBEmptyParam();
    }
  }
}
