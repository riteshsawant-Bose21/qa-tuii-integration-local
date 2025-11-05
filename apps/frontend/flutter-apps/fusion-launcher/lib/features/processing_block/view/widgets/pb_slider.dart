import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';

class PBSlider extends StatelessWidget {
  const PBSlider({super.key, required this.item});
  final PBItem item;
  @override
  Widget build(BuildContext context) {
    final PBSliderParam data = item.param as PBSliderParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            Text(
              data.label,
              style: const TextStyle(
                color: Colors.grey,
                // fontSize: constraints.maxWidth
              ),
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3, // Rotate 270 degrees (or 1 quarter turn clockwise from vertical)
                child: Slider(
                  value: 50,
                  min: 0,
                  max: 100,
                  divisions: 10,
                  onChanged: (double value) {},
                  // label: ,
                  // label: _currentSliderValue.round().toString(),
                  // onChanged: (double value) {
                  //   setState(() {
                  //     _currentSliderValue = value;
                  //   });
                  // },
                ),
              ),
            ),
            const Text("20"),
          ],
        );
      },
    );
  }
}
