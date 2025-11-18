import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';

class PBEmpty extends StatelessWidget {
  const PBEmpty({super.key, required this.item});
  final PBItem item;
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
