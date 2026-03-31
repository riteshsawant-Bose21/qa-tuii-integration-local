// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/fusion_canvas_input_state.dart';

class FusionCanvasInputViewModel extends Cubit<FusionCanvasInputState> {
  FusionCanvasInputViewModel() : super(const FusionCanvasInputIdleState());

  /// Distance threshold to consider a movement as drag (in logical pixels).
  static const double _dragThreshold = 5.0;

  /// Converts pointer button index to FusionMouseButton enum.
  static FusionMouseButton buttonFromPointerButton(int buttons) {
    if (buttons & 0x01 != 0) return FusionMouseButton.left;
    if (buttons & 0x02 != 0) return FusionMouseButton.right;
    if (buttons & 0x04 != 0) return FusionMouseButton.middle;
    if (buttons & 0x08 != 0) return FusionMouseButton.stylus;
    return FusionMouseButton.unknown;
  }

  /// Updates the mouse position. Handles state transitions based on current state.
  void updateMousePosition(Offset? position, Offset? delta) {
    final FusionCanvasInputState currentState = state;
    if (position == null) {
      // If position is null, reset to idle but keep pressed keys
      emit(
        FusionCanvasInputIdleState(
          mousePosition: null,
          pressedKeys: currentState.pressedKeys,
        ),
      );
      return;
    }
    // Handle TapDown → Dragging transition
    if (currentState is FusionCanvasInputTapDownState) {
      final double distance = (position - currentState.tapPosition).distance;
      if (distance > _dragThreshold) {
        emit(
          FusionCanvasInputDraggingState(
            startPosition: currentState.tapPosition,
            currentPosition: position,
            delta: position - currentState.tapPosition,
            button: currentState.button,
            mousePosition: position,
            pressedKeys: currentState.pressedKeys,
          ),
        );
        return;
      }
      // Still within threshold, just update mouse position
      emit(currentState.copyWith(mousePosition: position));
      return;
    }

    // Handle ongoing Dragging state
    if (currentState is FusionCanvasInputDraggingState) {
      emit(
        currentState.copyWith(
          currentPosition: position,
          delta: delta ?? position - currentState.currentPosition,
          mousePosition: position,
        ),
      );
      return;
    }

    // Handle TapUp → Idle transition
    if (currentState is FusionCanvasInputTapUpState) {
      emit(
        FusionCanvasInputIdleState(
          mousePosition: position,
          pressedKeys: currentState.pressedKeys,
        ),
      );
      return;
    }

    // Default: just update mouse position
    emit(currentState.copyWith(mousePosition: position));
  }

  /// Handles key events and updates pressed keys.
  void onKeyEvent(KeyEvent event) {
    final LogicalKeyboardKey logicalKey = event.logicalKey;
    if (event is KeyDownEvent) {
      if (!state.pressedKeys.contains(logicalKey)) {
        emit(
          state.copyWith(
            pressedKeys: List<LogicalKeyboardKey>.from(state.pressedKeys)..add(logicalKey),
          ),
        );
      }
    } else if (event is KeyUpEvent) {
      emit(
        state.copyWith(
          pressedKeys: List<LogicalKeyboardKey>.from(state.pressedKeys)..remove(logicalKey),
        ),
      );
    }
  }

  /// Emits a tap up event state. Derives gesture origin from current state.
  void onTapUp(Offset position, {int buttons = 0x01}) {
    final FusionCanvasInputState currentState = state;

    final FusionMouseButton button;
    final FusionGestureOrigin gestureOrigin;

    switch (currentState) {
      case FusionCanvasInputTapDownState():
        button = currentState.button;
        gestureOrigin = FusionGestureOrigin.click;
      case FusionCanvasInputDraggingState():
        button = currentState.button;
        gestureOrigin = FusionGestureOrigin.drag;
      case FusionCanvasInputDoubleTapState():
        button = buttonFromPointerButton(buttons);
        gestureOrigin = FusionGestureOrigin.doubleTap;
      case FusionCanvasInputLongPressState():
        button = buttonFromPointerButton(buttons);
        gestureOrigin = FusionGestureOrigin.longPress;
      default:
        button = buttonFromPointerButton(buttons);
        gestureOrigin = FusionGestureOrigin.unknown;
    }

    emit(
      FusionCanvasInputTapUpState(
        tapPosition: position,
        button: button,
        gestureOrigin: gestureOrigin,
        mousePosition: position,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  /// Emits a tap down event state.
  void onTapDown(Offset position, {int buttons = 0x01}) {
    emit(
      FusionCanvasInputTapDownState(
        tapPosition: position,
        button: buttonFromPointerButton(buttons),
        mousePosition: position,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  /// Emits a double tap event state.
  void onDoubleTap(Offset position, {int buttons = 0x01}) {
    emit(
      FusionCanvasInputDoubleTapState(
        tapPosition: position,
        mousePosition: position,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  /// Emits a long press event state.
  void onLongPress(Offset position, {int buttons = 0x01}) {
    emit(
      FusionCanvasInputLongPressState(
        pressPosition: position,
        mousePosition: state.mousePosition,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  /// Emits a secondary tap (right-click) event state.
  void onSecondaryTap(Offset position, {int buttons = 0x02}) {
    emit(
      FusionCanvasInputSecondaryTapState(
        tapPosition: position,
        button: buttonFromPointerButton(buttons),
        mousePosition: state.mousePosition,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  /// Emits a middle click event state.
  void onMiddleClick(Offset position) {
    emit(
      FusionCanvasInputTapUpState(
        tapPosition: position,
        button: FusionMouseButton.middle,
        gestureOrigin: FusionGestureOrigin.click,
        mousePosition: position,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  /// Resets to idle state while preserving mouse position and pressed keys.
  void resetToIdle() {
    emit(
      FusionCanvasInputIdleState(
        mousePosition: state.mousePosition,
        pressedKeys: state.pressedKeys,
      ),
    );
  }
}
