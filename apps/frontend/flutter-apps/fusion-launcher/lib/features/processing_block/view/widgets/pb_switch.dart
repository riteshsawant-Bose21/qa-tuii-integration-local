import 'package:flutter/cupertino.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBSwitch extends StatelessWidget {
  const PBSwitch({super.key, required this.item, this.handler});
  final PBItem item;
  final PBWidgetValueHandler? handler;
  @override
  Widget build(BuildContext context) {
    final PBSwitchParam data = (handler?.resolveForItem(item) ?? item.param) as PBSwitchParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double mw = constraints.maxWidth;
        final TextStyle style = TextStyle(fontSize: (mw * 0.05).clamp(6, 12));
        return Row(
          spacing: (mw * 0.05).clamp(10, 20),
          children: <Widget>[
            Text(
              data.label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: (mw * 0.05).clamp(10, 20)),
            ),
            CupertinoSlidingSegmentedControl<bool>(
              children: <bool, Widget>{
                true: Text(data.enableValueLabel ?? "Yes", style: style),
                false: Text(data.disabledValueLabel ?? "No", style: style),
              },
              onValueChanged: (_) {},
              groupValue: handler?.getValue(item) ?? true,
            ),
          ],
        );
      },
    );
  }
}
