import 'package:flutter/material.dart';

class AudioToggleButtonWidget extends StatefulWidget {
  final String name;
  final bool initialToggleState;
  final ValueChanged<bool> onToggle;

  const AudioToggleButtonWidget({
    super.key,
    required this.name,
    required this.initialToggleState,
    required this.onToggle,
  });

  @override
  AudioToggleButtonWidgetState createState() => AudioToggleButtonWidgetState();
}

class AudioToggleButtonWidgetState extends State<AudioToggleButtonWidget> {
  late bool isOn;
  double scale = 1.0;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialToggleState;
  }

  void _toggleSwitch() {
    if (mounted) {
      setState(() {
        isOn = !isOn;
      });
      widget.onToggle(isOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.95),
      onTapUp: (_) {
        setState(() => scale = 1.0);
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) setState(() => scale = 1.0);
        });
        _toggleSwitch();
      },
      onTapCancel: () => setState(() => scale = 1.0),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.bounceOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOn ? Colors.greenAccent.shade700 : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isOn
                ? <BoxShadow>[
                    BoxShadow(color: Colors.greenAccent.shade700, blurRadius: 8),
                  ]
                : <BoxShadow>[
                    const BoxShadow(color: Colors.black38, blurRadius: 6),
                  ],
          ),
          child: Text(
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
