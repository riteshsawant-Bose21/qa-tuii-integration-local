import 'package:flutter/material.dart';

class FusionPopupButton extends StatefulWidget {
  const FusionPopupButton({
    super.key,
    required this.child,
    required this.popupBuilder,
    this.offset = Offset.zero,
    this.barrierColor = Colors.transparent,
    this.onDismiss,
  });

  /// Anchor widget
  final Widget child;

  /// Popup content builder
  final WidgetBuilder popupBuilder;

  /// Popup offset from anchor
  final Offset offset;

  /// Tap outside color
  final Color barrierColor;

  final VoidCallback? onDismiss;

  @override
  State<FusionPopupButton> createState() => _FusionPopupButtonState();
}

class _FusionPopupButtonState extends State<FusionPopupButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _show() {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hide,
                child: Container(color: widget.barrierColor),
              ),
            ),

            // Popup
            CompositedTransformFollower(
              link: _layerLink,
              offset: widget.offset,
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: IntrinsicWidth(
                  child: widget.popupBuilder(context),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _show,
        child: widget.child,
      ),
    );
  }
}
