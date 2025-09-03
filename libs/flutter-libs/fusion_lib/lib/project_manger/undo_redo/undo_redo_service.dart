import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

extension UndoRedoService on ProjectService {
  /// -------------------
  /// Undo / Redo
  /// -------------------

  bool get _isBatching => false;

  set _isBatching(bool value) {
    _isBatching = value;
  }

  Map<String, dynamic>? get _batchSnapshotBefore => null;
  set _batchSnapshotBefore(Map<String, dynamic>? value) {
    _batchSnapshotBefore = value;
  }

  // Capture current state as a JSON map (deep copy)
  Map<String, dynamic> _captureSnapshot() {
    // ProjectService.toJson returns Map<String, dynamic>
    final s = toJson();
    // make sure it's a deep copy (json encode/decode)
    return jsonDecode(jsonEncode(s)) as Map<String, dynamic>;
  }

  void _pushUndoSnapshot(Map<String, dynamic> snapshot) {
    undoStack.add(snapshot);
    if (undoStack.length > maxHistory) {
      undoStack.removeAt(0);
    }
    print("Undo stack size: ${undoStack.length}");
    // clearing redo on new action
    redoStack.clear();
  }

  void recordChange() {
    // call this before a mutating operation (records "before" state)
    if (_isBatching) {
      // if batching already started, we already captured before snapshot on beginBatch
      return;
    }
    _pushUndoSnapshot(_captureSnapshot());
  }

  /// Begin grouping multiple operations into a single undo step.
  /// Example: beginBatch(); addZone(...); addHardware(...); endBatch(commit: true);
  void beginBatch() {
    if (_isBatching) return;
    _isBatching = true;
    _batchSnapshotBefore = _captureSnapshot();
  }

  /// End batch. If commit==true, we push the snapshot captured at beginBatch to undo stack.
  /// If commit==false, we discard and do not record anything.
  void endBatch({bool commit = true}) {
    if (!_isBatching) return;
    if (commit && _batchSnapshotBefore != null) {
      _pushUndoSnapshot(_batchSnapshotBefore!);
    }
    _batchSnapshotBefore = null;
    _isBatching = false;
  }

  /// Undo: restore last snapshot (the project state *before* the last recorded change).
  bool canUndo() => undoStack.isNotEmpty;
  bool canRedo() => redoStack.isNotEmpty;

  Map<String, dynamic>? undo() {
    print("Undo stack size before undo: ${undoStack.length}");
    if (!canUndo()) return null;
    // Save current state to redo stack
    final current = _captureSnapshot();
    redoStack.add(current);

    print("Redo stack size after adding current: ${redoStack.length}");

    // Pop the previous state from undo and restore it
    final snapshot = undoStack.removeLast();
    print("Undo stack size after undo: ${undoStack.length}");
    print("Snapshot restored: $snapshot");
    return snapshot;
  }

  Map<String, dynamic>? redo() {
    if (!canRedo()) return null;
    // Save current to undo (so undo after redo is possible)
    final current = _captureSnapshot();
    undoStack.add(current);

    // pop redo
    final snapshot = redoStack.removeLast();
    return snapshot;
  }
}
