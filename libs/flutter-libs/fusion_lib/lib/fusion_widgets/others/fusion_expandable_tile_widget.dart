import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import '../dockable_side_bar/fusion_dock_floating_panel.dart';
import '../text_views/fusion_app_text.dart';

/// A custom expandable tile widget with drag gesture support for Fusion applications.
///
/// This widget provides an expandable/collapsible tile with a title and child content.
/// It supports drag gestures on the title area for interaction with parent widgets,
/// such as for implementing drag-to-dock functionality.
///
/// ### Features:
/// - **Expandable/Collapsible:**
///   - Click to expand/collapse the tile content.
///   - Animated rotating arrow icon provides visual feedback.
/// - **Drag Support:**
///   - Drag gestures on the title area trigger callbacks.
///   - Compatible with dockable panel implementations.
/// - **Fusion Theme Integration:**
///   - Consistent styling with Fusion design system.
///   - Proper color scheme and typography.
///
/// ### Example:
/// ```dart
/// FusionExpandableTileWidget(
///
///     ],
///   ),
/// )
/// ```
class FusionExpandableTileWidget extends StatefulWidget {
  final DockItem item;
  final DockItemConfig config;
  final void Function(DockItem, DraggableDetails) onUndock;
  final void Function(DockItem, bool) onExpansionChanged;
  final ExpansibleController? controller;

  const FusionExpandableTileWidget({
    super.key,
    required this.item,
    required this.config,
    required this.onUndock,
    required this.onExpansionChanged,
    required this.controller,
  });

  @override
  State<FusionExpandableTileWidget> createState() => _FusionExpandableTileWidgetState();
}

/// State class for [FusionExpandableTileWidget] that manages expansion animation.
///
/// Handles the rotation animation for the trailing icon and manages the
/// expansion/collapse state of the tile. Uses [SingleTickerProviderStateMixin]
/// to provide animation controller lifecycle management.
class _FusionExpandableTileWidgetState extends State<FusionExpandableTileWidget> with SingleTickerProviderStateMixin {
  /// Animation controller for the rotating icon animation.
  ///
  /// Controls the 180-degree rotation animation when expanding/collapsing.
  late final AnimationController _rotationController;

  /// Animation that rotates the trailing icon during expand/collapse transitions.
  ///
  /// Rotates from 0 to 0.5 turns (180 degrees) with eased timing.
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller with initial state based on expansion
    _rotationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: widget.config.initiallyExpanded ? 1.0 : 0.0);
    // Configure rotation animation to rotate 180 degrees (0.5 turns)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Handles expansion state changes and triggers icon rotation animation.
  ///
  /// Called by the [ExpansionTile] when the user taps to expand or collapse.
  /// Animates the trailing icon to provide visual feedback.
  ///
  /// [expanded] - `true` if the tile is being expanded, `false` if collapsing.
  void _handleExpansionChanged(bool expanded) {
    if (expanded) {
      _rotationController.forward();
    } else {
      _rotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.white,
          border: Border(bottom: BorderSide(color: theme.colorScheme.dividerColor, width: 1)),
        ),
        child: ExpansionTile(
          key: ValueKey<String>(widget.config.title),
          minTileHeight: 24,
          controller: widget.controller,
          dense: true,
          tilePadding: const EdgeInsets.only(right: 16, left: 16),
          trailing: _RotatingIcon(animation: _rotationAnimation, color: theme.colorScheme.fusionTextViewColor),
          onExpansionChanged: _handleExpansionChanged,
          iconColor: theme.colorScheme.fusionTextViewColor,
          collapsedIconColor: theme.colorScheme.fusionTextViewColor,
          title: Draggable<DockItem>(
            data: widget.item,
            feedback: FloatingWidget(
              item: widget.item,
              config: widget.config,
              resizing: false,
              onClose: () {}, // No-op for feedback
              onResize: (_, __) {}, // No-op for feedback
            ),

            /// make the original widget semi transparent when dragging
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: FusionAppText(text: widget.config.title, style: Theme.of(context).textTheme.labelSmall),
              ),
            ),

            /// Only allow undocking if config allows it
            onDragEnd: (details) => widget.config.allowUndock ? widget.onUndock(widget.item, details) : null,
            child: FusionAppText(text: widget.config.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ),

          initiallyExpanded: widget.config.initiallyExpanded,
          children: <Widget>[widget.config.dockItemWidget],
        ),
      ),
    );
  }
}

/// A rotating icon widget that animates based on expansion state.
///
/// Displays a downward-pointing arrow icon that rotates 180 degrees during
/// the expand/collapse animation to provide visual feedback to users.
/// The icon points down when collapsed and up when expanded.
class _RotatingIcon extends StatelessWidget {
  const _RotatingIcon({required this.animation, required this.color});

  /// The animation that drives the rotation transformation.
  ///
  /// Should be a value between 0.0 (no rotation) and 0.5 (180 degrees).
  final Animation<double> animation;

  /// The color to apply to the icon.
  ///
  /// Should match the theme's text color for consistency.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) => RotationTransition(
        turns: animation,
        child: Icon(Icons.arrow_drop_down_rounded, size: 22, color: color),
      ),
    );
  }
}
