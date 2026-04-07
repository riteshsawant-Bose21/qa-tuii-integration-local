import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class CommonCheckBox extends StatefulWidget {

  final bool isSelected;
  final Function? onSelected;
  const CommonCheckBox({super.key,required this.isSelected,this.onSelected});

  @override
  State<CommonCheckBox> createState() => _CommonCheckBoxState();
}

class _CommonCheckBoxState extends State<CommonCheckBox> {
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
