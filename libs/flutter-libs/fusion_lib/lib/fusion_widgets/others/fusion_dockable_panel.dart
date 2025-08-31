import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_expandable_tile_widget.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:flutter/gestures.dart';

/// A dockable and expandable tile widget.
///
/// This widget can stay docked inline (like a normal expandable tile)
/// or be undocked into a draggable floating panel inside an [Overlay].
///
/// ### Features:
/// - **Docked mode:**
///   - Inline with expand/collapse toggle.
///   - Starts floating when dragged.
/// - **Floating mode:**
///   - Draggable anywhere on screen.
///   - Has a close (`X`) button to re-dock (collapses on dock).
///
/// ### Example:
/// ```dart
/// FusionDockablePanel(
///   title: "Project Settings",
///   initiallyExpanded: false,
///   child: Column(
///     children: [
///       Text("Option A"),
///       Text("Option B"),
///     ],
///   ),
/// )
/// ```
class FusionDockablePanel extends StatefulWidget {
  /// Title displayed in the header.
  final String title;

  /// Content widget displayed when expanded.
  final Widget child;

  /// Whether the tile starts expanded (only applies when docked).
  final bool initiallyExpanded;

  const FusionDockablePanel({super.key, required this.title, required this.child, this.initiallyExpanded = false});

  @override
  State<FusionDockablePanel> createState() => _FusionDockablePanelState();
}

class _FusionDockablePanelState extends State<FusionDockablePanel> {
  bool _isExpanded = false;
  bool _isDocked = true;
  Offset _floatingPosition = Offset.zero;
  OverlayEntry? _floatingEntry;
  bool _isDragging = false;
  Offset _dragStartPosition = Offset.zero;
  Offset _localDragOffset = Offset.zero; // Add this to track local offset
  static const double _dragThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Undocks and expands once dropped
  void _undockAt(Offset position) {
    setState(() {
      _isDocked = false;
      _isExpanded = true;
      _floatingPosition = position;
    });
    _insertFloating();
  }

  /// Re-dock and collapse
  void _dock() {
    setState(() {
      _isDocked = true;
      _isExpanded = false;
    });
    _removeFloating();
  }

  /// Inserts the floating tile into the overlay
  void _insertFloating() {
    _removeFloating();
    if (!mounted) return;

    _floatingEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          left: _floatingPosition.dx - _localDragOffset.dx,
          top: _floatingPosition.dy - _localDragOffset.dy,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240, maxHeight: 650), child: _buildFloatingTile()),
          ),
        );
      },
    );

    if (mounted) {
      Overlay.of(context).insert(_floatingEntry!);
    }
  }

  void _removeFloating() {
    _floatingEntry?.remove();
    _floatingEntry = null;
  }

  void _updateFloating() {
    if (_floatingEntry != null && mounted) {
      _floatingEntry!.markNeedsBuild();
    }
  }

  /// Builds the floating tile with custom header and close button
  Widget _buildFloatingTile() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// Custom header with close button for floating mode
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                // Only allow left mouse button or touch
                if (event.kind == PointerDeviceKind.mouse && event.buttons != kPrimaryMouseButton) {
                  _isDragging = false; // block drag
                  return;
                }
                _isDragging = true;
                _dragStartPosition = event.position;
              },

              onPointerUp: (_) => _isDragging = false,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  if (_isDragging) {
                    setState(() {
                      _floatingPosition += details.delta;
                    });
                    _updateFloating();
                  }
                },
                onPanEnd: (_) {
                  _isDragging = false;
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.white,
                    border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(text: widget.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 9)),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 16), onPressed: _dock, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Content area
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
              ),
              child: SingleChildScrollView(
                // no pysics to allow nested scrolling
                physics: const ClampingScrollPhysics(),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockedTile() {
    return FusionExpandableTileWidget(
      title: widget.title,
      initiallyExpanded: _isExpanded,
      child: widget.child,
      // onExpansionChanged: (bool expanded) {
      //   setState(() {
      //     _isExpanded = expanded;
      //   });
      // },
      onPanStart: (DragStartDetails details) {
        _isDragging = false;
        _dragStartPosition = details.globalPosition;
        _localDragOffset = details.localPosition; // Capture local offset
      },
      onPanUpdate: (DragUpdateDetails details) {
        final double dragDistance = (details.globalPosition - _dragStartPosition).distance;
        if (!_isDragging && dragDistance > _dragThreshold) {
          _isDragging = true;
          _floatingPosition = details.globalPosition;
          _insertFloating();
        }

        if (_isDragging) {
          _floatingPosition += details.delta;
          _updateFloating();
        }
      },
      onPanEnd: (_) {
        if (_isDragging) {
          _undockAt(_floatingPosition);
        }
        _isDragging = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDocked) {
      return _buildDockedTile();
    }
    return const SizedBox.shrink(); // handled by overlay
  }

  @override
  void dispose() {
    _removeFloating();
    super.dispose();
  }
}
