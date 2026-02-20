import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

const double _bRadius = 12;
const double _blurRadius = 10;

class PBItemDropdown extends StatelessWidget {
  const PBItemDropdown({super.key, required this.item, this.handler});
  final PBItem item;
  final PBWidgetValueHandler? handler;

  @override
  Widget build(BuildContext context) {
    final PBDropdownParam data =
        (handler?.resolveForItem(item) ?? item.param) as PBDropdownParam;
    return SemanticHelper.dropdown(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "DottedLine",
      ),
      child: PBDropdown<String>(
        value: handler?.getValue(item) ?? item.value ?? data.label,
        hintText: data.label,
        onChanged: (String? value) {
          handler?.onValueChanged(item, value);
        },
        items: data.options,
        itemBuilder: (BuildContext context, String option) {
          return Text(option);
        },
      ),
    );
  }
}

class PBDropdown<T> extends StatelessWidget {
  final String? value;
  final String hintText;
  // final PopupMenuItemBuilder<T> itemBuilder;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final ValueChanged<T> onChanged;
  final double? height;
  final double? width;

  const PBDropdown({
    super.key,
    this.value,
    required this.hintText,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      raised: true,
      color: context.colorScheme.elevation2,
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(_bRadius),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FusionPopupMenu<T>(
            items: items,

            // color: context.colorScheme.elevation2,
            // elevation: 1,
            // position: PopupMenuPosition.under,
            itemBuilder: itemBuilder,
            onSelected: onChanged,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: value ?? hintText,
                      maxLine: 1,
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
