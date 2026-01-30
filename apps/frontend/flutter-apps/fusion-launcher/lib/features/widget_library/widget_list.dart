import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../configuration_page/widgets/section_header.dart';

class WidgetList extends StatelessWidget {
  const WidgetList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SectionHeader(
          title: 'Widgets Library',
        ),

        /// Event list
        Expanded(
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
                left: BorderSide(color: context.colorScheme.elevation2, width: 1),
                right: BorderSide(color: context.colorScheme.elevation2, width: 1),
              ),
              color: Theme.of(context).colorScheme.elevation1,
            ),
            child: const Center(
              child: FusionAppText(text: 'Widget List'),
            ),
          ),
        ),
      ],
    );
  }
}
