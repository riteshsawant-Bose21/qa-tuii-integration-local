import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_lib.dart';

class BlockHeader extends StatelessWidget {
  const BlockHeader({
    super.key,
    required this.pb,
    this.actions,
  });
  final ProcessingBlockModel pb;
  final Widget? actions;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(color: context.colorScheme.elevation2, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            pb.iconAsset,
            color: context.colorScheme.iconDefault,
            height: 18,
            width: 18,
            // package: '',
          ),
        ),
        const SizedBox(width: 10),
        Text(
          pb.name,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actions != null) actions!,
      ],
    );
  }
}
