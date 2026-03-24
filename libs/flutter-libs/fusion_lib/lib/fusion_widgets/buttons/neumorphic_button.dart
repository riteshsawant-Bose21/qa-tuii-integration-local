import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A neumorphic-style button for the Fusion design system.
///
/// The [NeumorphicButton] provides a soft, raised surface effect
/// inspired by neumorphism principles. It visually responds to
/// press interactions and supports disabled states.
///
/// This button is ideal for subtle, tactile UI interactions
/// where depth and elevation feedback are important.
///
/// ### Features
/// - Neumorphic raised and pressed visual effect
/// - Press animation using touch feedback
/// - Disabled state with reduced opacity
/// - Customizable size and border radius
/// - Supports text or custom child widgets
/// - Theme-aware text styling
/// - Semantic accessibility support
///
/// ### Example usage:
/// ```dart
/// NeumorphicButton(
///   text: 'Login',
///   onTap: () {
///     // Handle login
///   },
///
///   width: 200,
///   height: 45,
///
///   borderRadius: 14,
///
///   isActive: true,
///
///   textStyle: const TextStyle(
///     fontSize: 16,
///     fontWeight: FontWeight.w600,
///   ),
/// )
/// ```
///
/// ### Example: Custom Child
/// ```dart
/// NeumorphicButton(
///   onTap: () {},
///   width: 180,
///   height: 40,
///
///   child: Row(
///     mainAxisAlignment: MainAxisAlignment.center,
///     children: const [
///       Icon(Icons.favorite, size: 18),
///       SizedBox(width: 6),
///       Text('Like'),
///     ],
///   ),
/// )
/// ```
///
/// ### Example: Disabled State
/// ```dart
/// NeumorphicButton(
///   text: 'Submit',
///   onTap: () {},
///   isActive: false,
/// )
/// ```
///
/// ### Notes
/// - Either [text] or [child] must be provided.
/// - When [isActive] is false, touch events are disabled.
/// - The button shows reduced opacity in disabled mode.
/// - Neumorphic elevation is removed when disabled.
/// - Uses [FusionContainer] for consistent design language.
class NeumorphicButton extends StatefulWidget {
  final String? text;
  final double? width;
  final double? height;
  final double borderRadius;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final Widget? child;
  final Color? color;

  // NEW: Disabled support
  final bool isActive;
  final String semanticId;

  const NeumorphicButton({
    super.key,
    this.text,
    this.width,
    this.height = 35,
    required this.onTap,
    this.borderRadius = 12,
    this.textStyle,
    this.child,
    this.color,
    this.isActive = true,
    required this.semanticId,
    // default enabled
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  bool get _isDisabled => !widget.isActive;

  @override
  Widget build(BuildContext context) {
    assert(widget.text != null || widget.child != null);

    return SemanticHelper.button(
      isEnabled: widget.isActive,
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "neumorphic_button_${widget.text}",
      ),
      child: GestureDetector(
        // Disable gestures
        onTapDown: _isDisabled ? null : (_) => setState(() => _isPressed = true),

        onTapCancel: _isDisabled ? null : () => setState(() => _isPressed = false),

        onTapUp: _isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },

        child: Opacity(
          // Visual disabled effect
          opacity: _isDisabled ? 0.5 : 1,

          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            clipBehavior: _isPressed ? Clip.hardEdge : Clip.none,

            child: FusionContainer(
              width: widget.width,
              height: widget.height,

              // Disable neumorphic raise when disabled
              raised: !_isPressed && !_isDisabled,

              borderRadius: widget.borderRadius,

              alignment: Alignment.center,

              color: widget.color,

              child:
                  widget.child ??
                  FusionAppText(
                    text: widget.text!,
                    style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
