import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionToast extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;

  const FusionToast({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration = const Duration(seconds: 2),
  });

  /// Show a success toast message
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green[600],
      textColor: Colors.white,
      duration: duration,
    );
  }

  /// Show an error toast message
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red[600],
      textColor: Colors.white,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final OverlayState overlayState = Overlay.of(context);
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        top: 60,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: FusionToast(
              message: message,
              icon: icon,
              backgroundColor: backgroundColor,
              textColor: textColor,
              duration: duration,
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future<Null>.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  @override
  State<FusionToast> createState() => _FusionToastState();
}

class _FusionToastState extends State<FusionToast> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        );

    _animationController.forward();

    // Start fade out animation before removal
    Future<Null>.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.black87,
                borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.icon != null) ...<Widget>[
                    Icon(
                      widget.icon,
                      color: widget.textColor ?? Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                      child: SemanticHelper.staticText(
                      testId: SemanticHelper.createTestId(SemanticTypes.text, "toast_msg"),
                      child:FusionAppText(
                      text: widget.message,
                      style: TextStyle(
                        color: widget.textColor ?? Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
