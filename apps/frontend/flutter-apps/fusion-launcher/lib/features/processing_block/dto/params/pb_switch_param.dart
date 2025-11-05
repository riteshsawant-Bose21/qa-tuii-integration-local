part of '../pb_item_param.dart';

class PBSwitchParam extends PBItemParam {
  final String label;
  final String? enableValueLabel;
  final String? disabledValueLabel;
  PBSwitchParam({required this.label, required this.enableValueLabel, required this.disabledValueLabel});

  PBSwitchParam copyWith({String? label, String? enableValueLabel, String? disabledValueLabel}) {
    return PBSwitchParam(
      label: label ?? this.label,
      enableValueLabel: enableValueLabel ?? this.enableValueLabel,
      disabledValueLabel: disabledValueLabel ?? this.disabledValueLabel,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label, 'enable_value_label': enableValueLabel, 'disabled_value_label': disabledValueLabel};
  }

  factory PBSwitchParam.fromMap(Map<String, dynamic> map) {
    return PBSwitchParam(
      label: (map['label'] ?? '') as String,
      enableValueLabel: (map['enable_value_label']) as String?,
      disabledValueLabel: (map['disabled_value_label']) as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory PBSwitchParam.fromJson(String source) => PBSwitchParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridSwitchParam(label: $label, enableValueLabel: $enableValueLabel, disabledValueLabel: $disabledValueLabel)';

  @override
  bool operator ==(covariant PBSwitchParam other) {
    if (identical(this, other)) return true;

    return other.label == label && other.enableValueLabel == enableValueLabel && other.disabledValueLabel == disabledValueLabel;
  }

  @override
  int get hashCode => label.hashCode ^ enableValueLabel.hashCode ^ disabledValueLabel.hashCode;
  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBSwitchParam.fromMap(map);
  }
}
