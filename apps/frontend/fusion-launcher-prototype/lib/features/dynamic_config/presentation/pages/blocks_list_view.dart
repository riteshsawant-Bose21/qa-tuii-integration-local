// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../core/service_locator.dart';
// import '../../domain/entities/panel_entity.dart';
// import '../bloc/blocks_bloc.dart';
//
//
// class BlocksListView extends StatefulWidget {
//   const BlocksListView({super.key});
//
//   @override
//   State<BlocksListView> createState() => _BlocksListViewState();
// }
//
// class _BlocksListViewState extends State<BlocksListView> {
//   @override
//   void initState() {
//     super.initState();
//     initBlocks();
//   }
//
//   void initBlocks() {
//     serviceLocator<BlocksBloc>().add(Pane());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<BlocksBloc, BlocksState>(
//       builder: (BuildContext context, BlocksState state) {
//         if (state is BlocksLoading) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (state is BlocksLoaded) {
//           final List<PanelEntity> blocks = state.blocks;
//           if (blocks.isEmpty) return _populateErrorScreen();
//           return _populateUIBasedOnDesignFile(blocks);
//         } else if (state is BlocksError) {
//           return _populateErrorScreen();
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }
//
//   Widget _populateUIBasedOnDesignFile(List<PanelEntity> blocks) {
//     return SingleChildScrollView(
//       child: Align(
//         alignment: Alignment.topCenter,
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 800),
//           padding: const EdgeInsets.all(8.0),
//           child: Wrap(
//             spacing: 12.0,
//             runSpacing: 12.0,
//             children: blocks.map((PanelEntity panelEntity) {
//               final AlgorithmInfo algorithmData = getAlgorithmInfo(panelEntity.algorithmType);
//               return SizedBox(
//                 width: 180,
//                 child: AspectRatio(
//                   aspectRatio: 5 / 3,
//                   child: Card(
//                     elevation: 4.0,
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.pushNamed(
//                           context,
//                           Routes.panelScreen,
//                           arguments: panelEntity,
//                         );
//                       },
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           spacing: 16.0,
//                           children: <Widget>[
//                             Iconify(
//                               algorithmData.icon,
//                               color: Theme.of(context).textTheme.titleSmall!.color,
//                               size: 32,
//                             ),
//                             Text(
//                               panelEntity.name.toUpperCase(),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _populateErrorScreen() {
//     return const Center(
//       child: Text("Error loading panels"),
//     );
//   }
// }
