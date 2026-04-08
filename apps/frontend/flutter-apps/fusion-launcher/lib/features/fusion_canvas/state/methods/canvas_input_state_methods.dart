
part of  '../fusion_canvas_input_state.dart';

extension KeyboardStateExtension on FusionCanvasInputState {
  bool get isShiftPressed => pressedKeys.contains(LogicalKeyboardKey.shiftLeft) || pressedKeys.contains(LogicalKeyboardKey.shiftRight);
}
