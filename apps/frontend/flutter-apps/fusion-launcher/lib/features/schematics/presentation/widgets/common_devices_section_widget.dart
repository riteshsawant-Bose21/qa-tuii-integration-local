import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import 'expandable_popup_menu_widget.dart';

class CommonDevicesSectionWidget extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final Widget sectionContent;
  final Widget addButtonWidget;
  const CommonDevicesSectionWidget({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    required this.sectionContent,
    required this.addButtonWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.launcherBgColor1,
        border: Border(
          bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
          right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Header
          Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLine: 1,
                  ),
                ),
                const SizedBox(width: 4),

                /// Pass section title to the expandable popup menu
                ExpandablePopupMenuWidget(sectionTitle: title),
              ],
            ),
          ),

          /// Content
          Expanded(
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: sectionContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
