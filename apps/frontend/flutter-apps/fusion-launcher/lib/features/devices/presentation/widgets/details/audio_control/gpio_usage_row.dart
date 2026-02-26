import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class GpioUsageRow extends StatelessWidget {
  final String name;
  final bool isActive;
  final String? type;

  const GpioUsageRow({
    required this.name,
    this.isActive = false,
    required this.type,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 80,
            child: FusionAppText(
              text: name,
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textPrimary,
              ),
            ),
          ),

          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? context.colorScheme.infoText : context.colorScheme.textGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          if (type != null)
            FusionAppText(
              text: type!,
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
