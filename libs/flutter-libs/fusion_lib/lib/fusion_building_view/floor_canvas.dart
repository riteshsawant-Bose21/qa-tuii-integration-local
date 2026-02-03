import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../di/service_locator.dart';
import '../fusion_lib.dart';
import '../fusion_utils/image_loader_service.dart';
import 'floor_canvas_controller.dart';
import 'floor_canvas_painter.dart';

class FloorCanvas extends StatefulWidget {
  final double gridSize;

  // external state
  final List<HardwareComponent> hardwareComponents;
  final List<Zone> zones;
  final List<SubZone> subZones;
  final List<ListeningArea> listeningAreas;
  final FloorPlanModel floorPlanEntity;
  final FloorModel floor;
  final double splMin;
  final double splMax;
  final SplPanelData splPanelData;
  final bool showLiveSpl;

  // selection state
  final String? selectedHardwareId;
  final String? selectedListeningAreaId;

  final FloorCanvasController controller;

  // mutation callbacks
  final ValueChanged<FloorPlanModel> onFloorPlanUpdated;

  final ValueChanged<ListeningArea> onUpdateListeningArea;
  final ValueChanged<ListeningArea> onTapListeningArea;
  final ValueChanged<HardwareComponent> onUpdateHardwareComponent;
  final ValueChanged<Offset> onViewportCenterUpdated;
  final ValueChanged<dynamic> onComponentTransformed;
  final ValueChanged<double> onCanvasZoomChanged;
  final ValueChanged<Offset> onCanvasPanChanged;
  final ValueChanged<String?> onSelectedListeningAreaIdChanged;
  final ValueChanged<String?> onSelectedHardwareComponentIdChanged;
  final Function onSelectedFloorPlanIdChanged;
  final Function(HardwareComponent, String? listeningAreaId, String? floorId) moveHardware;
  final Function(ListeningArea newArea, List<HardwareComponent>? hardwaresInsideArea) onAddListeningArea;
  final Function(Offset speakerPosition) addNewHardwareComponent;
  final Map<String, String> listeningAreaToZoneMap;
  final Map<String, String> subZoneToZoneMap;
  final Map<String, String> listeningAreaToSubZoneMap;
  final bool isInSpeakerPlacementMode;

  // Mode state
  final bool isAcousticsMode;

  final Function(PointerDownEvent e)? onRightClick;

  const FloorCanvas({
    super.key,
    this.gridSize = 100,
    required this.hardwareComponents,
    required this.listeningAreas,
    required this.controller,
    required this.onFloorPlanUpdated,
    required this.onAddListeningArea,
    required this.onUpdateListeningArea,
    required this.onUpdateHardwareComponent,
    required this.onViewportCenterUpdated,
    required this.onComponentTransformed,
    required this.floor,
    required this.floorPlanEntity,
    required this.onCanvasZoomChanged,
    required this.onCanvasPanChanged,
    required this.onSelectedListeningAreaIdChanged,
    required this.onSelectedHardwareComponentIdChanged,
    required this.onSelectedFloorPlanIdChanged,
    required this.onTapListeningArea,
    required this.zones,
    required this.subZones,
    required this.splMin,
    required this.splMax,
    required this.moveHardware,
    required this.addNewHardwareComponent,
    required this.splPanelData,
    required this.listeningAreaToZoneMap,
    required this.listeningAreaToSubZoneMap,
    required this.subZoneToZoneMap,
    required this.isAcousticsMode,
    this.selectedHardwareId,
    this.selectedListeningAreaId,
    required this.onRightClick,
    required this.isInSpeakerPlacementMode,
    required this.showLiveSpl,
  });

  @override
  FloorCanvasState createState() => FloorCanvasState();
}

class FloorCanvasState extends State<FloorCanvas> with SingleTickerProviderStateMixin {
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  double _baseZoom = 1.0;
  Offset _basePan = Offset.zero;

  static const double minZoom = 0.05, maxZoom = 5.0;

  bool showSpl = false;

  bool _isPanning = false;
  bool _isDrawing = false;
  final List<Offset> _current = <Offset>[];

  bool _isListeningAreaVertexDragging = false;
  bool _isListeningAreaDragging = false;
  int? _dragIndex;
  int? _dragVertexIndex;
  Offset? _dragStartWorld;
  List<Offset>? _dragOriginal;
  String? highlightedAreaId;

  FloorPlanModel? _tempFloorPlan;

  bool _isImageVertexDrag = false;
  int? _dragImageCorner;
  Offset? _dragImageOpposite;
  late double _imageOrigDiag;
  double? _planOrigW;
  double? _planOrigH;
  bool _isImageSelected = false;
  bool _isImageDragging = false;
  bool _isScaling = false;
  Offset? _imageDragStart;
  ui.Image? _floorPlanImage;
  Offset? _planOrigPosition;

  String? _selectedHardwareComponentId;
  bool _isHardwareComponentDragging = false;
  bool _isHardwareComponentRotating = false;
  late Offset _hardwareComponentDragStart;
  Offset? _hardwareComponentOrigPos;

  Offset? _hoverWorldPos;
  late Offset _lastOffset;
  late Offset _panStart;
  Offset _initialFocal = Offset.zero;

  Size _viewportSize = Size.zero;
  final Map<String, ui.Image> _hardwareImages = <String, ui.Image>{};

  List<HardwareComponent> originalHardwareList = [];
  List<ListeningArea> originalListeningAreaList = [];
  List<Zone> originalZoneList = [];

  Future<void> copyItems() async {
    originalHardwareList = widget.hardwareComponents.map((component) => component.copyWith()).toList();
    originalListeningAreaList = widget.listeningAreas.map((area) => area.copyWith()).toList();
    originalZoneList = widget.zones.map((zone) => zone.copyWith()).toList();
  }

  late final animationController = AnimationController.unbounded(vsync: this)..repeat(min: 0, max: 1, period: const Duration(milliseconds: 1000));
  @override
  void initState() {
    super.initState();

    // Synchronize internal selection state with external parameters
    _selectedHardwareComponentId = widget.selectedHardwareId;
    _updateHighlightIndexFromSelectedListeningArea();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onViewportCenterUpdated(getViewportCenter());
    });

    copyItems();

    _loadAllHardwareImages();

    // _setUpCanvas();

    _loadPlanImage();

    widget.controller.bind(
      onTapListeningArea: widget.onTapListeningArea,
      toggleDraw: () {
        setState(() {
          _isDrawing = !_isDrawing;
          _current.clear();
          highlightedAreaId = null;
          _selectedHardwareComponentId = null;
        });
      },
      toggleSpl: () => setState(() => showSpl = !showSpl),
      fitToView: () => _fitToViewport(),
      deselectAll: () => _deselectAll(),
      loadFloorPlanImage: () => _loadPlanImage(),
      updateView: () => setState(() {}),
      setSelectedHardwareComponent: (HardwareComponent hardwareComponent) {
        // final int idx = widget.hardwareComponents.indexWhere((HardwareComponent sp) => sp.id == hardwareComponent.id);
        // if (idx != -1) {
        print("setting hardware component speaker at pos is selected is ${hardwareComponent.id}");
        setState(() {
          _selectedHardwareComponentId = hardwareComponent.id;
          _isHardwareComponentDragging = false;
          _isHardwareComponentRotating = false;
        });
        // }
      },
      // setHardwareComponentListeningAreaId: (HardwareComponent hardwareComponent) => _updateHardwareComponentListeningAreaId(hardwareComponent),
    );
  }

  @override
  void didUpdateWidget(covariant FloorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync internal selection state when external selection parameters change
    if (widget.selectedHardwareId != oldWidget.selectedHardwareId) {
      _selectedHardwareComponentId = widget.selectedHardwareId;
    }

    if (widget.selectedListeningAreaId != oldWidget.selectedListeningAreaId) {
      _updateHighlightIndexFromSelectedListeningArea();
    }

    // if (widget.floorPlanEntity.id != oldWidget.floorPlanEntity.id) {
    //   _zoomScale = widget.floorPlanEntity.canvasZoom;
    //   _panOffset = widget.floorPlanEntity.canvasPan;
    // }
    if (oldWidget.floorPlanEntity.id != widget.floorPlanEntity.id || oldWidget.floorPlanEntity.imagePath != widget.floorPlanEntity.imagePath) {
      setState(() {
        _floorPlanImage = null;
        _loadPlanImage();
      });
    }
    copyItems();
    _loadAllHardwareImages();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        _viewportSize = constraints.biggest;
        return Stack(
          children: <Widget>[
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: Listener(
                onPointerSignal: _handleScrollWheelZoom,
                onPointerDown: _handleDown,
                onPointerMove: _handleMove,
                onPointerUp: _handleUp,
                onPointerHover: _handleHover,

                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, asyncSnapshot) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: FloorCanvasPainter(
                        animationController: animationController,
                        gridSize: widget.gridSize,
                        zoomScale: _zoomScale,
                        panOffset: _panOffset,
                        listeningAreas: widget.listeningAreas.where((ListeningArea area) => area.isDrawn).toList(),
                        zones: widget.zones,
                        subZones: widget.subZones,
                        current: _current,
                        previewPoint: _isDrawing && _current.isNotEmpty ? _hoverWorldPos : null,
                        highlightedAreaId: highlightedAreaId,
                        floorPlanImageSelected: _isImageSelected || _isImageVertexDrag,
                        hardwareComponents: widget.hardwareComponents,
                        selectedHardwareComponentId: _selectedHardwareComponentId,
                        showSpl: showSpl,
                        floorPlanEntity: _tempFloorPlan ?? widget.floorPlanEntity,
                        floorPlanImage: _floorPlanImage,
                        hardwareImages: _hardwareImages,
                        listeningAreaSelectionActive: widget.controller.isListeningAreaSelectionActive.value,
                        currentlySelectingZone: widget.controller.currentlySelectingZone,
                        currentlySelectingSubZone: widget.controller.currentlySelectingSubZone,
                        selectedListeningAreaIds: [
                          ...widget.controller.selectedListeningAreas.map((ListeningArea s) => s.id),
                          if (widget.selectedListeningAreaId != null) widget.selectedListeningAreaId!,
                        ],
                        splMax: widget.splMax,
                        splMin: widget.splMin,
                        splPanelData: widget.splPanelData,
                        //prepare a map of listening area id to zone
                        listeningAreaToZoneMap: widget.listeningAreaToZoneMap,
                        listeningAreaToSubZoneMap: widget.listeningAreaToSubZoneMap,
                        subZoneToZoneMap: widget.subZoneToZoneMap,
                        isAcousticsMode: widget.isAcousticsMode,
                        showLiveSpl: widget.showLiveSpl,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _loadAllHardwareImages() {
    final ImageLoaderService loader = fusionLibLocator<ImageLoaderService>();
    for (final HardwareComponent comp in widget.hardwareComponents) {
      if (comp is! Speaker) {
        final String path = comp.assetImagePath;
        if (!_hardwareImages.containsKey(path)) {
          loader.loadImage(path).then((ui.Image img) {
            setState(() {
              _hardwareImages[path] = img;
            });
          });
        }
      }
    }
  }

  void _setUpCanvas() {
    final double zoomScaleP = widget.floorPlanEntity.canvasZoom;
    final Offset panOffsetP = widget.floorPlanEntity.canvasPan;

    if (zoomScaleP == 1.0 && panOffsetP == Offset.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToViewport();
      });
    } else {
      setState(() {
        _zoomScale = zoomScaleP;
        _panOffset = panOffsetP;
      });
      widget.onViewportCenterUpdated(getViewportCenter());
    }
  }

  Future<void> _loadPlanImage() async {
    final String imagePath = widget.floorPlanEntity.imagePath;
    if (imagePath.isNotEmpty) {
      final ui.Image img = await fusionLibLocator<ImageLoaderService>().loadImage(imagePath);
      if (!mounted) return;
      setState(() {
        _floorPlanImage = img;
        _fitToViewport();
      });
    }
  }

  List<Offset> get _computedCorners {
    final ui.Offset p = widget.floorPlanEntity.position;
    final double h = widget.floorPlanEntity.size.height;
    if (_floorPlanImage == null) {
      // fallback to stored size if no image
      final double w = widget.floorPlanEntity.size.width;
      return <ui.Offset>[p, p + Offset(w, 0), p + Offset(w, h), p + Offset(0, h)];
    }
    final double ar = _floorPlanImage!.width / _floorPlanImage!.height;
    final double w = h * ar;
    return <ui.Offset>[p, p + Offset(w, 0), p + Offset(w, h), p + Offset(0, h)];
  }

  void _deselectAll() {
    setState(() {
      _selectedHardwareComponentId = null;
      _isHardwareComponentDragging = false;
      _isHardwareComponentRotating = false;
      _isListeningAreaVertexDragging = false;
      _isListeningAreaDragging = false;
      _dragIndex = null;
      _dragVertexIndex = null;
      highlightedAreaId = null;
    });
  }

  void _stopListeningAreaSelection() {
    widget.controller.cancelListeningAreaSelection();
    setState(() {
      highlightedAreaId = null;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) {
      _isScaling = false;
      return;
    }
    _isScaling = true;
    _baseZoom = _zoomScale;
    _basePan = _panOffset;
    _initialFocal = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) {
      _isScaling = false;
      return;
    }

    final Offset focalPoint = details.localFocalPoint;

    final double newZoom = (_baseZoom * details.scale).clamp(minZoom, maxZoom);
    final double zoomFactor = newZoom / _baseZoom;

    final Offset newPan = (_basePan - _initialFocal) * zoomFactor + focalPoint;

    setState(() {
      _zoomScale = newZoom;
      _panOffset = newPan;
    });

    widget.onViewportCenterUpdated(getViewportCenter());
    widget.onCanvasZoomChanged(_zoomScale);
    widget.onCanvasPanChanged(_panOffset);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
  }

  void _handleScrollWheelZoom(PointerSignalEvent p) {
    if (p is PointerScrollEvent) {
      final double d = p.scrollDelta.dy;
      final Offset f = p.localPosition;
      setState(() {
        final double prop = _zoomScale * (1 - d * 0.001);
        final double c = prop.clamp(minZoom, maxZoom);
        final double zf = c / _zoomScale;
        _panOffset = (_panOffset - f) * zf + f;
        _zoomScale = c;
        widget.onViewportCenterUpdated(getViewportCenter());
      });
      widget.onCanvasZoomChanged(_zoomScale);
      widget.onCanvasPanChanged(_panOffset);
    }
  }

  void _handleDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse && e.buttons == kSecondaryMouseButton) {
      widget.onRightClick?.call(e);
      return;
    }

    if (_isScaling) return;
    if (e.kind != PointerDeviceKind.mouse && e.kind != PointerDeviceKind.touch) {
      return;
    }
    final Offset worldPos = (e.localPosition - _panOffset) / _zoomScale;
    if (widget.isInSpeakerPlacementMode) {
      //To check what is under the cursor
      // final ListeningArea? hit = _findListeningAreaAt(worldPos);
      widget.addNewHardwareComponent(worldPos);
      return;
    }

    // PAN
    if (e.buttons == kMiddleMouseButton) {
      _isPanning = true;
      _panStart = e.localPosition;
      _lastOffset = _panOffset;
      return;
    }

    // deselect everything
    _deselectAll();

    // SPEAKER hit‐test
    if (e.buttons == kPrimaryMouseButton) {
      for (int i = widget.hardwareComponents.length - 1; i >= 0; i--) {
        final HardwareComponent sp = widget.hardwareComponents[i];

        // In acoustics mode, only allow selection of speakers
        if (widget.isAcousticsMode && sp is! Speaker) {
          continue;
        }

        // simplest circular hit‐test:
        final double hitRadius = sp is Source ? widget.gridSize : widget.gridSize * 0.3;
        if ((worldPos - sp.pos!).distance < hitRadius) {
          _stopListeningAreaSelection();
          widget.onSelectedHardwareComponentIdChanged(sp.id);
          print(
            "setting speaker hit (${worldPos.dx}, ${worldPos.dy}) to index $i speaker at pos is ${widget.hardwareComponents[i].id}, selected is ${sp.id}",
          );
          setState(() {
            _selectedHardwareComponentId = sp.id;
            _isHardwareComponentDragging = true;
            _hardwareComponentDragStart = worldPos;
            _hardwareComponentOrigPos = sp.pos;
          });
          return;
        }
      }
    }

    // DRAW
    if (_isDrawing) {
      if (e.buttons == kPrimaryMouseButton) {
        if (_current.isNotEmpty && (worldPos - _current.first).distance < 10.0 / _zoomScale) {
          if (_current.length >= 3) {
            if (widget.selectedListeningAreaId != null &&
                widget.listeningAreas.any((area) => (area.id == widget.selectedListeningAreaId && area.vertices.isEmpty))) {
              // Update existing listening area
              final ListeningArea areaToUpdate = widget.listeningAreas.firstWhere((area) => area.id == widget.selectedListeningAreaId);
              final ListeningArea updatedArea = areaToUpdate.copyWith(
                vertices: List<Offset>.of(_current),
                isDrawn: true,
              );
              widget.onUpdateListeningArea(updatedArea);
            } else {
              // Add new listening area
              final ListeningArea newArea = ListeningArea(
                name: "Area ${widget.listeningAreas.length + 1}",
                vertices: List<Offset>.of(_current),
                isDrawn: true,
              );
              // final List<HardwareComponent> hardwareForArea = _getHardwareComponentsInListeningAreas(newArea);
              widget.onAddListeningArea(newArea, []);
            }
          }

          setState(() {
            _current.clear();
            _isDrawing = false;
            widget.controller.isDrawing.value = _isDrawing;
            if (widget.listeningAreas.isNotEmpty) {
              highlightedAreaId = widget.listeningAreas.last.id;
            }
          });
        } else {
          setState(() => _current.add(worldPos));
        }
      } else if (e.buttons == kSecondaryMouseButton) {
        setState(() {
          _current.clear();
          _isDrawing = false;
          widget.controller.isDrawing.value = _isDrawing;
        });
      }
      return;
    }

    // Listening area select mode

    // if (widget.controller.autoPlaceCompleter != null) {
    //   for (final ListeningArea s in widget.listeningAreas) {
    //     final List<ui.Offset> p = s.vertices;
    //     final ui.Path poly = Path()..addPolygon(p, true);
    //     if (poly.contains(worldPos)) {
    //       final List<ui.Offset> points = s.getSpeakerPoints(
    //         spacing: 250.0,
    //         tolerance: 25.0,
    //       );
    //       widget.controller.completeAutoPlace(points);
    //       return;
    //     }
    //   }
    //   widget.controller.completeAutoPlace(null);
    //   return;
    // }

    // Listening area selection mode
    if (widget.controller.isListeningAreaSelectionActive.value) {
      if (e.buttons == kPrimaryMouseButton) {
        for (int i = 0; i < widget.listeningAreas.length; i++) {
          final ListeningArea area = widget.listeningAreas[i];
          final List<ui.Offset> p = area.vertices;
          final ui.Path poly = Path()..addPolygon(p, true);
          if (poly.contains(worldPos)) {
            // Add/remove area from selection
            widget.controller.selectListeningArea(area);

            // Update highlight for visual feedback
            setState(() {
              highlightedAreaId = area.id;
            });
            return;
          }
        }

        // If clicked outside any area, stop selection
        _stopListeningAreaSelection();
      }
      _deselectAll();
      return; // Don't process other interactions during selection
    }

    // POLY‐VERTEX DRAG - only allow in acoustics mode
    if (e.buttons == kPrimaryMouseButton && widget.isAcousticsMode) {
      for (int i = widget.listeningAreas.length - 1; i >= 0; i--) {
        final List<ui.Offset> poly = widget.listeningAreas[i].vertices;
        for (int j = 0; j < poly.length; j++) {
          if ((worldPos - poly[j]).distance < 10.0 / _zoomScale) {
            widget.onSelectedListeningAreaIdChanged(widget.listeningAreas[i].id);
            setState(() {
              _isListeningAreaVertexDragging = true;
              _dragIndex = i;
              _dragVertexIndex = j;
              highlightedAreaId = widget.listeningAreas[i].id;
            });
            return;
          }
        }
      }
    }

    // POLY DRAG - only allow in acoustics mode
    if (e.buttons == kPrimaryMouseButton) {
      for (int i = widget.listeningAreas.length - 1; i >= 0; i--) {
        final List<ui.Offset> poly = widget.listeningAreas[i].vertices;
        final ui.Path path = Path()..addPolygon(poly, true);
        if (path.contains(worldPos)) {
          widget.onSelectedListeningAreaIdChanged(widget.listeningAreas[i].id);
          setState(() {
            _isListeningAreaDragging = true;
            _dragIndex = i;
            _dragStartWorld = worldPos;
            _dragOriginal = List<Offset>.of(poly);
            highlightedAreaId = widget.listeningAreas[i].id;
          });
          return;
        }
      }
    }

    // 1) Vertex‐grab (resize) hit‐test
    final List<ui.Offset> corners = _computedCorners;
    if (e.buttons == kPrimaryMouseButton) {
      for (int i = 0; i < 4; i++) {
        if ((worldPos - corners[i]).distance < 15.0 / _zoomScale) {
          widget.onSelectedFloorPlanIdChanged();
          setState(() {
            _isImageVertexDrag = true;
            _isImageSelected = true;
            _dragImageCorner = i;
            _dragImageOpposite = corners[(i + 2) % 4];
            final double dx = _dragImageOpposite!.dx - corners[i].dx;
            final double dy = _dragImageOpposite!.dy - corners[i].dy;
            _imageOrigDiag = sqrt(dx * dx + dy * dy);
            _planOrigW = dx.abs();
            _planOrigH = dy.abs();
          });
          return;
        }
      }
    }

    // 2) Full‐image drag hit‐test
    if (e.buttons == kPrimaryMouseButton) {
      final ui.Rect rect = Rect.fromLTWH(
        widget.floorPlanEntity.position.dx,
        widget.floorPlanEntity.position.dy,
        widget.floorPlanEntity.size.width,
        widget.floorPlanEntity.size.height,
      );
      if (rect.contains(worldPos)) {
        widget.onSelectedFloorPlanIdChanged();
        setState(() {
          _isImageDragging = true;
          _isImageSelected = true;
          _imageDragStart = worldPos;
          _planOrigPosition = widget.floorPlanEntity.position;
          _tempFloorPlan = widget.floorPlanEntity;
        });
        return;
      }
    }

    // LISTENING AREA CLICK-TO-SELECT (system mode - identification only)
    if (e.buttons == kPrimaryMouseButton && !widget.isAcousticsMode) {
      for (int i = widget.listeningAreas.length - 1; i >= 0; i--) {
        final List<ui.Offset> poly = widget.listeningAreas[i].vertices;
        final ui.Path path = Path()..addPolygon(poly, true);
        if (path.contains(worldPos)) {
          widget.onSelectedListeningAreaIdChanged(widget.listeningAreas[i].id);
          setState(() {
            highlightedAreaId = widget.listeningAreas[i].id;
          });
          return;
        }
      }
    }

    // 3) Simple select/deselect
    if (e.buttons == kPrimaryMouseButton) {
      final ui.Rect rect = Rect.fromLTWH(
        widget.floorPlanEntity.position.dx,
        widget.floorPlanEntity.position.dy,
        widget.floorPlanEntity.size.width,
        widget.floorPlanEntity.size.height,
      );
      setState(() {
        _isImageSelected = rect.contains(worldPos);
        _isImageVertexDrag = false;
      });
      return;
    }
  }

  void _handleMove(PointerMoveEvent e) {
    if (_isScaling) return;
    if (e.kind != PointerDeviceKind.mouse && e.kind != PointerDeviceKind.touch) {
      return;
    }

    final Offset worldPos = (e.localPosition - _panOffset) / _zoomScale;

    // speaker rotate
    // if (_isHardwareComponentRotating && _selectedHardwareComponent != null) {
    //   final HardwareComponent sp = widget.hardwareComponents[_selectedHardwareComponent!];
    //   if (sp is! CanvasSpeaker) return;
    //   final double angle = atan2(worldPos.dy - sp.pos.dy, worldPos.dx - sp.pos.dx);
    //   setState(() => sp.rotation = (_speakerOrigRotation! + (angle - _rotateStartAngle)) % (2 * pi));
    //   widget.onUpdateSpeaker(sp);
    //   return;
    // }

    // hardware component drag
    if (_isHardwareComponentDragging && _selectedHardwareComponentId != null) {
      final HardwareComponent hardwareComponent = widget.hardwareComponents.firstWhere(
        (HardwareComponent sp) => sp.id == _selectedHardwareComponentId,
      );

      // In acoustics mode, only allow movement of speakers
      if (widget.isAcousticsMode && hardwareComponent is! Speaker) {
        return;
      }

      final ui.Offset delta = worldPos - _hardwareComponentDragStart;
      setState(() => hardwareComponent.pos = _hardwareComponentOrigPos! + delta);
      // widget.onUpdateHardwareComponent(hardwareComponent);
      return;
    }

    // pan
    if (_isPanning) {
      setState(() {
        _panOffset = _lastOffset + (e.localPosition - _panStart);
        widget.onViewportCenterUpdated(getViewportCenter());
      });
      return;
    }

    // poly-vertex drag - only allow in acoustics mode
    if (_isListeningAreaVertexDragging && _dragIndex != null && _dragVertexIndex != null) {
      if (!widget.isAcousticsMode) {
        return;
      }
      final ListeningArea cs = widget.listeningAreas[_dragIndex!];
      setState(() {
        cs.vertices[_dragVertexIndex!] = worldPos;
      });
      // widget.onUpdateListeningArea(cs);
      return;
    }

    // poly drag - only allow in acoustics mode
    if (_isListeningAreaDragging && _dragIndex != null && _dragOriginal != null) {
      if (!widget.isAcousticsMode) {
        return;
      }
      final ui.Offset delta = worldPos - _dragStartWorld!;
      final ListeningArea cs = widget.listeningAreas[_dragIndex!];
      final ListeningArea updated = cs.copyWith(vertices: _dragOriginal!.map((ui.Offset pt) => pt + delta).toList());
      setState(() {
        widget.listeningAreas[_dragIndex!] = updated;
      });
      // widget.onUpdateListeningArea(updated);
      return;
    }

    // ─── Floor-plan resize ─────────────────────────────────────────────────────
    // if (_isImageVertexDrag && _dragImageCorner != null && _dragImageOpposite != null) {
    //   // 1) Compute diagonal scaling just like before
    //   final Offset opp = _dragImageOpposite!;
    //   final Offset v = worldPos - opp;
    //   final double diag = v.distance;
    //   final double sf = diag / _imageOrigDiag;
    //   final double newW = _planOrigW! * sf;
    //   final double newH = _planOrigH! * sf;
    //
    //   // 2) Determine new top-left corner and size
    //   //    (we assume the user drags one corner away from ‘opp’)
    //   final Offset newCorner = opp + Offset(v.dx.sign * newW, v.dy.sign * newH);
    //   final double minX = math.min(newCorner.dx, opp.dx);
    //   final double minY = math.min(newCorner.dy, opp.dy);
    //   final Size newSize = Size((newCorner.dx - opp.dx).abs(), (newCorner.dy - opp.dy).abs());
    //
    //   // 3) Build an updated FloorPlanEntity
    //   final FloorPlanModel updated = widget.floorPlanEntity.copyWith(position: Offset(minX, minY), size: newSize);
    //
    //   // 4) Tell the parent/store about it
    //   widget.onFloorPlanUpdated(updated);
    //
    //   return;
    // }

    // ─── Floor plan -image drag ─────────────────────────────────────────────────────────
    if (widget.zones.isNotEmpty || widget.listeningAreas.isNotEmpty || widget.hardwareComponents.isNotEmpty) return;
    if (_isImageDragging && _imageDragStart != null) {
      final ui.Offset worldPos = (e.localPosition - _panOffset) / _zoomScale;
      final ui.Offset delta = worldPos - _imageDragStart!;

      setState(() {
        _tempFloorPlan = _tempFloorPlan!.copyWith(position: _planOrigPosition! + delta);
      });
      return;
    }
  }

  void _handleUp(PointerUpEvent e) {
    if (_isScaling) return;
    if (e.kind != PointerDeviceKind.mouse) return;

    if (_isHardwareComponentRotating) {
      final HardwareComponent hardwareComponent = widget.hardwareComponents.firstWhere(
        (HardwareComponent sp) => sp.id == _selectedHardwareComponentId,
      );

      setState(() {
        _isHardwareComponentRotating = false;
        widget.onComponentTransformed(hardwareComponent);
      });
    }
    if (_isHardwareComponentDragging) {
      // print("is dragging up $_isHardwareComponentDragging is true, calling _updateHardwareComponentListeningAreaId ");
      final HardwareComponent hardwareComponent = widget.hardwareComponents.firstWhere(
        (HardwareComponent sp) => sp.id == _selectedHardwareComponentId,
      );
      setState(() {
        _isHardwareComponentDragging = false;
        // _updateHardwareComponentListeningAreaId(hardwareComponent);
        widget.onComponentTransformed(hardwareComponent);
      });
    }
    if (_isListeningAreaVertexDragging) {
      final ListeningArea cs = widget.listeningAreas[_dragIndex!];
      setState(() {
        _isListeningAreaVertexDragging = false;
        widget.onUpdateListeningArea(cs);
        widget.onComponentTransformed(cs);
      });
    }
    if (_isListeningAreaDragging) {
      final ListeningArea cs = widget.listeningAreas[_dragIndex!];
      final ListeningArea originalArea = originalListeningAreaList.firstWhere((area) => area.id == cs.id);
      setState(() {
        _isListeningAreaDragging = false;
        if (!FusionUtils.areVerticesEqualIgnoringOrder(cs.vertices, originalArea.vertices)) {
          widget.onUpdateListeningArea(cs);
          widget.onTapListeningArea(cs);
          widget.onComponentTransformed(cs);
        }
      });
    }
    if (_isPanning && e.buttons == 0) {
      setState(() => _isPanning = false);
    }
    if (_isImageVertexDrag) {
      setState(() => _isImageVertexDrag = false);
    }

    if (_isImageDragging) {
      widget.onFloorPlanUpdated(_tempFloorPlan!);
      setState(() {
        _isImageDragging = false;
        _imageDragStart = null;
        _planOrigPosition = null;
        _tempFloorPlan = null;
      });
    }
  }

  void _handleHover(PointerHoverEvent e) {
    setState(() => _hoverWorldPos = (e.localPosition - _panOffset) / _zoomScale);
  }

  void _fitToViewport() {
    final List<Offset> all = <Offset>[
      for (ListeningArea s in widget.listeningAreas) ...s.vertices,
      ..._computedCorners,
    ];
    if (all.isEmpty) return;
    final Iterable<double> xs = all.map((ui.Offset p) => p.dx), ys = all.map((ui.Offset p) => p.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);
    final double w = maxX - minX, h = maxY - minY;
    if (w == 0 || h == 0) return;
    const double pad = 50.0;
    final double availW = _viewportSize.width - 2 * pad;
    final double availH = _viewportSize.height - 2 * pad;
    if (availW <= 0 || availH <= 0) return;
    final double sX = availW / w, sY = availH / h;
    final double tar = (sX < sY ? sX : sY).clamp(minZoom, maxZoom);
    final double mX = (_viewportSize.width - w * tar) / 2;
    final double mY = (_viewportSize.height - h * tar) / 2;
    setState(() {
      _zoomScale = tar;
      _panOffset = Offset(mX - minX * tar, (mY - minY * tar) - 30);
      widget.onViewportCenterUpdated(getViewportCenter());
    });
    // widget.onCanvasZoomChanged(_zoomScale);
    // widget.onCanvasPanChanged(_panOffset);
  }

  Offset getViewportCenter() {
    final Offset screenCenter = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final Offset worldCenter = (screenCenter - _panOffset) / _zoomScale;
    return worldCenter;
  }

  // void _updateHardwareComponentListeningAreaId(HardwareComponent hardwareComponent) {
  //   // Find the listening area at the component’s position (if any)
  //   final ListeningArea? hit = _findListeningAreaAt(hardwareComponent.pos!);

  //   // Determine the new listeningAreaId (use empty string when none)
  //   final String newListeningAreaId = hit?.id ?? '';

  //   final HardwareComponent originalHardware = originalHardwareList.firstWhere(
  //     (comp) => comp.id == hardwareComponent.id,
  //   );

  //   print(
  //     "Original hardware listeningAreaId: ${originalHardware.locationEntity.listeningAreaId}, New listeningAreaId: $newListeningAreaId, pos: ${hardwareComponent.pos} vs original pos: ${originalHardware.pos}",
  //   );
  //   if (newListeningAreaId != originalHardware.locationEntity.listeningAreaId || hardwareComponent.pos != originalHardware.pos) {
  //     print("Calling moveHardware with listeningAreaId: $newListeningAreaId , && pos: ${hardwareComponent.pos}");

  //     //new logic
  //     widget.moveHardware(
  //       hardwareComponent,
  //       newListeningAreaId.isNotEmpty ? newListeningAreaId : null,
  //       widget.floor.id,
  //     );
  //   }
  // }

  ListeningArea? _findListeningAreaAt(Offset worldPos) {
    for (final ListeningArea area in widget.listeningAreas) {
      final Path poly = Path()..addPolygon(area.vertices, true);
      if (poly.contains(worldPos)) return area;
    }
    return null;
  }

  List<HardwareComponent> _getHardwareComponentsInListeningAreas(ListeningArea area) {
    final result = <HardwareComponent>[];
    for (final hw in widget.hardwareComponents) {
      if (_isPointInsidePolygon(hw.pos!, area.vertices)) {
        result.add(hw);
      }
    }
    return result;
  }

  /// Ray-casting algorithm for point-in-polygon
  bool _isPointInsidePolygon(Offset point, List<Offset> polygon) {
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      if (((p1.dy > point.dy) != (p2.dy > point.dy)) && (point.dx < (p2.dx - p1.dx) * (point.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx)) {
        intersections++;
      }
    }
    return intersections.isOdd;
  }

  /// Update the internal highlight index based on the external selected listening area ID
  void _updateHighlightIndexFromSelectedListeningArea() {
    print("Updating highlight index from selected listening area id: ${widget.selectedListeningAreaId}");
    if (widget.selectedListeningAreaId != null) {
      // Find the index of the selected listening area
      final int index = widget.listeningAreas.indexWhere(
        (ListeningArea area) => area.id == widget.selectedListeningAreaId,
      );
      if (index != -1) {
        highlightedAreaId = widget.selectedListeningAreaId;
      } else {
        // Selected listening area ID not found, clear highlight
        highlightedAreaId = null;
      }
    } else {
      // No listening area selected externally, clear highlight
      highlightedAreaId = null;
    }
  }
}
