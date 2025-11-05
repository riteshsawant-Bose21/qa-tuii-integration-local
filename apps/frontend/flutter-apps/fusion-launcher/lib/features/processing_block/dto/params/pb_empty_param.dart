part of '../pb_item_param.dart';

class PBEmptyParam extends PBItemParam {
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{};
  }

  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBEmptyParam();
  }
}
