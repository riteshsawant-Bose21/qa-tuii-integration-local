class PrioritySourceData {
  final String id;
  final int priority;
  final String sourceId;
  final String zoneId;
  final double gain;
  final bool isActive;

  PrioritySourceData({
    String? id,
    this.gain = -24.0,
    required this.priority,
    required this.sourceId,
    required this.zoneId,
    this.isActive = false,
  }) : id = id ?? "PRIO${DateTime.now().millisecondsSinceEpoch}";

  //copy with method
  PrioritySourceData copyWith({
    String? id,
    double? gain,
    int? priority,
    String? sourceId,
    String? zoneId,
    bool? isActive,
  }) {
    return PrioritySourceData(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      priority: priority ?? this.priority,
      sourceId: sourceId ?? this.sourceId,
      zoneId: zoneId ?? this.zoneId,
      isActive: isActive ?? this.isActive,
    );
  }

  factory PrioritySourceData.fromJson(Map<String, dynamic> json) {
    return PrioritySourceData(
      id: json['id'] as String,
      gain: (json['gain'] as num).toDouble(),
      priority: json['priority'] as int,
      sourceId: json['sourceId'] as String,
      zoneId: json['zoneId'] as String,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gain': gain,
      'priority': priority,
      'sourceId': sourceId,
      'zoneId': zoneId,
      'isActive': isActive,
    };
  }
}
