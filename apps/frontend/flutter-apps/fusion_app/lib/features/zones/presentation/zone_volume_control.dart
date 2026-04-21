import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ZoneVolumeControl extends StatefulWidget {

   const ZoneVolumeControl({
    super.key,
  });

  @override
  State<ZoneVolumeControl> createState() => _ZoneVolumeControlState();
}

class _ZoneVolumeControlState extends State<ZoneVolumeControl> {


  ValueNotifier<bool> controller = ValueNotifier(false);

  GlobalKey<VerticalAudioSliderState> key = GlobalKey<VerticalAudioSliderState>();

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return VirtualControllerVolumeControl();
  }

  Widget _navButton({
    required IconData icon,
    required BuildContext context,
    VoidCallback? onTap,

  }) {
    return GestureDetector(
      onTap: onTap,
      child: FusionContainer(
        raised:true,
        borderRadius: 8,
        child: Container(
          margin: EdgeInsets.all(8),
          child: Icon(
            icon,
            color: context.colorScheme.iconDefault,
          ),
        ),
      ),
    );
  }
}

//
// class VerticalAudioSlider extends StatefulWidget {
//   final double initialValue;
//   final ValueChanged<double>? onChanged;
//
//   const VerticalAudioSlider({
//     super.key,
//     this.initialValue = 50,
//     this.onChanged,
//   });
//
//   @override
//   State<VerticalAudioSlider> createState() => VerticalAudioSliderState();
// }
//
// class VerticalAudioSliderState extends State<VerticalAudioSlider> with SingleTickerProviderStateMixin {
//   late double value;
//   double previousValue = 0;
//
//   late AnimationController _controller;
//   Animation<double>? _animation;
//   @override
//   void initState() {
//     value = widget.initialValue;
//     previousValue = value;
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _controller.addListener(() {
//       setState(() {
//         value = _animation!.value;
//       });
//       widget.onChanged?.call(value);
//     });
//     super.initState();
//   }
//
//   void _updateValue(Offset localPosition, double height) {
//     double newValue = (1 - (localPosition.dy / height)) * 100;
//
//     newValue = newValue.clamp(0, 100);
//
//     setState(() => value = newValue);
//     widget.onChanged?.call(newValue);
//   }
//
//   void _animateTo(double target) {
//     _animation = Tween<double>(
//       begin: value,
//       end: target,
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );
//
//     _controller.forward(from: 0);
//   }
//
//   void toggleMute() {
//     if (value > 0) {
//       previousValue = value;
//       _animateTo(0);
//     } else {
//       _animateTo(previousValue == 0 ? 50 : previousValue);
//     }
//     widget.onChanged?.call(value);
//   }
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return GestureDetector(
//           onVerticalDragUpdate: (details) {
//             _updateValue(details.localPosition, constraints.maxHeight);
//           },
//           onTapDown: (details) {
//             _updateValue(details.localPosition, constraints.maxHeight);
//           },
//           child: CustomPaint(
//             size: Size(constraints.maxWidth, constraints.maxHeight),
//             painter:  VolumeMeterPainterBG(
//               value: value,
//               trackColor: context.colorScheme.elevation2,
//               gradientColors: [
//                 context.colorScheme.primary,
//                 context.colorScheme.iconWhite,
//               ],
//             )
//           ),
//         );
//       },
//     );
//   }
// }