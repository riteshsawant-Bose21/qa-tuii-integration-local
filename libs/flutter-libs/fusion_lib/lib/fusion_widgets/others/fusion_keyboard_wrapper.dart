import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FusionKeyboardWrapper extends StatefulWidget {
  final Widget child;

  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final VoidCallback? onShiftUp;
  final VoidCallback? onShiftDown;
  final VoidCallback? onControlUp;
  final VoidCallback? onControlDown;

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onDelete;

  const FusionKeyboardWrapper({
    super.key,
    required this.child,
    this.onUp,
    this.onDown,
    this.onLeft,
    this.onRight,
    this.onUndo,
    this.onRedo,
    this.onDelete,
    this.onShiftUp,
    this.onShiftDown,
    this.onControlUp,
    this.onControlDown,
  });

  @override
  State<FusionKeyboardWrapper> createState() => _FusionKeyboardWrapperState();
}

class _FusionKeyboardWrapperState extends State<FusionKeyboardWrapper> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    final bool isMeta = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;

    final LogicalKeyboardKey logicalKey = event.logicalKey;
    if (logicalKey == LogicalKeyboardKey.shiftLeft || logicalKey == LogicalKeyboardKey.shiftRight) {
      if (event is KeyDownEvent) {
        widget.onShiftDown?.call();
      } else if (event is KeyUpEvent) {
        widget.onShiftUp?.call();
      }
      return;
    }
    if (logicalKey == LogicalKeyboardKey.controlLeft || logicalKey == LogicalKeyboardKey.controlRight) {
      if (event is KeyDownEvent) {
        widget.onControlDown?.call();
      } else if (event is KeyUpEvent) {
        widget.onControlUp?.call();
      }
      return;
    }
    if (event is! KeyDownEvent) return; // handle only key down once

    if (logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onUp?.call();
    } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onDown?.call();
    } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onLeft?.call();
    } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onRight?.call();
    } else if (logicalKey == LogicalKeyboardKey.delete || logicalKey == LogicalKeyboardKey.backspace) {
      widget.onDelete?.call();
    }

    // Undo / Redo
    if (isMeta && logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        widget.onRedo?.call();
      } else {
        widget.onUndo?.call();
      }
    } else if (isMeta && logicalKey == LogicalKeyboardKey.keyY) {
      widget.onRedo?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) {
        _focusNode.requestFocus();
      },
      onExit: (PointerExitEvent event) => _focusNode.unfocus(),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: widget.child,
      ),
    );
  }
}
