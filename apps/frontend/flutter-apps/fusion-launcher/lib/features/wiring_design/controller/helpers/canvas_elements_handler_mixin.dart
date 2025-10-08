part of '../circuit_controller.dart';

mixin _CanvasElementsHandlerMixin on CanvasHandlerMixin {
  List<CircuitComponent> get components;
  List<Wire> get wires;

  @protected
  CircuitController get self;

  CanvasElement? selectedElement;
  Offset? elementDragPosition;
  List<Offset> intermediateJoints = <Offset>[];

  void selectElement(CanvasElement? element) {
    selectedElement = element;
    saveState();
  }

  void onMoveStart(CanvasElement? element, Offset position) {
    elementDragPosition = position;
    selectElement(element);
  }

  void onMoveUpdate(Offset delta) {
    if (selectedElement == null) {
      onPanUpdate(delta);

      return;
    }
    elementDragPosition =
        (elementDragPosition ?? selectedElement?.position ?? Offset.zero) +
        delta;
    if (selectedElement is CircuitComponent) {
      final CircuitComponent component = selectedElement as CircuitComponent;
      // component.position += delta;
      component.changePosition(delta);
    }
    if (selectedElement is CircuitPort) {
      intermediateJoints = self.pathFinder.findPath(
        (selectedElement as CircuitPort).absolutePositionWithOffset,
        elementDragPosition!,
      );
    }
    notifyListeners();
  }

  void onMoveEnd(CanvasElement? element, Offset position) {
    elementDragPosition = null;
    if (element is CircuitPort && selectedElement is CircuitPort) {
      intermediateJoints = <Offset>[];
      self.addWire(selectedElement as CircuitPort, element);
    }
    saveState();
  }
}
