import 'dart:convert';
import 'dart:developer';

class StateStack {
  final List<Map<String, dynamic>> _stack = <Map<String, dynamic>>[];
  int _currentIndex = -1;

  /// Push a new state and discard future states (redo history).
  void push(Map<String, dynamic> state) {
    if (_currentIndex < _stack.length - 1) {
      _stack.removeRange(_currentIndex + 1, _stack.length);
    }
    _stack.add(Map<String, dynamic>.from(state));
    log("*" * 20);
    log("Add State");
    log(jsonEncode(state));
    log("*" * 20);
    _currentIndex++;
  }

  /// Undo the last action and return the previous state.
  Map<String, dynamic>? undo() {
    if (canUndo) {
      _currentIndex--;
      return Map<String, dynamic>.from(_stack[_currentIndex]);
    }
    return null;
  }

  /// Redo the undone action and return the next state.
  Map<String, dynamic>? redo() {
    if (canRedo) {
      _currentIndex++;
      return Map<String, dynamic>.from(_stack[_currentIndex]);
    }
    return null;
  }

  /// Get the current state.
  Map<String, dynamic>? get current {
    if (_currentIndex >= 0 && _currentIndex < _stack.length) {
      return Map<String, dynamic>.from(_stack[_currentIndex]);
    }
    return null;
  }

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _stack.length - 1;

  void clear() {
    _stack.clear();
    _currentIndex = -1;
  }
}
