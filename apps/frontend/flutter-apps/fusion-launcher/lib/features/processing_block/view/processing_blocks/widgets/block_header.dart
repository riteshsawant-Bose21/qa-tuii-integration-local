import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/processing_chain_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

List<Positioned> getBlockHeader(BuildContext context, ProcessingBlockModel pb, {List<Widget>? actions}) {
  return <Positioned>[
    Positioned(
      left: 0,
      top: 0,
      child: SizedBox(
        height: 40,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
    ),

    Positioned(
      right: 0,
      top: 0,
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (actions != null) ...actions,
            const SizedBox(width: 10),
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
        ),
      ),
    ),
  ];
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fusion_launcher/features/processing_block/viewmodel/processing_chain_cubit.dart';
// import 'package:fusion_lib/fusion_lib.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

// class BlockHeader extends StatelessWidget {
//   const BlockHeader({
//     super.key,
//     required this.pb,
//     this.actions,
//   });
//   final ProcessingBlockModel pb;
//   final Widget? actions;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       constraints: const BoxConstraints(
//         minWidth: 300,
//         maxWidth: double.infinity,
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min, // still shrink-wrap
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: <Widget>[
//           /// LEFT
//           Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: <Widget>[
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 decoration: BoxDecoration(
//                   color: context.colorScheme.elevation2,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 padding: const EdgeInsets.all(10),
//                 child: Image.asset(
//                   pb.iconAsset,
//                   color: context.colorScheme.iconDefault,
//                   height: 18,
//                   width: 18,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 pb.name,
//                 style: context.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(width: 16),

//           /// RIGHT (no spacer)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             // mainAxisSize: MainAxisSize.min,
//             children: <Widget>[
//               if (actions != null) actions!,
//               const SizedBox(width: 20),
//               InkWell(
//                 onTap: () {
//                   context.read<ProcessingChainCubit>().deleteSelectedProcessingBlock();
//                 },
//                 child: Tooltip(
//                   message: "Delete processing block",
//                   child: Icon(
//                     LucideIcons.trash200,
//                     size: 16,
//                     color: context.colorScheme.iconDefault,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
