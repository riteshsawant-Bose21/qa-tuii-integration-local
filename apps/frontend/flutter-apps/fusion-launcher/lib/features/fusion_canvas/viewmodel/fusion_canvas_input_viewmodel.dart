// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/fusion_canvas_input_state.dart';

class FusionCanvasInputViewModel extends Cubit<FusionCanvasInputState> {
  FusionCanvasInputViewModel() : super(FusionCanvasInputState(mousePosition: null, pressedKeys: <LogicalKeyboardKey>[]));
  final List<FusionInputEventsListener> _listeners = <FusionInputEventsListener>[];

  void updateMousePosition(Offset? position) {
    emit(
      FusionCanvasInputState(
        mousePosition: position,
        pressedKeys: state.pressedKeys,
      ),
    );
  }

  void onKeyEvent(KeyEvent event) {
    final LogicalKeyboardKey logicalKey = event.logicalKey;
    if (event is KeyDownEvent) {
      if (!state.pressedKeys.contains(logicalKey)) {
        emit(
          FusionCanvasInputState(
            mousePosition: state.mousePosition,
            pressedKeys: List<LogicalKeyboardKey>.from(state.pressedKeys)..add(logicalKey),
          ),
        );
      }
    } else if (event is KeyUpEvent) {
      emit(
        FusionCanvasInputState(
          mousePosition: state.mousePosition,
          pressedKeys: List<LogicalKeyboardKey>.from(state.pressedKeys)..remove(logicalKey),
        ),
      );
    }
  }

  void addListener(FusionInputEventsListener listener) {
    _listeners.add(listener);
  }

  void removeListener(FusionInputEventsListener listener) {
    _listeners.remove(listener);
  }

  void onTapUp(Offset position) {
    for (final FusionInputEventsListener listener in _listeners) {
      if (listener.onTapUp != null) {
        listener.onTapUp!(position);
      }
    }
  }

  bool get isShiftPressed => state.pressedKeys.contains(LogicalKeyboardKey.shiftLeft) || state.pressedKeys.contains(LogicalKeyboardKey.shiftRight);

  bool get isControlPressed => state.pressedKeys.contains(LogicalKeyboardKey.controlLeft) || state.pressedKeys.contains(LogicalKeyboardKey.controlRight);

  bool get isMetaPressed => state.pressedKeys.contains(LogicalKeyboardKey.metaLeft) || state.pressedKeys.contains(LogicalKeyboardKey.metaRight);
}

class FusionInputEventsListener {
  final ValueChanged<Offset>? onTapUp;
  FusionInputEventsListener({
    this.onTapUp,
  });
}
