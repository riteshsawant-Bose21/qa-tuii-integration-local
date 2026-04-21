import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class CommonMobileCheckBox extends StatefulWidget {

  final bool isSelected;
  final Function? onSelected;
  const CommonMobileCheckBox({super.key,required this.isSelected,this.onSelected});

  @override
  State<CommonMobileCheckBox> createState() => _CommonMobileCheckBoxState();
}

class _CommonMobileCheckBoxState extends State<CommonMobileCheckBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color:widget.isSelected
            ? context.colorScheme.primary
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isSelected
              ? context.colorScheme.primary
              : context.colorScheme.textDisabled,
          width: 2,
        ),
      ),
      child: widget.isSelected
          ?  Icon(Icons.done, size: 16, color: context.colorScheme.primaryBlack)
          : null,
    );
  }
}
