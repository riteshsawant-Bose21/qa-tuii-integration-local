class DeepDifference {
  bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final dynamic key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }

  dynamic deepDifference(dynamic oldValue, dynamic newValue) {
    // --- MAP ---
    if (oldValue is Map && newValue is Map) {
      final Map<String, dynamic> diff = <String, dynamic>{};
      final Set<dynamic> allKeys = <dynamic>{
        ...oldValue.keys,
        ...newValue.keys,
      };

      for (final dynamic key in allKeys) {
        final bool hadOld = oldValue.containsKey(key);
        final bool hasNew = newValue.containsKey(key);

        if (!hadOld && hasNew) {
          diff[key] = newValue[key];
        } else if (hadOld && !hasNew) {
          diff[key] = null;
        } else {
          final dynamic sub = deepDifference(oldValue[key], newValue[key]);
          if (sub != null) diff[key] = sub;
        }
      }

      return diff.isEmpty ? null : diff;
    }

    // --- LIST ---
    if (oldValue is List && newValue is List) {
      final bool hasIdMaps =
          (oldValue.any((dynamic e) => e is Map && e.containsKey('id'))) ||
          (newValue.any((dynamic e) => e is Map && e.containsKey('id')));

      if (hasIdMaps) {
        // Match maps by 'id'
        final Map<String, Map<String, dynamic>> oldById =
            <String, Map<String, dynamic>>{
              for (final Map<dynamic, dynamic> e
                  in oldValue.whereType<Map<dynamic, dynamic>>())
                if (e['id'] != null)
                  e['id'].toString(): e.cast<String, dynamic>(),
            };
        final Map<String, Map<String, dynamic>> newById =
            <String, Map<String, dynamic>>{
              for (final Map<dynamic, dynamic> e
                  in newValue.whereType<Map<dynamic, dynamic>>())
                if (e['id'] != null)
                  e['id'].toString(): e.cast<String, dynamic>(),
            };

        final List<Map<String, dynamic>> added = <Map<String, dynamic>>[];
        final List<Map<String, dynamic>> removed = <Map<String, dynamic>>[];
        final Map<String, dynamic> modified = <String, dynamic>{};

        for (final String id in newById.keys) {
          if (!oldById.containsKey(id)) {
            added.add(newById[id]!);
          } else {
            final dynamic sub = deepDifference(oldById[id], newById[id]);
            if (sub != null) modified[id] = sub;
          }
        }

        for (final String id in oldById.keys) {
          if (!newById.containsKey(id)) {
            removed.add(oldById[id]!);
          }
        }

        if (added.isEmpty && removed.isEmpty && modified.isEmpty) return null;
        return <String, Object>{
          if (added.isNotEmpty) 'added': added,
          if (removed.isNotEmpty) 'removed': removed,
          if (modified.isNotEmpty) 'modified': modified,
        };
      } else {
        // Fallback: list of primitives or maps without IDs
        if (_deepEquals(oldValue, newValue)) return null;

        final List<dynamic> added =
            newValue
                .where(
                  (dynamic n) =>
                      !oldValue.any((dynamic o) => _deepEquals(o, n)),
                )
                .toList();
        final List<dynamic> removed =
            oldValue
                .where(
                  (dynamic o) =>
                      !newValue.any((dynamic n) => _deepEquals(o, n)),
                )
                .toList();

        if (added.isEmpty && removed.isEmpty) return null;
        return <String, List<dynamic>>{
          if (added.isNotEmpty) 'added': added,
          if (removed.isNotEmpty) 'removed': removed,
        };
      }
    }

    // --- PRIMITIVE / DIFFERENT TYPE ---
    if (!_deepEquals(oldValue, newValue)) return newValue;
    return null;
  }

  Map<String, dynamic> getMapDifference(
    Map<String, dynamic> oldMap,
    Map<String, dynamic> newMap,
  ) {
    final dynamic diff = deepDifference(oldMap, newMap);
    return (diff is Map<String, dynamic>) ? diff : <String, dynamic>{};
  }
}
