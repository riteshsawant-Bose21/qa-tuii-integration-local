import 'package:flutter/material.dart';

import '../fusion_lib.dart';

class GlobalBlockerController {
  OverlayEntry? _entry;

  // Used to update content without recreating overlay
  final ValueNotifier<_OverlayConfig?> _configNotifier = ValueNotifier<_OverlayConfig?>(null);

  bool get isShowing => _entry != null;

  void show(
    BuildContext context, {
    required Widget content,
    Color backgroundColor = Colors.transparent,
  }) {
    if (_entry != null) return;

    _configNotifier.value = _OverlayConfig(
      content: content,
      backgroundColor: backgroundColor,
    );

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (_) {
        return ValueListenableBuilder<_OverlayConfig?>(
          valueListenable: _configNotifier,
          builder: (_, config, __) {
            if (config == null) return const SizedBox.shrink();

            return GlobalBlockerOverlay(
              content: config.content,
              backgroundColor: config.backgroundColor,
            );
          },
        );
      },
    );

    overlay.insert(_entry!);
  }

  /// 🔥 No flicker update
  void update({
    required Widget content,
    Color backgroundColor = Colors.transparent,
  }) {
    if (_entry == null) return;

    _configNotifier.value = _OverlayConfig(
      content: content,
      backgroundColor: backgroundColor,
    );
  }

  void hide() {
    _entry?.remove();
    _entry = null;
    _configNotifier.value = null;
  }

  void dispose() {
    hide();
    _configNotifier.dispose();
  }
}

class _OverlayConfig {
  final Widget? content;
  final Color backgroundColor;

  _OverlayConfig({
    required this.content,
    required this.backgroundColor,
  });
}

class GlobalBlockerOverlay extends StatefulWidget {
  final Widget? content;
  final Color backgroundColor;
  final String hintText;

  const GlobalBlockerOverlay({
    super.key,
    this.content,
    this.backgroundColor = Colors.transparent,
    this.hintText = "Please wait, this may take a moment...",
  });

  @override
  State<GlobalBlockerOverlay> createState() => _GlobalBlockerOverlayState();
}

class _GlobalBlockerOverlayState extends State<GlobalBlockerOverlay> with SingleTickerProviderStateMixin {
  bool _showHint = false;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide =
        Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
        );
  }

  void _onTap() {
    if (_showHint) return;

    setState(() => _showHint = true);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      _controller.reverse().then((_) {
        if (!mounted) return;
        setState(() => _showHint = false);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Material(
          color: widget.backgroundColor,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main content (optional)
              if (widget.content != null) Center(child: widget.content!),

              // Hint message
              if (_showHint)
                Positioned(
                  bottom: 80,
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(
                      position: _slide,
                      child: _HintBubble(text: widget.hintText),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  final String text;

  const _HintBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.elevation1,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          text,
          style: context.textTheme.labelMedium,
        ),
      ),
    );
  }
}
