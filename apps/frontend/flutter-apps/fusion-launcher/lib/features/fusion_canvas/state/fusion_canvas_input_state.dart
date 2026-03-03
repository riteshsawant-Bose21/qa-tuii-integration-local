// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enum representing mouse button types.
enum FusionMouseButton {
  left,
  right,
  middle,
  stylus,
  unknown,
}

/// Enum representing the origin/type of gesture that led to a tap up event.
enum FusionGestureOrigin {
  /// Simple click without dragging
  click,

  /// Drag gesture ended
  drag,

  /// Double tap gesture
  doubleTap,

  /// Long press gesture
  longPress,

  /// Unknown or idle state
  unknown,
}

/// Base state for canvas input containing persistent state like mouse position and pressed keys.
sealed class FusionCanvasInputState {
  final Offset? mousePosition;
  final List<LogicalKeyboardKey> pressedKeys;

  const FusionCanvasInputState({
    required this.mousePosition,
    required this.pressedKeys,
  });

  /// Creates a copy with updated values.
  FusionCanvasInputState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
  });

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return other.mousePosition == mousePosition && listEquals(other.pressedKeys, pressedKeys);
  }

  @override
  int get hashCode => mousePosition.hashCode ^ pressedKeys.hashCode;
}

/// Idle state - no active gesture.
class FusionCanvasInputIdleState extends FusionCanvasInputState {
  const FusionCanvasInputIdleState({
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  @override
  FusionCanvasInputIdleState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
  }) {
    return FusionCanvasInputIdleState(
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return other is FusionCanvasInputIdleState && other.mousePosition == mousePosition && listEquals(other.pressedKeys, pressedKeys);
  }

  @override
  int get hashCode => mousePosition.hashCode ^ pressedKeys.hashCode;
}

/// Tap down event state.
class FusionCanvasInputTapDownState extends FusionCanvasInputState {
  final Offset tapPosition;
  final FusionMouseButton button;

  const FusionCanvasInputTapDownState({
    required this.tapPosition,
    this.button = FusionMouseButton.left,
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  @override
  FusionCanvasInputTapDownState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
    Offset? tapPosition,
    FusionMouseButton? button,
  }) {
    return FusionCanvasInputTapDownState(
      tapPosition: tapPosition ?? this.tapPosition,
      button: button ?? this.button,
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return super == other && other is FusionCanvasInputTapDownState && other.tapPosition == tapPosition && other.button == button;
  }

  @override
  int get hashCode => super.hashCode ^ tapPosition.hashCode ^ button.hashCode;
}

class FusionCanvasInputTapUpState extends FusionCanvasInputState {
  final Offset tapPosition;
  final FusionMouseButton button;
  final FusionGestureOrigin gestureOrigin;

  const FusionCanvasInputTapUpState({
    required this.tapPosition,
    this.button = FusionMouseButton.left,
    this.gestureOrigin = FusionGestureOrigin.click,
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  @override
  FusionCanvasInputTapUpState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
    Offset? tapPosition,
    FusionMouseButton? button,
    FusionGestureOrigin? gestureOrigin,
  }) {
    return FusionCanvasInputTapUpState(
      tapPosition: tapPosition ?? this.tapPosition,
      button: button ?? this.button,
      gestureOrigin: gestureOrigin ?? this.gestureOrigin,
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return super == other &&
        other is FusionCanvasInputTapUpState &&
        other.tapPosition == tapPosition &&
        other.button == button &&
        other.gestureOrigin == gestureOrigin;
  }

  @override
  int get hashCode => super.hashCode ^ tapPosition.hashCode ^ button.hashCode ^ gestureOrigin.hashCode;
}

/// Dragging event state - emitted while user is dragging.
class FusionCanvasInputDraggingState extends FusionCanvasInputState {
  /// The position where the drag started.
  final Offset startPosition;

  /// The current drag position.
  final Offset currentPosition;

  /// The delta from the last position.
  final Offset delta;

  /// The mouse button being used for dragging.
  final FusionMouseButton button;

  const FusionCanvasInputDraggingState({
    required this.startPosition,
    required this.currentPosition,
    this.delta = Offset.zero,
    this.button = FusionMouseButton.left,
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  /// Returns the total offset from start to current position.
  Offset get totalDelta => currentPosition - startPosition;

  @override
  FusionCanvasInputDraggingState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
    Offset? startPosition,
    Offset? currentPosition,
    Offset? delta,
    FusionMouseButton? button,
  }) {
    return FusionCanvasInputDraggingState(
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      delta: delta ?? this.delta,
      button: button ?? this.button,
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return super == other &&
        other is FusionCanvasInputDraggingState &&
        other.startPosition == startPosition &&
        other.currentPosition == currentPosition &&
        other.delta == delta &&
        other.button == button;
  }

  @override
  int get hashCode => super.hashCode ^ startPosition.hashCode ^ currentPosition.hashCode ^ delta.hashCode ^ button.hashCode;
}

/// Double tap event state.
class FusionCanvasInputDoubleTapState extends FusionCanvasInputState {
  final Offset tapPosition;

  const FusionCanvasInputDoubleTapState({
    required this.tapPosition,
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  @override
  FusionCanvasInputDoubleTapState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
    Offset? tapPosition,
  }) {
    return FusionCanvasInputDoubleTapState(
      tapPosition: tapPosition ?? this.tapPosition,
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return super == other && other is FusionCanvasInputDoubleTapState && other.tapPosition == tapPosition;
  }

  @override
  int get hashCode => super.hashCode ^ tapPosition.hashCode;
}

/// Long press event state.
class FusionCanvasInputLongPressState extends FusionCanvasInputState {
  final Offset pressPosition;

  const FusionCanvasInputLongPressState({
    required this.pressPosition,
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  @override
  FusionCanvasInputLongPressState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
    Offset? pressPosition,
  }) {
    return FusionCanvasInputLongPressState(
      pressPosition: pressPosition ?? this.pressPosition,
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return super == other && other is FusionCanvasInputLongPressState && other.pressPosition == pressPosition;
  }

  @override
  int get hashCode => super.hashCode ^ pressPosition.hashCode;
}

/// Secondary tap (right-click) event state.
class FusionCanvasInputSecondaryTapState extends FusionCanvasInputState {
  final Offset tapPosition;
  final FusionMouseButton button;

  const FusionCanvasInputSecondaryTapState({
    required this.tapPosition,
    this.button = FusionMouseButton.right,
    super.mousePosition,
    super.pressedKeys = const <LogicalKeyboardKey>[],
  });

  @override
  FusionCanvasInputSecondaryTapState copyWith({
    Offset? mousePosition,
    List<LogicalKeyboardKey>? pressedKeys,
    Offset? tapPosition,
    FusionMouseButton? button,
  }) {
    return FusionCanvasInputSecondaryTapState(
      tapPosition: tapPosition ?? this.tapPosition,
      button: button ?? this.button,
      mousePosition: mousePosition ?? this.mousePosition,
      pressedKeys: pressedKeys ?? this.pressedKeys,
    );
  }

  @override
  bool operator ==(covariant FusionCanvasInputState other) {
    if (identical(this, other)) return true;

    return super == other && other is FusionCanvasInputSecondaryTapState && other.tapPosition == tapPosition && other.button == button;
  }

  @override
  int get hashCode => super.hashCode ^ tapPosition.hashCode ^ button.hashCode;
}
