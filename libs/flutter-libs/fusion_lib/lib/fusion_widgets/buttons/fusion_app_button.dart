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
/// ---------------- ENUM ----------------

enum FusionAppButtonStyle {
  primary,
  secondary,
  neumorphic,
  brand,
  tertiary,
  link,
}

/// ---------------- BUTTON ----------------

class FusionAppButton extends StatefulWidget {
  final String? text;
  final FusionAppButtonStyle style;
  final bool enabled;

  final double width;
  final double height;

  final bool showPrefixIcon;
  final IconData? prefixIcon;

  final bool showSuffixIcon;
  final IconData? suffixIcon;

  final bool IconButton;
  final FusionAppButtonStyle IconStyle;

  final VoidCallback? onPressed;
  final Widget? child;
  final String? semanticId;
  const FusionAppButton({
    super.key,
    this.semanticId,
    this.child,
    this.showPrefixIcon = false,
    this.prefixIcon,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.IconButton = false,
    this.IconStyle = FusionAppButtonStyle.primary,
    this.text,
    required this.style,
    this.enabled = true,
    this.width = 358,
    this.height = 48,
    this.onPressed,
  });

  @override
  State<FusionAppButton> createState() => _FusionAppButtonState();
}

class _FusionAppButtonState extends State<FusionAppButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isActive = false;

  bool get _isDisabled => !widget.enabled;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      enabled: _isDisabled,
      label: widget.text,
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "fusion_app_button${widget.semanticId ?? ""}",
      ),
      ontap: widget.onPressed,

      child: MouseRegion(
        onEnter: (_) {
          if (!_isDisabled) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (!_isDisabled) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
              // keep _isActive
            });
          }
        },
        child: GestureDetector(
          onTapDown: _isDisabled
              ? null
              : (_) => setState(() => _isPressed = true),

          onTap: _isDisabled
              ? null
              : () {
                  setState(() {
                    _isActive = !_isActive;
                    _isPressed = false;
                  });

                  widget.onPressed?.call();
                },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: widget.style == FusionAppButtonStyle.tertiary
                ? 180
                : widget.style == FusionAppButtonStyle.link
                ? null
                : widget.child != null
                ? 40
                : widget.width,
            height:
                widget.style == FusionAppButtonStyle.tertiary ||
                    widget.style == FusionAppButtonStyle.link
                ? 24
                : widget.child != null
                ? 40
                : widget.height,
            decoration:
                // widget.style == FusionAppButtonStyle.neumorphic
                //     ? null
                //     :
                _buildDecoration(),
            // alignment: Alignment.center,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  /// ---------------- UI ----------------

  Widget _buildContent() {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "_build_content",
      ),
      child: widget.style == FusionAppButtonStyle.neumorphic
          ? Opacity(
              opacity: _isDisabled ? 0.5 : 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: _isPressed ? Clip.hardEdge : Clip.none,
                child: FusionContainer(
                  raised: !_isPressed,
                  borderRadius: 6,
                  height: widget.height,
                  alignment: Alignment.center,
                  color: () {
                    if (_isDisabled)
                      return context.colorScheme.elevation2;
                    else
                      return context.colorScheme.elevation1;
                  }(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.prefixIcon != null) ...[
                        Icon(
                          widget.prefixIcon,
                          size: 16,
                          color: !widget.enabled
                              ? context.colorScheme.iconDisabled
                              : context.colorScheme.textPrimary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const SizedBox(width: 6),

                      Center(
                        child:
                            widget.child ??
                            FusionAppText(
                              text: widget.text!,
                              style: _textStyle(),
                            ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.suffixIcon != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          widget.suffixIcon,
                          size: 16,
                          color: !widget.enabled
                              ? context.colorScheme.iconDisabled
                              : context.colorScheme.textPrimary,
                        ),
                      ],
                      if (widget.IconButton) ...[
                        const SizedBox(width: 6),
                        // if (widget.IconStyle == FusionAppButtonStyle.primary)
                        //   ...[]
                        // else if (widget.IconStyle == FusionAppButtonStyle.secondary)
                        //   ...[]
                        // else if (widget.IconStyle == FusionAppButtonStyle.neumorphic)
                        //   ...[]
                        // else if (widget.IconStyle == FusionAppButtonStyle.brand)
                        //   ...[]
                        // else if (widget.IconStyle == FusionAppButtonStyle.tertiary)
                        //   ...[]
                        // else if (widget.IconStyle == FusionAppButtonStyle.link)
                        //   ...[]
                        // else ...[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _isDisabled
                                ? context.colorScheme.elevation6
                                : context.colorScheme.primaryWhite,
                          ),
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: () {
                              if (_isDisabled)
                                context.colorScheme.textPlaceholder;
                              else
                                return context.colorScheme.elevation2;
                            }(),
                          ),
                        ),

                        // ],
                        // const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.showPrefixIcon && widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon, size: 16, color: _buttonTextColor),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 6),

                widget.child ??
                    Flexible(
                      child: FusionAppText(
                        text: widget.text!,
                        style: _textStyle(),
                      ),
                    ),

                const SizedBox(width: 6),
                if (widget.showSuffixIcon && widget.suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(widget.suffixIcon, size: 16, color: _buttonTextColor),
                ],
                if (widget.IconButton) ...[
                  const SizedBox(width: 6),

                  // if (widget.IconStyle == FusionAppButtonStyle.primary)
                  //   ...[]
                  // else if (widget.IconStyle == FusionAppButtonStyle.secondary)
                  //   ...[]
                  // else if (widget.IconStyle == FusionAppButtonStyle.neumorphic)
                  //   ...[]
                  // else if (widget.IconStyle == FusionAppButtonStyle.brand)
                  //   ...[]
                  // else if (widget.IconStyle == FusionAppButtonStyle.tertiary)
                  //   ...[]
                  // else if (widget.IconStyle == FusionAppButtonStyle.link)
                  //   ...[]
                  // else ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _isDisabled
                          ? context.colorScheme.elevation6
                          : context.colorScheme.primaryWhite,
                    ),
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: () {
                        if (_isDisabled)
                          if (widget.style == FusionAppButtonStyle.brand)
                            return context.colorScheme.primaryColor;
                          else
                            context.colorScheme.textPlaceholder;
                        else if (widget.style == FusionAppButtonStyle.brand)
                          return context.colorScheme.primaryColor;
                        else
                          return context.colorScheme.elevation2;
                      }(),
                    ),
                  ),

                  // ],
                  // const SizedBox(width: 8),
                ],
              ],
            ),
    );
  }

  /// ---------------- DECORATION ----------------
  Color get _buttonTextColor {
    final colorScheme = context.colorScheme;

    // Disabled
    if (_isDisabled) {
      if (widget.style == FusionAppButtonStyle.brand) {
        return colorScheme.GreenThemeDisabledText;
      }
      return colorScheme.iconDisabled;
    }

    // Brand (enabled)
    if (widget.style == FusionAppButtonStyle.brand) {
      return colorScheme.primaryWhite;
    }

    // Tertiary or Link
    if (widget.style == FusionAppButtonStyle.tertiary ||
        widget.style == FusionAppButtonStyle.link) {
      if (_isDisabled) {
        return colorScheme.iconDisabled;
      }

      if (_isHovered) {
        return colorScheme.iconDefault;
      }

      if (_isActive || _isPressed) {
        return colorScheme.iconWhite;
      }

      return colorScheme.textPrimary;
    }

    // Default
    return colorScheme.textPrimary;
  }

  BoxDecoration _buildDecoration() {
    switch (widget.style) {
      case FusionAppButtonStyle.primary:
        return _primary();

      case FusionAppButtonStyle.secondary:
        return _secondary();

      case FusionAppButtonStyle.neumorphic:
        return _neumorphic();

      case FusionAppButtonStyle.brand:
        return _brand();

      case FusionAppButtonStyle.tertiary:
        return _tertiary();

      case FusionAppButtonStyle.link:
        return _link();
    }
  }

  /// ---------------- STYLES ----------------

  BoxDecoration _primary() {
    return BoxDecoration(
      color: _isDisabled
          ? context.colorScheme.elevation2
          : _isPressed || _isActive
          ? context.colorScheme.elevation2
          : _isHovered
          ? context.colorScheme.elevation3
          : context.colorScheme.elevation2,
      border: Border.all(color: _border(), width: _isPressed ? 2 : 1),
      borderRadius: BorderRadius.circular(12),
    );
  }

  BoxDecoration _secondary() {
    return BoxDecoration(
      color: _isDisabled
          ? Colors.transparent
          : _isPressed || _isActive
          ? context.colorScheme.elevation2
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _isDisabled
            ? context.colorScheme.elevation2
            : _isPressed || _isActive
            ? context.colorScheme.elevation5
            : _isHovered
            ? context.colorScheme.elevation5
            : context.colorScheme.elevation4,
        width: _isPressed ? 2 : 1,
      ),
    );
  }

  BoxDecoration _neumorphic() {
    final pressed = _isPressed;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: _isPressed || _isActive
          ? [
              BoxShadow(
                color: context.colorScheme.shadowDark,
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
              BoxShadow(color: context.colorScheme.elevation1),
            ]
          : [
              BoxShadow(
                color: context.colorScheme.shadowDark,
                blurRadius: 1,
                offset: Offset(-2, -2),
                blurStyle: BlurStyle.inner,
              ),
              BoxShadow(
                color: context.colorScheme.shadowLight,
                blurRadius: 1,
                offset: Offset(2, 2),
                blurStyle: BlurStyle.inner,
              ),
              BoxShadow(
                color: context.colorScheme.elevation1,
                blurRadius: 4,
                blurStyle: BlurStyle.inner,
              ),
            ],
    );
  }

  BoxDecoration _brand() {
    return BoxDecoration(
      color: _isDisabled
          ? context.colorScheme.GreenThemeDisabled
          : _isPressed || _isActive
          ? context.colorScheme.spl600
          : _isHovered
          ? context.colorScheme.spl500
          : context.colorScheme.spl600,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _isDisabled
            ? Colors.transparent
            : _isPressed || _isActive
            ? context.colorScheme.spl300
            : Colors.transparent,
        width: _isPressed ? 2 : 1,
      ),
    );
  }

  BoxDecoration _tertiary() {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    );
  }

  BoxDecoration _link() {
    return BoxDecoration(
      color: Colors.transparent,
      border: Border(
        bottom: BorderSide(
          color: _isDisabled
              ? context.colorScheme.textDisabled
              : _isPressed || _isActive
              ? context.colorScheme.textPrimary
              : _isHovered
              ? context.colorScheme.textBody
              : context.colorScheme.textPrimary,
          width: 1,
        ),
      ),
    );
  }

  /// ---------------- COLORS ----------------

  Color _border() {
    if (_isDisabled) {
      if (widget.style == FusionAppButtonStyle.primary) {
        return context.colorScheme.elevation2;
      }
    }

    if (_isPressed) {
      if (widget.style == FusionAppButtonStyle.primary) {
        return context.colorScheme.elevation5;
      }
    }
    if (_isActive) {
      return context.colorScheme.elevation5;
    }
    if (_isHovered) {
      if (widget.style == FusionAppButtonStyle.primary) {
        return context.colorScheme.elevation4;
      }
    }

    return context.colorScheme.elevation3;
  }

  TextStyle _textStyle() {
    Color color = context.colorScheme.textPrimary;
    if (_isDisabled) {
      color = context.colorScheme.textDisabled;
    }
    if (widget.style == FusionAppButtonStyle.link) {
      return TextStyle(
        fontWeight: FontWeight.w600,
        color: () {
          if (_isDisabled)
            return context.colorScheme.textDisabled;
          else if (_isPressed || _isActive)
            return context.colorScheme.textPrimary;
          else if (_isHovered)
            return context.colorScheme.textBody;
          else
            context.colorScheme.textPrimary;
        }(),
      );
    }
    if (widget.style == FusionAppButtonStyle.tertiary) {
      return TextStyle(
        fontWeight: FontWeight.w600,
        color: _isDisabled
            ? context.colorScheme.textDisabled
            : _isPressed || _isActive
            ? context.colorScheme.textPrimary
            : _isHovered
            ? context.colorScheme.textBody
            : context.colorScheme.textPrimary,
      );
    }

    if (widget.style == FusionAppButtonStyle.brand) {
      return TextStyle(
        fontWeight: FontWeight.w600,
        color: _isDisabled
            ? context.colorScheme.GreenThemeDisabledText
            : context.colorScheme.primaryWhite,
      );
    }

    return TextStyle(
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
