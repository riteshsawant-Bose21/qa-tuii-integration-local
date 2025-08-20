import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedWidgetChanger extends StatefulWidget {
  final List<Widget> textWidgetsList;

  /// how long to display each widget before fading to the next
  final int duration;

  const AnimatedWidgetChanger({
    super.key,
    required this.textWidgetsList,
    this.duration = 4000,
  });

  @override
  AnimatedWidgetChangerState createState() => AnimatedWidgetChangerState();
}

class AnimatedWidgetChangerState extends State<AnimatedWidgetChanger> {
  int currentTextIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      Duration(milliseconds: widget.duration),
      (_) {
        if (!mounted) return;
        setState(() {
          currentTextIndex = (currentTextIndex + 1) % widget.textWidgetsList.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRect(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: <double>[0.0, 0.1, 0.9, 1.0],
          ).createShader(bounds),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: (widget.duration / 4).toInt()),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final bool isIncoming = (child.key as ValueKey<int>).value == currentTextIndex;

              // incoming: from top → center; outgoing: from center → bottom
              final Animatable<Offset> tween = Tween<Offset>(
                begin: isIncoming ? const Offset(0, -1) : const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut));

              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Container(
              key: ValueKey<int>(currentTextIndex),
              child: widget.textWidgetsList[currentTextIndex],
            ),
          ),
        ),
      ),
    );
  }
}
