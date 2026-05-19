class FusionStateSnapshot {
  final Map<String, dynamic> state;

  const FusionStateSnapshot({required this.state});

  factory FusionStateSnapshot.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const FusionStateSnapshot(state: <String, dynamic>{});
    }

    final dynamic rawState = json['state'];
    if (rawState is! Map<String, dynamic>) {
      return const FusionStateSnapshot(state: <String, dynamic>{});
    }

    final Map<String, dynamic> flattened = <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in rawState.entries) {
      final dynamic value = entry.value;
      if (value is Map<String, dynamic> && value.containsKey('data')) {
        flattened[entry.key] = value['data'];
      }
    }

    return FusionStateSnapshot(state: flattened);
  }
}

class FusionStateValue<T> {
  final bool exists;
  final T? value;

  const FusionStateValue({required this.exists, this.value});

  factory FusionStateValue.fromJson(
    dynamic json,
    T Function(dynamic value) decodeValue,
  ) {
    if (json is! Map<String, dynamic>) {
      return FusionStateValue<T>(exists: false);
    }

    final bool exists = json['exists'] == true;
    if (!exists) {
      return FusionStateValue<T>(exists: false);
    }

    return FusionStateValue<T>(exists: true, value: decodeValue(json['value']));
  }
}
