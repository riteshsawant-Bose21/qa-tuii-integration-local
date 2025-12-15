enum GpioDirection {
  input,
  output,
}

enum GpiAction {
  activeHigh,
  activeLow,
  voltageTrigger,
}

extension GpiActionExtension on GpiAction {
  String get displayName {
    switch (this) {
      case GpiAction.activeHigh:
        return "Active High";
      case GpiAction.activeLow:
        return "Active Low";
      case GpiAction.voltageTrigger:
        return "Voltage Trigger";
    }
  }
}

enum GpoAction {
  activeHigh,
  activeLow,
  openCollector,
}

extension GpoActionExtension on GpoAction {
  String get displayName {
    switch (this) {
      case GpoAction.activeHigh:
        return "Active High";
      case GpoAction.activeLow:
        return "Active Low";
      case GpoAction.openCollector:
        return "Open Collector";
    }
  }
}

class GpioConfig {
  final String id;
  final String name;
  final GpioDirection direction;
  final GpiAction? gpiAction; // used when direction = input
  final GpoAction? gpoAction; // used when direction = output
  final bool invert;
  final bool status;

  GpioConfig({
    String? id,
    required this.name,
    required this.direction,
    this.gpiAction,
    this.gpoAction,
    required this.invert,
    required this.status,
  }) : id = id ?? "GPIO${DateTime.now().millisecondsSinceEpoch}";

  factory GpioConfig.fromJson(Map<String, dynamic> json) {
    return GpioConfig(
      id: json['id'],
      name: json['name'],
      direction: GpioDirection.values.firstWhere(
        (e) => e.toString() == 'GpioDirection.${json['direction']}',
      ),
      gpiAction: json['gpiAction'] == null
          ? null
          : GpiAction.values.firstWhere(
              (e) => e.toString() == 'GpiAction.${json['gpiAction']}',
            ),
      gpoAction: json['gpoAction'] == null
          ? null
          : GpoAction.values.firstWhere(
              (e) => e.toString() == 'GpoAction.${json['gpoAction']}',
            ),
      invert: json['invert'] ?? false,
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'direction': direction.name,
      'gpiAction': gpiAction?.name,
      'gpoAction': gpoAction?.name,
      'invert': invert,
      'status': status,
    };
  }

  GpioConfig copyWith({
    String? id,
    String? name,
    GpioDirection? direction,
    GpiAction? gpiAction,
    GpoAction? gpoAction,
    bool? invert,
    bool? status,
  }) {
    return GpioConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      gpiAction: gpiAction ?? this.gpiAction,
      gpoAction: gpoAction ?? this.gpoAction,
      invert: invert ?? this.invert,
      status: status ?? this.status,
    );
  }

  GpioConfig removeGpiAction() {
    return GpioConfig(
      id: id,
      name: name,
      direction: direction,
      gpiAction: null,
      gpoAction: gpoAction,
      invert: invert,
      status: status,
    );
  }

  GpioConfig removeGpoAction() {
    return GpioConfig(
      id: id,
      name: name,
      direction: direction,
      gpiAction: gpiAction,
      gpoAction: null,
      invert: invert,
      status: status,
    );
  }
}
