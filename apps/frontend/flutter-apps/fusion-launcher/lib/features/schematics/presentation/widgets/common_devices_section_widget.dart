import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_vertical_resizable_widget.dart';

import 'expandable_popup_menu_widget.dart';

class CommonDevicesSectionWidget extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final Widget sectionContent;
  final Widget addButtonWidget;
  final ValueChanged<double>? onHeightChanged;
  final double minHeight;
  final bool enableResize;

  const CommonDevicesSectionWidget({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    required this.sectionContent,
    required this.addButtonWidget,
    this.onHeightChanged,
    this.minHeight = 150,
    this.enableResize = true,
  });

  @override
  Widget build(BuildContext context) {
    if (enableResize) {
      return FusionVerticalResizableWidget(
        initialHeight: height,
        minHeight: minHeight,
        maxHeight: double.infinity,
        onHeightChanged: onHeightChanged,
        child: _buildContainer(context),
      );
    } else {
      return SizedBox(
        height: height,
        child: _buildContainer(context),
      );
    }
  }

  Widget _buildContainer(BuildContext context) {
    return Container(
      width: width,
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
