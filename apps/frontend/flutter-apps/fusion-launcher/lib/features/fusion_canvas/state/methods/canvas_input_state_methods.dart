part of '../fusion_canvas_input_state.dart';

extension KeyboardStateExtension on FusionCanvasInputState {
  bool get isShiftPressed => pressedKeys.contains(LogicalKeyboardKey.shiftLeft) || pressedKeys.contains(LogicalKeyboardKey.shiftRight);

  bool get isEscPressed => pressedKeys.contains(LogicalKeyboardKey.escape);

  bool get isEnterPressed => pressedKeys.contains(LogicalKeyboardKey.enter) || pressedKeys.contains(LogicalKeyboardKey.numpadEnter);
}
