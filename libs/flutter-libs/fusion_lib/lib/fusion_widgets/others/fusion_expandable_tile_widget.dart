import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

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
///   title: "Settings Panel",
///   initiallyExpanded: false,
///   onPanStart: (details) => _handleDragStart(details),
///   onPanUpdate: (details) => _handleDragUpdate(details),
///   onPanEnd: (details) => _handleDragEnd(details),
///   child: Column(
///     children: [
///       ListTile(title: Text("Option 1")),
///       ListTile(title: Text("Option 2")),
///     ],
///   ),
/// )
/// ```
class FusionExpandableTileWidget extends StatefulWidget {
  /// The title text displayed in the tile header.
  final String title;

  /// The widget content displayed when the tile is expanded.
  final Widget child;

  /// Whether the tile should be initially expanded when first rendered.
  ///
  /// Defaults to `false` (collapsed state).
  final bool initiallyExpanded;

  /// Callback triggered when a pan gesture starts on the title area.
  ///
  /// Provides [DragStartDetails] containing the initial touch position.
  /// Used for drag-to-dock or similar interactions.
  final GestureDragStartCallback? onPanStart;

  /// Callback triggered during pan gesture updates on the title area.
  ///
  /// Provides [DragUpdateDetails] with delta and position information
  /// for continuous drag tracking and visual feedback.
  final GestureDragUpdateCallback? onPanUpdate;

  /// Callback triggered when a pan gesture ends on the title area.
  ///
  /// Provides [DragEndDetails] with velocity information.
  /// Used to complete drag operations or handle drop logic.
  final GestureDragEndCallback? onPanEnd;

  const FusionExpandableTileWidget({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
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
    _rotationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: widget.initiallyExpanded ? 1.0 : 0.0);
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
          minTileHeight: 24,
          dense: true,
          tilePadding: const EdgeInsets.only(right: 8, left: 16),
          trailing: _RotatingIcon(animation: _rotationAnimation, color: theme.colorScheme.fusionTextViewColor),
          onExpansionChanged: _handleExpansionChanged,
          iconColor: theme.colorScheme.fusionTextViewColor,
          collapsedIconColor: theme.colorScheme.fusionTextViewColor,
          title: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: widget.onPanStart,
              onPanUpdate: widget.onPanUpdate,
              onPanEnd: widget.onPanEnd,
              child: _SectionTitle(title: widget.title),
            ),
          ),

          initiallyExpanded: widget.initiallyExpanded,
          children: <Widget>[widget.child],
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
        child: Icon(Icons.keyboard_arrow_down, size: 16, color: color),
      ),
    );
  }
}

/// A styled title text widget for the expandable tile header.
///
/// Applies consistent text styling with Fusion theme typography
/// and small font size appropriate for compact tile headers.
/// The text is interactive and can receive pan gestures for drag operations.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  /// The title text to display in the tile header.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 9));
  }
}
