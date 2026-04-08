import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class CommonDivider extends StatelessWidget {
  final double paddingValue;
  const CommonDivider({super.key,this.paddingValue=16});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(horizontal: paddingValue),
      child: Divider(color: context.colorScheme.strokeLight,thickness: 0.75,height: 2),
    );
  }
}

class CommonVerticalDivider extends StatelessWidget {

  const CommonVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(color: context.colorScheme.strokeLight,thickness: 0.75);
  }
}

