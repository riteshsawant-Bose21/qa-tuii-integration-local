import 'package:flutter/material.dart';

import '../algorithm/path_finder_algorithm.dart';
import '../algorithm/wire_router.dart';
import '../model/model.dart';
import 'helpers/canvas_handler_mixin.dart';
import 'helpers/initialization_handler_mixin.dart';

part 'helpers/canvas_elements_handler_mixin.dart';

class CircuitController extends ChangeNotifier
    with CanvasHandlerMixin, _CanvasElementsHandlerMixin {
  CircuitController() {
    initialize();
  }
  final List<CircuitComponent> components = <CircuitComponent>[];
  final List<Wire> wires = <Wire>[];

  List<List<Offset>> get allWireJoints =>
      wires
          .map(
            (Wire wire) => <Offset>[
              wire.from.absolutePositionWithOffset,
              ...wire.joints,
              wire.to.absolutePositionWithOffset,
            ],
          )
          .toList();

  ///
  /// Caching for Performance
  ///

  Map<CircuitComponent, List<Wire>> _compnentWireCache =
      <CircuitComponent, List<Wire>>{};

  final WireRouter wiewRoter = WireRouter(
    basePaths: <PathSide, Map<PathSide, List<Offset>>>{},
    usedPaths: <PathSide, Map<PathSide, List<Wire>>>{},
  );

  void addComponent(CircuitComponent component) {
    components.add(component);
    saveState();
  }

  OrthogonalRouter get pathFinder => OrthogonalRouter(<Rect>[
    ...components.map(
      (CircuitComponent e) => Obstacle(e.position & e.size).expanded,
    ),
  ]);

  void addWire(CircuitPort from, CircuitPort to) {
    final PathSide fromSide = _constructPathSide(from);
    final PathSide toSide = _constructPathSide(to);

    // final base = addPath(fromSide, toSide, from, to);
    final List<Obstacle> obstacles =
        components
            .map((CircuitComponent e) => Obstacle(e.position & e.size))
            .toList();
    final Wire wire = Wire(id: 'id', from: from, to: to, joints: <Offset>[]);
    _compnentWireCache[from.parent] ??= <Wire>[];
    _compnentWireCache[from.parent]!.add(wire);
    _compnentWireCache[to.parent] ??= <Wire>[];
    _compnentWireCache[to.parent]!.add(wire);
    wires.add(wire);
    wiewRoter.addWire(fromSide, toSide, wire, obstacles);
    saveState();
  }

  PathSide _constructPathSide(CircuitPort port) {
    final CircuitComponent parent = port.parent;
    final Side side =
        port.absolutePositionWithOffset.dx > parent.position.dx
            ? Side.right
            : Side.left;
    return PathSide(component: parent, side: side);
  }

  void saveState() {
    // Implement state saving logic here
    notifyListeners();
  }

  @override
  void onMoveUpdate(Offset delta) {
    super.onMoveUpdate(delta);
    if (selectedElement is CircuitComponent) {
      _updateWirePath(selectedElement as CircuitComponent);
    }
  }

  void _updateWirePath(CircuitComponent component) {
    final List<Obstacle> obstacles =
        components
            .map((CircuitComponent e) => Obstacle(e.position & e.size))
            .toList();
    final List<Wire> connectedWires = _compnentWireCache[component] ?? <Wire>[];
    for (final Wire wire in connectedWires) {
      // final path = pathFinder.findPath(
      //   wire.from.absolutePositionWithOffset,
      //   wire.to.absolutePositionWithOffset,
      //   // stops: stops.length > 1 ? [stops[1]] : [],
      // );
      // wire.joints = path;
      wiewRoter.updateRouteForWire(wire, obstacles);
    }
    adjustPaths();
  }

  @override
  CircuitController get self => this;

  void adjustPaths() {
    final List<Obstacle> obstacles =
        components
            .map((CircuitComponent e) => Obstacle(e.position & e.size))
            .toList();
    for (final Wire wire in wires) {
      wiewRoter.updateRouteForWire(wire, obstacles);
    }
    // PathAdjuster(obstacles: [...components]).resolveAll(wires);
    notifyListeners();
    computeBasePaths();
  }

  // Map<PathSide, Map<PathSide, List<Wire>>> usedPaths = {};

  void computeBasePaths() {
    final Map<PathSide, Map<PathSide, List<Offset>>> basePaths =
        <PathSide, Map<PathSide, List<Offset>>>{};
    basePaths.clear();
    for (int i = 0; i < components.length; i++) {
      for (final Side aSide in Side.values) {
        final PathSide compA = PathSide(component: components[i], side: aSide);
        for (int j = 0; j < components.length; j++) {
          if (components[i] == components[j]) continue;
          for (final Side bSide in Side.values) {
            final PathSide compB = PathSide(
              component: components[j],
              side: bSide,
            );
            final Offset start;
            final Offset end;
            const double offset = 20.0;
            switch (aSide) {
              case Side.top:
                start =
                    compA.component.position +
                    Offset(compA.component.size.width / 2, -offset);
              case Side.bottom:
                start =
                    compA.component.position +
                    Offset(
                      compA.component.size.width / 2,
                      compA.component.size.height + offset,
                    );
              case Side.left:
                start =
                    compA.component.position +
                    Offset(-offset, compA.component.size.height / 2);
              case Side.right:
                start =
                    compA.component.position +
                    Offset(
                      compA.component.size.width + offset,
                      compA.component.size.height / 2,
                    );
            }
            switch (bSide) {
              case Side.top:
                end =
                    compB.component.position +
                    Offset(compB.component.size.width / 2, -offset);
              case Side.bottom:
                end =
                    compB.component.position +
                    Offset(
                      compB.component.size.width / 2,
                      compB.component.size.height + offset,
                    );
              case Side.left:
                end =
                    compB.component.position +
                    Offset(-offset, compB.component.size.height / 2);
              case Side.right:
                end =
                    compB.component.position +
                    Offset(
                      compB.component.size.width + offset,
                      compB.component.size.height / 2,
                    );
            }
            final List<Offset> path = pathFinder.findPath(
              start,
              end,
              // thickness: compB.component.ports.length * 15,
            );
            basePaths[compA] ??= <PathSide, List<Offset>>{};
            basePaths[compA]![compB] = path.toList();
            // basePaths[compB] ??= {};
            // basePaths[compB]![compA] = path.reversed.toList();
          }
        }
      }
    }
    wiewRoter.basePaths.addAll(basePaths);
  }
}

class PathSide {
  const PathSide({required this.component, required this.side});
  final CircuitComponent component;
  final Side side;

  @override
  String toString() => 'PathSide(component: $component, side: $side)';

  @override
  bool operator ==(covariant PathSide other) {
    if (identical(this, other)) return true;

    return other.component == component && other.side == side;
  }

  @override
  int get hashCode => component.hashCode ^ side.hashCode;
}

enum Side { top, bottom, left, right }
