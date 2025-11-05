import 'package:flutter/material.dart';

import 'processing_block_customizer.dart';

class ProcessingBlockPage extends StatelessWidget {
  const ProcessingBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProcessingBlockCustomizer();
    // return Padding(
    //   padding: const EdgeInsets.all(8.0),
    //   child: DynamicGridView(
    //     layout: PBLayout.fromMap(SampleData.sampleData),
    //   ),
    // );
  }
}
