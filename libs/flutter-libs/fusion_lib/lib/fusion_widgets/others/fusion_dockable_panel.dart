import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_expandable_tile_widget.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:flutter/gestures.dart';

/// A dockable and expandable tile widget with auto-dock feature.
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
///   - **Auto-dock:** Automatically docks when dragged near original position.
///
/// ### Example:
/// ```dart
/// FusionDockablePanel(
///   title: "Project Settings",
///   initiallyExpanded: false,
///   autoDockDistance: 50.0, // pixels
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

  /// Distance in pixels from original position to trigger auto-dock.
  /// Set to 0 to disable auto-dock feature.
  final double autoDockDistance;

  /// Whether to show visual feedback when in auto-dock range.
  final bool showAutoDockFeedback;

  const FusionDockablePanel({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.autoDockDistance = 80.0,
    this.showAutoDockFeedback = true,
  });

  @override
  State<FusionDockablePanel> createState() => _FusionDockablePanelState();
}

class _FusionDockablePanelState extends State<FusionDockablePanel> {
  bool _isExpanded = false;
  bool _isDocked = true;
  Offset _floatingPosition = Offset.zero;
  Offset _originalPosition = Offset.zero; // Store original position for auto-dock
  OverlayEntry? _floatingEntry;
  bool _isDragging = false;
  bool _isInAutoDockRange = false;
  bool _wasExpandedWhenDocked = false; // Track expansion state when docked
  Offset _dragStartPosition = Offset.zero;
  Offset _localDragOffset = Offset.zero;
  static const double _dragThreshold = 10.0;

  /// Global key to get widget's position
  final GlobalKey _dockedWidgetKey = GlobalKey();

  /// Z-index for this panel
  int _zIndex = 1000;

  /// Static registry to manage all floating panels
  static final List<_FusionDockablePanelState> _floatingPanels = [];
  static int _nextZIndex = 1000;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Gets the current position of the docked widget
  Offset _getDockedWidgetPosition() {
    final RenderBox? renderBox = _dockedWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }

  /// Checks if floating panel is within auto-dock range
  bool _isWithinAutoDockRange() {
    if (widget.autoDockDistance <= 0) return false;

    final double distance = (_floatingPosition - _originalPosition).distance;
    return distance <= widget.autoDockDistance;
  }

  /// Updates auto-dock visual feedback
  void _updateAutoDockFeedback() {
    final bool inRange = _isWithinAutoDockRange();
    if (_isInAutoDockRange != inRange) {
      setState(() {
        _isInAutoDockRange = inRange;
      });
      _updateFloating();
    }
  }

  /// Undocks while maintaining current expansion state
  void _undockAt(Offset position) {
    // Store the original position when undocking
    _originalPosition = _getDockedWidgetPosition();
    // Store the expansion state when it was docked
    _wasExpandedWhenDocked = _isExpanded;

    setState(() {
      _isDocked = false;
      // Keep the current expansion state, don't force expand
      _floatingPosition = position;
      _isInAutoDockRange = false;
    });
    _insertFloating();
  }

  /// Re-dock and collapse
  void _dock() {
    setState(() {
      _isDocked = true;
      // Restore the expansion state it had when docked
      _isExpanded = _wasExpandedWhenDocked;
      _isInAutoDockRange = false;
    });
    _removeFloating();
  }

  /// Auto-dock if within range
  void _tryAutoDock() {
    if (_isWithinAutoDockRange()) {
      _dock();
    }
  }

  /// Brings this floating panel to the front
  void _bringToFront() {
    if (!_isDocked && _floatingEntry != null) {
      // Remove and re-insert this entry → makes it the topmost
      _floatingEntry!.remove();
      Overlay.of(context).insert(_floatingEntry!);

      // Assign new z-index (optional if you’re not sorting)
      _zIndex = ++_nextZIndex;

      // Update all floating panels to redraw correctly
      for (final panel in _floatingPanels) {
        if (panel.mounted && panel._floatingEntry != null) {
          panel._updateFloating();
        }
      }
    }
  }

  /// Register this panel when it becomes floating
  void _registerFloatingPanel() {
    if (!_floatingPanels.contains(this)) {
      _floatingPanels.add(this);
      _zIndex = ++_nextZIndex;
    }
  }

  /// Unregister this panel when it's no longer floating
  void _unregisterFloatingPanel() {
    _floatingPanels.remove(this);
  }

  /// Inserts the floating tile into the overlay
  void _insertFloating() {
    _removeFloating();
    if (!mounted) return;

    // Register this panel and assign z-index
    _registerFloatingPanel();

    _floatingEntry = OverlayEntry(
      builder: (BuildContext context) {
        // Sort all floating panels by z-index to determine rendering order
        final sortedPanels = List<_FusionDockablePanelState>.from(_floatingPanels)..sort((a, b) => a._zIndex.compareTo(b._zIndex));

        // Find our position in the sorted list
        final ourIndex = sortedPanels.indexOf(this);
        final isTopmost = ourIndex == sortedPanels.length - 1;

        return Positioned(
          left: _floatingPosition.dx - _localDragOffset.dx,
          top: _floatingPosition.dy - _localDragOffset.dy,
          child: Material(
            elevation: _isInAutoDockRange && widget.showAutoDockFeedback ? 16 : (isTopmost ? 12 : 8), // Higher elevation for topmost panel
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: _isInAutoDockRange && widget.showAutoDockFeedback ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                // Add subtle overlay for non-topmost panels
                color: isTopmost ? null : Colors.black.withOpacity(0.05),
              ),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240, maxHeight: 650), child: _buildFloatingTile()),
            ),
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
    _unregisterFloatingPanel();
  }

  void _updateFloating() {
    if (_floatingEntry != null && mounted) {
      _floatingEntry!.markNeedsBuild();
    }
  }

  /// Builds the floating tile with custom header and close button
  Widget _buildFloatingTile() {
    // When dragging and was docked, show collapsed view regardless of expansion state
    final bool shouldShowContent = _isExpanded && !(_isDocked && _isDragging && _wasExpandedWhenDocked);

    return GestureDetector(
      // Bring to front when tapped anywhere on the panel
      onTap: () {
        _bringToFront();
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /// Custom header with close button for floating mode
            MouseRegion(
              cursor: SystemMouseCursors.move,
              child: Listener(
                onPointerDown: (PointerDownEvent event) {
                  // Bring to front when starting to drag
                  _bringToFront();

                  // Only allow left mouse button or touch
                  if (event.kind == PointerDeviceKind.mouse && event.buttons != kPrimaryMouseButton) {
                    _isDragging = false;
                    return;
                  }
                  _isDragging = true;
                  _dragStartPosition = event.position;
                },
                onPointerUp: (_) {
                  if (_isDragging) {
                    _tryAutoDock(); // Check for auto-dock on release
                  }
                  _isDragging = false;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    if (_isDragging) {
                      setState(() {
                        _floatingPosition += details.delta;
                      });
                      _updateAutoDockFeedback();
                      _updateFloating();
                    }
                  },
                  onPanEnd: (_) {
                    if (_isDragging) {
                      _tryAutoDock(); // Check for auto-dock on pan end
                    }
                    _isDragging = false;
                  },
                  onTap: () {
                    // Toggle expansion when tapping the header (if not dragging)
                    if (!_isDragging) {
                      _bringToFront(); // Also bring to front when expanding/collapsing
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                      _updateFloating();
                    }
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isInAutoDockRange && widget.showAutoDockFeedback
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.white,
                      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Drag handle indicator
                        Container(
                          width: 12,
                          height: 4,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                        ),
                        // Expand/collapse icon
                        Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FusionAppText(text: widget.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 9)),
                        ),
                        // Auto-dock indicator
                        if (_isInAutoDockRange && widget.showAutoDockFeedback)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.home, size: 12, color: Theme.of(context).colorScheme.primary),
                          ),
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: _dock, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Content area - only show when expanded and not dragging a docked panel
            if (shouldShowContent)
              Flexible(
                child: GestureDetector(
                  // Bring to front when tapping content area
                  onTap: () {
                    _bringToFront();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
                    ),
                    child: SingleChildScrollView(physics: const ClampingScrollPhysics(), child: widget.child),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockedTile() {
    return Container(
      key: _dockedWidgetKey,
      child: FusionExpandableTileWidget(
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
          _localDragOffset = details.localPosition;
          // Update original position when drag starts
          _originalPosition = _getDockedWidgetPosition();
          // Store the current expansion state
          _wasExpandedWhenDocked = _isExpanded;
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
            _updateAutoDockFeedback();
            _updateFloating();
          }
        },
        onPanEnd: (_) {
          if (_isDragging) {
            // Check for auto-dock before undocking
            if (_isWithinAutoDockRange()) {
              _dock();
            } else {
              _undockAt(_floatingPosition);
            }
          }
          _isDragging = false;
        },
      ),
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
