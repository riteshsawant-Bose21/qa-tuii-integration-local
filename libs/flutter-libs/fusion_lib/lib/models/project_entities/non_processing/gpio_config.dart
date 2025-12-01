enum GpioDirection {
  input,
  output,
}

enum GpiAction {
  activeHigh,
  activeLow,
  voltageTrigger,
}

enum GpoAction {
  activeHigh,
  activeLow,
  openCollector,
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
}
