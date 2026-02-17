import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NetworkSettingsHeader extends StatelessWidget {
  final String title;

  const NetworkSettingsHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              text: title,
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textBody,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),
        Divider(
          color: context.colorScheme.elevation2,
          thickness: 1,
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
