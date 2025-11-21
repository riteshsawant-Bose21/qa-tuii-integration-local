import 'dart:math';

import 'package:flutter/material.dart';

import '../dto/pb_item.dart';
import '../dto/pb_layout.dart';
import 'item_widget_builder.dart';

class DynamicGridView extends StatelessWidget {
  const DynamicGridView({super.key, required this.layout, this.handler,required this.scrollController});
  final PBLayout layout;
  final PBWidgetValueHandler? handler;
  final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double widthPerCell = constraints.maxHeight / layout.height;
        final int maxRowNum = layout.children.fold<int>(
          0,
          (int previousValue, PBItem element) => max(previousValue, element.x.toInt() + element.width.toInt()),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          child: SizedBox(
            width: max(widthPerCell * maxRowNum, constraints.maxWidth),
            height: widthPerCell * layout.height,
            child: Stack(
              children: <Widget>[
                for (final PBItem child in layout.children)
                  Positioned(
                    left: widthPerCell * child.x,
                    top: widthPerCell * child.y,
                    child: SizedBox(
                      width: widthPerCell * child.width,
                      height: widthPerCell * child.height,
                      child: ItemWidgetBuilder(item: child, valueHandler: handler),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
