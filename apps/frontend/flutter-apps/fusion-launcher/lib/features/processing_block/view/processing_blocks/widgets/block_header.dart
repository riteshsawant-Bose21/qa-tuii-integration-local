import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/processing_chain_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        const Spacer(),
        if (actions != null) actions!,
        const SizedBox(width: 20),
        InkWell(
          onTap: () {
            context.read<ProcessingChainCubit>().deleteSelectedProcessingBlock();
          },
          child: Tooltip(
            message: "Delete processing block",
            child: Icon(
              LucideIcons.trash200,
              size: 16,
              color: context.colorScheme.iconDefault,
            ),
          ),
        ),
      ],
    );
  }
}
