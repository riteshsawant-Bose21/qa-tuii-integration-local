part of '../pb_item_param.dart';

class PBEmptyParam extends PBItemParam {
  PBEmptyParam();
  factory PBEmptyParam.fromMap(Map<dynamic, dynamic> map) {
    return PBEmptyParam();
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{};
  }

  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBEmptyParam();
  }

  @override
  PBItemParam clone() {
    return PBEmptyParam();
  }
}
