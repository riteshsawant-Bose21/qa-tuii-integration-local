import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_lib.dart';

class VolumeControlButtons extends StatelessWidget {
  final Function(double newVolume) onVolumeChanged;
  final TextEditingController? volumeController;
  final Function() onIncrement;
  final Function() onDecrement;

  const VolumeControlButtons({
    super.key,
    this.volumeController,
    required this.onVolumeChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 20,
      // Fix 1: Clip the entire stack to rounded corners to hide sharp text field edges
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Layer 1: The Text Field (Background)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FusionContainer(
              child: FusionTextField(
                hintText: '5.0',
                controller: volumeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                color: context.colorScheme.elevation1,
                style: context.textTheme.labelSmall!.copyWith(
                  fontSize: 10,
                ),
                hintStyle: context.textTheme.labelSmall!.copyWith(
                  fontSize: 10,
                ),
                onChanged: (String value) {
                  final double? newVolume = double.tryParse(value);
                  if (newVolume != null) {
                    onVolumeChanged(newVolume);
                  }
                },
                // Padding prevents text from sliding under the buttons
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ),

          // Layer 2: Decrement Button (Left)
          Align(
            alignment: Alignment.centerLeft,
            child: FusionNeumorphicButton(
              onTap: onDecrement,
              borderRadius: 4,
              height: 30,
              width: 24,
              // Slightly wider for easier touch
              // Fix 2: Remove margin so button touches the edge and covers the background
              margin: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.minus,
                size: 12,
                color: context.colorScheme.iconWhite,
              ),
            ),
          ),

          // Layer 3: Increment Button (Right)
          Align(
            alignment: Alignment.centerRight,
            child: FusionNeumorphicButton(
              onTap: onIncrement,
              borderRadius: 4,
              height: 30,
              width: 24,
              // Fix 2: Remove margin
              margin: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.plus,
                size: 12,
                color: context.colorScheme.iconWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
