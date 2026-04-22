import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/neumorphic_button.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionContainer;
class GainControl extends StatelessWidget {
  const GainControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
     // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children:  [
          Transform.scale(
            scale: 1.2,
            child: FusionContainer(
              raised: true,
              color: context.colorScheme.elevation2,
              borderRadius: 3,
              child: Container(
                height: 24,
                width: 24,
                  child: Icon(Icons.remove, size: 16, color:context.colorScheme.iconWhite)),
            ),
          ),
          SizedBox(width: 8),
          Text('5.0',
            style: Theme.of(context).textTheme.l1Medium.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.textPrimary,
          ),
          ),
          SizedBox(width: 8),
          Transform.scale(
            scale: 1.2,
            child: FusionContainer(
              raised: true,
              color: context.colorScheme.elevation2,
              borderRadius: 3,
              child: Container(
                  height: 24,
                  width: 24,
                  child: Icon(Icons.add, size: 16,color:context.colorScheme.iconWhite)),
            ),
          ),
        ],
      ),
    );
  }
}
