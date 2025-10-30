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
  }

  void onMoveEnd(CanvasElement? element, Offset position) {
    if (element != null) {
      if (element is CircuitPort && state is ConnectionProgressWiringState) {
        self.addWire((state as ConnectionProgressWiringState).port, element);
        saveState();
        return;
      }
    }
    if (state is! IdleWiringState) self.setState(state.idle());

    saveState();
  }

  void fitToViewPort() {
    if (state.components.isEmpty) return;
    final Size viewportSize = canvasSize ?? const Size(700, 700);
    // Compute bounding box of all components
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final CircuitComponent component in state.components) {
      final ui.Rect rect =
          Obstacle(component.position & component.size).expanded;

      minX = rect.left < minX ? rect.left : minX;
      minY = rect.top < minY ? rect.top : minY;
      maxX = rect.right > maxX ? rect.right : maxX;
      maxY = rect.bottom > maxY ? rect.bottom : maxY;
    }

    final ui.Rect boundingRect = Rect.fromLTRB(minX, minY, maxX, maxY);

    // Calculate scale to fit entire bounding box into viewport
    final double scaleX = viewportSize.width / boundingRect.width;
    final double scaleY = viewportSize.height / boundingRect.height;
    final double newScale =
        (scaleX < scaleY ? scaleX : scaleY) * 0.9; // add margin

    // Center the bounding rect inside viewport
    final Offset contentCenter = boundingRect.center;
    final Offset viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    final Offset newOffset = viewportCenter - (contentCenter * newScale);
    setCanvasState(IdleCanvasState(offset: newOffset, scale: newScale));
  }
}
