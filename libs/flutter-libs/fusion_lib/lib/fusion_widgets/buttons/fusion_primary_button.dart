import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A customizable primary action button for the Fusion design system.
///
/// The [FusionPrimaryButton] is intended for high-priority user actions
/// such as form submission, confirmation, or navigation.
///
/// It supports loading and disabled states, optional icons,
/// gradient backgrounds, and full visual customization.
///
/// ### Features
/// - Primary call-to-action styling
/// - Supports gradient and solid backgrounds
/// - Loading indicator support
/// - Disabled and inactive states
/// - Optional prefix and suffix icons
/// - Custom width, height, and border radius
/// - Semantic accessibility support
/// - Theme-aware color integration
///
/// ### Example usage:
/// ```dart
/// FusionPrimaryButton(
///   label: 'Continue',
///   onTap: () {
///     // Handle primary action
///   },
///
///   backgroundColor: Colors.blue,
///
///   showPrefixIcon: true,
///   prefixIcon: Icons.arrow_forward,
///
///   showSuffixIcon: true,
///   suffixIcon: Icons.check,
///
///   isLoading: false,
///   isActive: true,
/// )
/// ```
///
/// ### Example: Gradient Button
/// ```dart
/// FusionPrimaryButton(
///   label: 'Pay Now',
///   onTap: () {},
///
///   gradient: LinearGradient(
///     colors: [Colors.purple, Colors.blue],
///   ),
/// )
/// ```
///
/// ### Example: Loading State
/// ```dart
/// FusionPrimaryButton(
///   label: 'Submitting',
///   isLoading: true,
///   onTap: () {},
/// )
/// ```
///
/// ### Example: Disabled State
/// ```dart
/// FusionPrimaryButton(
///   label: 'Submit',
///   isActive: false,
///   onTap: () {},
/// )
/// ```
///
/// ### Notes
/// - When [isLoading] is true, user interaction is disabled.
/// - When [isActive] is false, the button becomes inactive.
/// - If both [gradient] and [backgroundColor] are provided,
///   the gradient takes priority.
/// - Background rendering is handled by a [DecoratedBox]
///   to support complex visuals.
/// - Uses [ElevatedButton] internally for accessibility.
///
/// Designed to maintain visual consistency across Fusion UI components.
enum _ButtonState {
  normal,
  hover,
  selected,
  disabled,
}

class FusionPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;
  final double horizontalPadding;

  final Gradient? gradient;
  final Color? foregroundColor;
  final Color borderColor;

  final bool isLoading;
  final bool isActive;

  final bool showPrefixIcon;
  final IconData? prefixIcon;

  final bool showSuffixIcon;
  final IconData? suffixIcon;

  final String? accessIdentifier;
  final String? accessLabel;
  final Color? backgroundColor;

  const FusionPrimaryButton({
    super.key,
    required this.label,
    this.backgroundColor,
    required this.onTap,
    this.gradient,
    this.height = 55,
    this.width = 350,
    this.borderRadius = 8,
    this.textStyle,
    this.horizontalPadding = 12,
    this.foregroundColor,
    this.borderColor = Colors.transparent,
    this.isLoading = false,
    this.isActive = true,
    this.showPrefixIcon = false,
    this.prefixIcon,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.accessIdentifier,
    this.accessLabel,
  });

  @override
  State<FusionPrimaryButton> createState() => _FusionPrimaryButtonState();
}

class _FusionPrimaryButtonState extends State<FusionPrimaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = !widget.isActive || widget.isLoading;

    final _ButtonState state = _getState(disabled);

    return MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) => _updateHover(false),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _updatePressed(true),
        onTapUp: disabled ? null : (_) => _updatePressed(false),
        onTapCancel: () => _updatePressed(false),
        child: Semantics(
          label: widget.accessLabel,
          button: true,
          enabled: !disabled,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: DecoratedBox(
              decoration: _buildDecoration(context, state),
              child: ElevatedButton(
                onPressed: disabled ? null : widget.onTap,
                style: _buildButtonStyle(),
                child: _buildContent(context, state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= STATE =================

  _ButtonState _getState(bool disabled) {
    if (disabled) return _ButtonState.disabled;
    if (_isPressed) return _ButtonState.selected;
    if (_isHovered) return _ButtonState.hover;
    return _ButtonState.normal;
  }

  void _updateHover(bool value) {
    if (_isHovered != value) {
      setState(() => _isHovered = value);
    }
  }

  void _updatePressed(bool value) {
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  // ================= STYLE =================

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      elevation: 0,
    );
  }

  BoxDecoration _buildDecoration(
    BuildContext context,
    _ButtonState state,
  ) {
    Color bg;
    Color border;

    switch (state) {
      case _ButtonState.hover:
        bg = context.colorScheme.elevation3;
        border = context.colorScheme.elevation4;
        break;

      case _ButtonState.selected:
        bg = context.colorScheme.elevation2;
        border = context.colorScheme.elevation5;
        break;

      case _ButtonState.disabled:
        bg = context.colorScheme.elevation2;
        border = context.colorScheme.elevation2;
        break;

      default:
        bg = widget.backgroundColor ?? context.colorScheme.elevation3;
        border = widget.borderColor;
    }

    return BoxDecoration(
      color: widget.gradient == null ? bg : null,
      gradient: state == _ButtonState.disabled ? null : widget.gradient,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(color: border),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent(BuildContext context, _ButtonState state) {
    if (widget.isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final Color textColor = _getTextColor(context, state);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.showPrefixIcon && widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: 16, color: textColor),
          const SizedBox(width: 8),
        ],

        Flexible(
          child: Center(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  widget.textStyle ??
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
            ),
          ),
        ),

        if (widget.showSuffixIcon && widget.suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.suffixIcon, size: 16, color: textColor),
        ],
      ],
    );
  }

  Color _getTextColor(BuildContext context, _ButtonState state) {
    switch (state) {
      case _ButtonState.disabled:
        return Colors.grey.shade600;

      case _ButtonState.hover:
        return Colors.white;

      case _ButtonState.selected:
        return Colors.white;

      default:
        return context.colorScheme.textLabel;
    }
  }
}
