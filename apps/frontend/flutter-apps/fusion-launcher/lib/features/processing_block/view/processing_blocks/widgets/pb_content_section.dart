import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PbContentSection extends StatelessWidget {
  const PbContentSection({
    super.key,
    this.header,
    this.title,
    required this.child,
    this.footer,
  });
  final Widget? header;
  final String? title;

  final Widget child;

  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: <Widget>[
        if (header != null || title != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(16),

            child: Center(
              child:
                  header ??
                  FusionAppText(
                    text: title ?? "",
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
            ),
          ),
          Divider(
            height: 1,
            color: context.colorScheme.strokeLight,
          ),
        ],

        Expanded(child: child),
        if (footer != null) ...<Widget>[
          Divider(
            height: 1,
            color: context.colorScheme.strokeLight,
          ),
          Container(
            padding: const EdgeInsets.all(10),

            child: footer,
          ),
        ],
      ],
    );
  }
}
