import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ErrorOverlay {

  ErrorOverlay._internal();

  static final ErrorOverlay _instance = ErrorOverlay._internal();

  factory ErrorOverlay() => _instance;


  static void show(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ErrorOverlayWidget(
        message: message,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ErrorOverlayWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorOverlayWidget({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_ErrorOverlayWidget> createState() => _ErrorOverlayWidgetState();
}

class _ErrorOverlayWidgetState extends State<_ErrorOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: context.colorScheme.onPrimary,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(
                    Icons.close,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}