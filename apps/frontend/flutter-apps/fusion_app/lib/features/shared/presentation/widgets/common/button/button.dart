import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CustomButton extends StatelessWidget {
  final String buttonText;
  final ValueNotifier<bool>? enabled;
  final Function? onPressed;
  final bool isNeumorphic;
  final Color? backGroundColor;
  final double bottomPadding;
  final EdgeInsetsGeometry padding;

  const CustomButton({
    this.onPressed,
    this.enabled,
    this.isNeumorphic=false,
    this.backGroundColor,
    this.bottomPadding=40,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
    this.buttonText = 'Save Changes',
    super.key});

  @override
  Widget build(BuildContext context) {

    if(isNeumorphic){
      return FusionContainer(
        raised: true,
        child: _button(),
      );
    }

    return Padding(
      padding: padding.add(EdgeInsets.only(bottom: bottomPadding)),
      child: _button()
    );
  }

  _button(){
    final notifier = enabled ?? ValueNotifier(false);
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context,value,_) {
            return ElevatedButton(
              onPressed: value ? (){
                onPressed!();
              }:null, // disabled
              style: ElevatedButton.styleFrom(
                backgroundColor: backGroundColor ?? context.colorScheme.elevation2,
                disabledBackgroundColor: context.colorScheme.elevation2,
                foregroundColor: context.colorScheme.elevation3,
                side:BorderSide(
                  color: isNeumorphic ? Colors.transparent : context.colorScheme.elevation3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child:  Text(
                buttonText,
                style: TextStyle(
                  fontSize: context.textTheme.b2SemiBold.fontSize,
                  fontWeight: FontWeight.w600,
                  color:notifier.value == true ? context.colorScheme.textPrimary: context.colorScheme.textDisabled,
                ),
              ),
            );
          }
      ),
    );
  }

}
