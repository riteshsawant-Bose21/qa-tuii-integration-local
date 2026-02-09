import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A customizable and reusable button widget for the Fusion design system.
///
/// The [FusionAppButton] supports primary and neumorphic styles, loading and
/// disabled states, optional prefix/suffix icons, gradient or solid
/// backgrounds, and full visual customization.
///
/// It adapts automatically to the current theme and provides a consistent
/// user experience across the application.
///
/// ### Features
/// - Supports Primary and Neumorphic button styles
/// - Loading indicator support
/// - Disabled state handling
/// - Prefix and suffix icons
/// - Gradient and solid background support
/// - Theme-aware default colors
/// - Customizable size and border radius
///
/// ### Example usage:
/// ```dart
/// FusionAppButton(
///   label: 'Proceed',
///   onTap: () {
///     // Your action here
///   },
///
///   style: FusionAppButtonStyle.primary,
///
///   width: 160,
///   height: 45,
///
///   backgroundColor: Colors.blue,
///
///   showPrefixIcon: true,
///   prefixIcon: Icons.arrow_back,
///
///   showSuffixIcon: true,
///   suffixIcon: Icons.check,
///
///   isActive: true,
///   isLoading: false,
///
///   textStyle: const TextStyle(
///     fontSize: 18,
///     fontWeight: FontWeight.bold,
///     color: Colors.white,
///   ),
/// )
/// ```
///
/// ### Neumorphic example:
/// ```dart
/// FusionAppButton(
///   label: 'Soft UI',
///   onTap: () {},
///
///   style: FusionAppButtonStyle.neumorphic,
///
///   backgroundColor: Colors.grey.shade200,
///
///   showPrefixIcon: true,
///   prefixIcon: Icons.touch_app,
/// )
/// ```
/// ================= BUTTON STYLES =================

enum FusionAppButtonStyle {
  primary,
  neumorphic,
}

/// ================= MAIN BUTTON =================

class FusionAppButton extends StatefulWidget {
  final String label;
  final Color? backgroundColor;
  final VoidCallback onTap;
  final FusionAppButtonStyle style;
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

  const FusionAppButton({
    super.key,
    this.backgroundColor,
    required this.label,
    required this.onTap,

    this.style = FusionAppButtonStyle.primary,

    this.height = 35,
    this.width = 120,
    this.borderRadius = 12,

    this.textStyle,
    this.horizontalPadding = 12,

    this.gradient,
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
  State<FusionAppButton> createState() => _FusionAppButtonState();
}

/// ================= STATE =================

class _FusionAppButtonState extends State<FusionAppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case FusionAppButtonStyle.primary:
        return _buildPrimary(context);

      case FusionAppButtonStyle.neumorphic:
        return _buildNeumorphic(context);
    }
  }

  // ================= PRIMARY =================

  Widget _buildPrimary(BuildContext context) {
    final bool disabled = !widget.isActive || widget.isLoading;

    final Color effectiveBorderColor =
        disabled && widget.borderColor != Colors.transparent
        ? widget.borderColor.withOpacity(0.4)
        : widget.borderColor;

    return SizedBox(
      width: widget.width,
      height: widget.height,

      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: widget.isActive ? widget.gradient : null,

          color: widget.gradient == null
              ? (widget.backgroundColor ?? context.colorScheme.elevation2)
              : null,

          borderRadius: BorderRadius.circular(widget.borderRadius),

          border: Border.all(color: effectiveBorderColor, width: 1),
        ),

        child: ElevatedButton(
          onPressed: disabled ? null : widget.onTap,

          style: ElevatedButton.styleFrom(
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
          ),

          child: _buildPrimaryContent(context),
        ),
      ),
    );
  }

  // ================= NEUMORPHIC =================

  Widget _buildNeumorphic(BuildContext context) {
    final bool disabled = !widget.isActive || widget.isLoading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),

      onTapCancel: disabled ? null : () => setState(() => _isPressed = false),

      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },

      child: Opacity(
        opacity: disabled ? 0.5 : 1,

        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),

          clipBehavior: _isPressed ? Clip.hardEdge : Clip.none,

          child: FusionContainer(
            color: widget.backgroundColor ?? context.colorScheme.elevation2,
            width: widget.width,
            height: widget.height,

            raised: !_isPressed && !disabled,

            borderRadius: widget.borderRadius,

            alignment: Alignment.center,

            child: _buildNeumorphicContent(context),
          ),
        ),
      ),
    );
  }

  // ================= PRIMARY CONTENT =================

  Widget _buildPrimaryContent(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }

    final Color iconColor = widget.isActive
        ? widget.foregroundColor ?? context.colorScheme.iconWhite
        : (widget.foregroundColor ?? context.colorScheme.iconWhite).withOpacity(
            0.5,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        if (widget.showPrefixIcon && widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: 16, color: iconColor),
          const SizedBox(width: 8),
        ],

        Flexible(
          child: Center(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,

              // textAlign: TextAlign,
              style:
                  widget.textStyle ??
                  TextStyle(
                    fontSize: 16,
                    color: widget.isActive
                        ? context.colorScheme.textLabel
                        : context.colorScheme.elevation3,
                  ),
            ),
          ),
        ),

        if (widget.showSuffixIcon && widget.suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.suffixIcon, size: 16, color: iconColor),
        ],
      ],
    );
  }

  // ================= NEUMORPHIC CONTENT =================

  Widget _buildNeumorphicContent(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          if (widget.showPrefixIcon && widget.prefixIcon != null) ...[
            Icon(widget.prefixIcon, size: 16),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Center(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,

                style:
                    widget.textStyle ??
                    TextStyle(
                      fontSize: 16,
                      color: widget.isActive
                          ? context.colorScheme.textLabel
                          : context.colorScheme.elevation3,
                    ),
              ),
            ),
          ),

          if (widget.showSuffixIcon && widget.suffixIcon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.suffixIcon, size: 16),
          ],
        ],
      ),
    );
  }
}
