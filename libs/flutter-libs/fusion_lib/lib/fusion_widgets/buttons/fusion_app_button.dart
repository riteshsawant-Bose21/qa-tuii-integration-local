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

  final bool iconButton;

  final VoidCallback? onPressed;
  final Widget? child;
  final String semanticId;

  final Color? color;
  final double borderRadius;
  final TextStyle? textstyle;

  const FusionAppButton({
    super.key,
    required this.semanticId,
    required this.style,
    this.text,
    this.child,
    this.enabled = true,
    this.width = 358,
    this.height = 48,
    this.onPressed,
    this.color,
    this.borderRadius = 8,
    this.showPrefixIcon = false,
    this.prefixIcon,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.iconButton = false,
    this.textstyle,
  });

  @override
  State<FusionAppButton> createState() => _FusionAppButtonState();
}

class _FusionAppButtonState extends State<FusionAppButton> {
  bool _hover = false;
  bool _pressed = false;
  bool _active = false;

  bool get _disabled => !widget.enabled;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      isEnabled: _disabled,
      label: widget.text,
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "fusion_app_button_${widget.semanticId}",
      ),
      child: MouseRegion(
        onEnter: (_) => !_disabled ? setState(() => _hover = true) : null,
        onExit: (_) {
          if (!_disabled) {
            setState(() {
              _hover = false;
              _pressed = false;
            });
          }
        },
        child: GestureDetector(
          onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
          onTap: _disabled
              ? null
              : () {
                  setState(() {
                    _active = !_active;
                    _pressed = false;
                  });
                  widget.onPressed?.call();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: _width(),
            height: _height(),
            decoration: _decoration(),
            child: _content(),
          ),
        ),
      ),
    );
  }

  double? _width() {
    if (widget.style == FusionAppButtonStyle.link) return null;
    if (widget.child != null) return 40;
    if (widget.style == FusionAppButtonStyle.tertiary) return null;
    return widget.width;
  }

  double _height() {
    if (widget.style == FusionAppButtonStyle.link || widget.style == FusionAppButtonStyle.tertiary) return 24;
    if (widget.child != null) return 40;
    return widget.height;
  }

  Widget _content() {
    if (widget.style == FusionAppButtonStyle.neumorphic) {
      return Opacity(
        opacity: _disabled ? 0.5 : 1,
        child: FusionContainer(
          raised: !_pressed,
          borderRadius: widget.borderRadius,
          height: widget.height,
          alignment: Alignment.center,
          color: _disabled ? context.colorScheme.elevation2 : widget.color ?? context.colorScheme.elevation1,
          child: Row(mainAxisSize: MainAxisSize.min, children: _children()),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _children(),
    );
  }

  List<Widget> _children() {
    return [
      if (widget.showPrefixIcon && widget.prefixIcon != null) _icon(widget.prefixIcon!),

      if (widget.text != null || widget.child != null)
        Flexible(
          child:
              widget.child ??
              FusionAppText(
                text: widget.text!,
                style: widget.textstyle ?? _textStyle(),
              ),
        ),

      if (widget.showSuffixIcon && widget.suffixIcon != null) _icon(widget.suffixIcon!),

      if (widget.iconButton) _arrowButton(),
    ];
  }

  Widget _icon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(icon, size: 16, color: _textColor),
    );
  }

  Widget _arrowButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: _disabled ? context.colorScheme.elevation6 : context.colorScheme.primaryWhite,
        ),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: _disabled
              ? context.colorScheme.textPlaceholder
              : widget.style == FusionAppButtonStyle.brand
              ? context.colorScheme.primaryColor
              : context.colorScheme.elevation2,
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
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
        return const BoxDecoration(color: Colors.transparent);
      case FusionAppButtonStyle.link:
        return _link();
    }
  }

  Color get _textColor {
    final cs = context.colorScheme;

    if (_disabled) return cs.iconDisabled;

    if (widget.style == FusionAppButtonStyle.brand) return cs.primaryWhite;

    if (widget.style == FusionAppButtonStyle.tertiary || widget.style == FusionAppButtonStyle.link) {
      if (_pressed || _active) return cs.iconWhite;
      if (_hover) return cs.iconDefault;
      return cs.textPrimary;
    }

    return cs.textPrimary;
  }

  BoxDecoration _primary() {
    return BoxDecoration(
      color: _disabled
          ? context.colorScheme.elevation2
          : _pressed || _active
          ? context.colorScheme.elevation2
          : _hover
          ? context.colorScheme.elevation3
          : widget.color ?? context.colorScheme.elevation2,
      border: Border.all(color: _border(), width: _pressed ? 2 : 1),
      borderRadius: BorderRadius.circular(widget.borderRadius),
    );
  }

  BoxDecoration _secondary() {
    return BoxDecoration(
      color: _pressed || _active ? context.colorScheme.elevation2 : Colors.transparent,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(
        color: _disabled
            ? context.colorScheme.elevation2
            : _hover || _pressed || _active
            ? context.colorScheme.elevation5
            : context.colorScheme.elevation4,
        width: _pressed ? 2 : 1,
      ),
    );
  }

  BoxDecoration _neumorphic() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      boxShadow: _active
          ? [
              BoxShadow(
                color: context.colorScheme.shadowLight,
                blurRadius: 2,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: context.colorScheme.shadowDark,
                blurRadius: 2,
                offset: const Offset(-2, -2),
              ),
            ]
          : [
              BoxShadow(
                color: context.colorScheme.shadowDark,
                blurRadius: 1,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: context.colorScheme.shadowLight,
                blurRadius: 1,
                offset: const Offset(-1, -1),
              ),
            ],
    );
  }

  BoxDecoration _brand() {
    return BoxDecoration(
      color: _disabled
          ? context.colorScheme.GreenThemeDisabled
          : _pressed || _active
          ? context.colorScheme.spl600
          : _hover
          ? context.colorScheme.spl500
          : widget.color ?? context.colorScheme.spl600,
      borderRadius: BorderRadius.circular(widget.borderRadius),
    );
  }

  BoxDecoration _link() {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: _disabled
              ? context.colorScheme.textDisabled
              : _pressed || _active
              ? context.colorScheme.textPrimary
              : _hover
              ? context.colorScheme.textBody
              : context.colorScheme.textPrimary,
        ),
      ),
    );
  }

  Color _border() {
    if (_disabled) return context.colorScheme.elevation2;
    if (_pressed || _active) return context.colorScheme.elevation5;
    if (_hover) return context.colorScheme.elevation4;
    return context.colorScheme.elevation3;
  }

  TextStyle _textStyle() {
    final cs = context.colorScheme;

    if (widget.style == FusionAppButtonStyle.brand) {
      return context.textTheme.b2SemiBold.withColor(
        _disabled ? cs.GreenThemeDisabledText : cs.primaryWhite,
      );
    }

    if (widget.style == FusionAppButtonStyle.link || widget.style == FusionAppButtonStyle.tertiary) {
      return context.textTheme.b2SemiBold.withColor(_textColor);
    }

    return context.textTheme.l1Regular.withColor(
      _disabled ? cs.textDisabled : cs.textPrimary,
    );
  }
}
