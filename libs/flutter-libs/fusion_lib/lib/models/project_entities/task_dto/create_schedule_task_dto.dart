class CreateScheduleTaskDto {
  final String id;
  final String description;
  final String type;
  final String cronExpr;
  final DateTime startAt;
  final DateTime? endAt;
  final ScheduleTaskParams params;
  final bool? enabled;

  const CreateScheduleTaskDto({
    required this.id,
    required this.description,
    required this.type,
    required this.cronExpr,
    required this.startAt,
    required this.endAt,
    required this.params,
    this.enabled,
  });

  factory CreateScheduleTaskDto.fromJson(Map<String, dynamic> json) {
    return CreateScheduleTaskDto(
      id: json['id'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      cronExpr: json['cron_expr'] as String,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at'] as String) : null,
      params: ScheduleTaskParams.fromJson(json['params'] as Map<String, dynamic>),
      enabled: json['enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type': type,
      'cron_expr': cronExpr,
      'start_at': startAt.toLocal().toIso8601String(),
      'end_at': endAt?.toLocal().toIso8601String(),
      'params': params.toJson(),
      'enabled': enabled,
    };
  }

  CreateScheduleTaskDto copyWith({
    String? id,
    String? description,
    String? type,
    String? cronExpr,
    DateTime? startAt,
    DateTime? endAt,
    ScheduleTaskParams? params,
    bool? enabled,
  }) {
    return CreateScheduleTaskDto(
      id: id ?? this.id,
      description: description ?? this.description,
      type: type ?? this.type,
      cronExpr: cronExpr ?? this.cronExpr,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      params: params ?? this.params,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  String toString() {
    return 'CreateScheduleTaskDto(id: $id, description: $description, '
        'type: $type, cronExpr: $cronExpr, startAt: $startAt, '
        'endAt: $endAt, params: $params enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateScheduleTaskDto &&
        other.id == id &&
        other.description == description &&
        other.type == type &&
        other.cronExpr == cronExpr &&
        other.startAt == startAt &&
        other.endAt == endAt &&
        other.params == params &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(
    id,
    description,
    type,
    cronExpr,
    startAt,
    endAt,
    params,
    enabled,
  );
}

class ScheduleTaskParams {
  final String snapshotDefinitionId;

  const ScheduleTaskParams({
    required this.snapshotDefinitionId,
  });

  factory ScheduleTaskParams.fromJson(Map<String, dynamic> json) {
    return ScheduleTaskParams(
      snapshotDefinitionId: json['snapshot_definition_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshot_definition_id': snapshotDefinitionId,
    };
  }

  ScheduleTaskParams copyWith({String? snapshotDefinitionId}) {
    return ScheduleTaskParams(
      snapshotDefinitionId: snapshotDefinitionId ?? this.snapshotDefinitionId,
    );
  }

  @override
  String toString() => 'ScheduleTaskParams(snapshotDefinitionId: $snapshotDefinitionId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleTaskParams && other.snapshotDefinitionId == snapshotDefinitionId;
  }

  @override
  int get hashCode => snapshotDefinitionId.hashCode;
}
