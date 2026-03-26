import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ScanInstruction extends StatelessWidget {
  final Function? onClickFlash;
  final ValueNotifier<bool> isFlashOn;
  const ScanInstruction({super.key,required this.isFlashOn,this.onClickFlash});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: (){
            onClickFlash!(!isFlashOn.value);
          },
          child: ValueListenableBuilder(
              valueListenable: isFlashOn,
              builder: (context, state, child) {
              return CommonCircleIcon(
                size: 48,
                iconSize: 24,
                icon:  isFlashOn.value ? Icons.flash_on :  Icons.flash_off,
                iconColor: context.colorScheme.iconWhite,
                bgColor: context.colorScheme.elevation2,
              );
            }
          ),
        ),

        const SizedBox(height: 16),

        Text(
          "Position QR code in the frame",
          style: Theme.of(context).textTheme.h5BoldMobile!.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: context.colorScheme.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Make sure the QR code is well-lit and fully visible within the frame",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.b3Regular!.copyWith(
            fontWeight: FontWeight.w400,
            color: context.colorScheme.textBody,
          ),
        ),
      ],
    );
  }
}