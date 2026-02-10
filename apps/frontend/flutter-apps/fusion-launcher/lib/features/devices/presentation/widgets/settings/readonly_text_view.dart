import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ReadonlyTextView extends StatelessWidget {
  final String value;

  const ReadonlyTextView({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FusionContainer(
          borderRadius: 6,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: FusionAppText(
              text: value,
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textDisabled,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
