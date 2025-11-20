part of '../pb_item_param.dart';

class PBButtonParam extends PBItemParam {
  final String label;
  final String? enableValueIcon;
  final String? disabledValueIcon;

  PBButtonParam({required this.label, required this.enableValueIcon, required this.disabledValueIcon});
  PBButtonParam copyWith({String? label, String? enableValueIcon, String? disabledValueIcon}) {
    return PBButtonParam(
      label: label ?? this.label,
      enableValueIcon: enableValueIcon ?? this.enableValueIcon,
      disabledValueIcon: disabledValueIcon ?? this.disabledValueIcon,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label, 'enable_value_icon': enableValueIcon, 'disabled_value_icon': disabledValueIcon};
  }

  factory PBButtonParam.fromMap(Map<dynamic, dynamic> map) {
    return PBButtonParam(
      label: (map['label'] ?? '') as String,
      enableValueIcon: (map['enable_value_icon']) as String?,
      disabledValueIcon: (map['disabled_value_icon']) as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory PBButtonParam.fromJson(String source) => PBButtonParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridSwitchParam(label: $label, enableValueLabel: $enableValueIcon, disabledValueLabel: $disabledValueIcon)';

  @override
  bool operator ==(covariant PBButtonParam other) {
    if (identical(this, other)) return true;

    return other.label == label && other.enableValueIcon == enableValueIcon && other.disabledValueIcon == disabledValueIcon;
  }

  @override
  int get hashCode => label.hashCode ^ enableValueIcon.hashCode ^ disabledValueIcon.hashCode;
  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBButtonParam.fromMap(map);
  }

  @override
  PBItemParam clone() {
    return copyWith();
  }
}
