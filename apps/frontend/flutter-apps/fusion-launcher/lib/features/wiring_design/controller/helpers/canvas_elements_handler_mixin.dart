part of '../circuit_controller.dart';

mixin _CanvasElementsHandlerMixin on CanvasHandlerMixin {
  // List<CircuitComponent> get components;
  // List<Wire> get wires;
  WiringState get state;
  @override
  CanvasState get canvasState => state.canvasState;
  @protected
  CircuitController get self;

  // CanvasElement? selectedElement;
  // Offset? elementDragPosition;
  // List<Offset> intermediateJoints = <Offset>[];

  void selectElement(CanvasElement? element) {
    self.setState(element != null ? state.select(element) : state.idle());
    saveState();
  }

  void onMoveStart(CanvasElement? element, Offset position) {
    // elementDragPosition = position;
    // selectElement(element);
    if (element != null) self.setState(state.startMoving(element, position));
  }

  void onMoveUpdate(Offset delta) {
    if (state is ConnectionProgressWiringState) {
      final ConnectionProgressWiringState state2 =
          state as ConnectionProgressWiringState;
      final Offset offset = state2.destination + delta;
      self.setState(
        (state2).moveTo(
          offset,
          self.pathFinder.findPath(
            state2.port.absolutePositionWithOffset,
            offset,
          ),
        ),
      );
    } else if (state is ElementMovingState) {
      final ElementMovingState movingState = state as ElementMovingState;
      self.setState(movingState.move(delta));
    } else {
      onPanUpdate(delta);
    }
    // if (selectedElement == null) {
    //   onPanUpdate(delta);

    //   return;
    // }
    // elementDragPosition =
    //     (elementDragPosition ?? selectedElement?.position ?? Offset.zero) +
    //     delta;
    // if (selectedElement is CircuitComponent) {
    //   final CircuitComponent component = selectedElement as CircuitComponent;
    //   // component.position += delta;
    //   component.changePosition(delta);
    // }
    // if (selectedElement is CircuitPort) {
    // intermediateJoints = self.pathFinder.findPath(
    //   (selectedElement as CircuitPort).absolutePositionWithOffset,
    //   elementDragPosition!,
    // );
    // }
    // notifyListeners();
  }

  void onMoveEnd(CanvasElement? element, Offset position) {
    if (element != null) {
      if (element is CircuitPort && state is ConnectionProgressWiringState) {
        self.addWire((state as ConnectionProgressWiringState).port, element);
      } else {
        self.setState(state.idle());
      }
    } else {
      self.setState(state.idle());
    }
    saveState();
  }
}
