import 'package:flutter/material.dart';

import '../dto/pb_layout.dart';
import '../sample_data/layout_data.dart';
import 'dynamic_grid_view.dart';

class ProcessingBlockPage extends StatelessWidget {
  const ProcessingBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridView(
      layout: PBLayout.fromMap(SampleData.sampleData),
    );
  }
}
