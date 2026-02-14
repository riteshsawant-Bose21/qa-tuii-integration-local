import 'package:flutter/material.dart';

import 'aes_usage_row.dart';

class Aes67IOUsageSection extends StatelessWidget {
  const Aes67IOUsageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AesUsageRow(label: "IN", activeCount: 2),
        SizedBox(height: 10),
        AesUsageRow(label: "OUT", activeCount: 5),
      ],
    );
  }
}
