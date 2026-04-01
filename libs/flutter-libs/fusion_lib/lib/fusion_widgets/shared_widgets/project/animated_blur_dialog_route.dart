import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBlurDialogRoute<T> extends PageRoute<T> {
  AnimatedBlurDialogRoute({required this.builder, required this.theme});

  final WidgetBuilder builder;
  final ThemeData theme;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final blurValue = Tween<double>(begin: 0, end: 6).evaluate(animation);

        return Stack(
          children: [
            // Blur background
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurValue,
                  sigmaY: blurValue,
                ),
                child: Container(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(animation.value * 0.3),
                ),
              ),
            ),

            // Dialog animation
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: Theme(
                    data: theme,
                    child: builder(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get maintainState => true;
}
