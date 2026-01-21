import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../state/processing_chain_state.dart';
import '../viewmodel/processing_chain_cubit.dart';
import 'processing_block_page.dart';
import 'widgets/dotted_line.dart';

class ProcessingChainView extends StatelessWidget {
  const ProcessingChainView({super.key, required this.params});
  final ProcessingChainParams params;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(),
          ),
        ),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(
                  color: context.colorScheme.strokeLight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: <Widget>[
                  /// --------------------------------------------------------------------------------
                  /// HEADING
                  /// --------------------------------------------------------------------------------
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: context.colorScheme.strokeLight,
                          width: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            FusionAppText(
                              text: switch (params.type) {
                                ProcessingChainDeviceType.source => "SOURCE PROCESSING ",
                                ProcessingChainDeviceType.sourceSet => "SOURCE SET PROCESSING ",
                                ProcessingChainDeviceType.zone => "ZONE PROCESSING ",
                                ProcessingChainDeviceType.subzone => "SUBZONE PROCESSING ",
                                ProcessingChainDeviceType.circuit => "CIRCUIT PROCESSING ",
                              },

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            FusionAppText(text: "- ${params.name}", style: context.textTheme.bodySmall),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            LucideIcons.x200,
                            color: context.colorScheme.iconDefault,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: Provider<ProcessingChainCubit>(
                      create:
                          (_) => ProcessingChainCubit(
                            param: params,
                            viewModel: serviceLocator<ProjectViewModel>(),
                          ),
                      child: Consumer<ProcessingChainCubit>(
                        builder: (BuildContext context, ProcessingChainCubit viewModel, Widget? child) {
                          return BlocBuilder<ProcessingChainCubit, ProcessingChainState>(
                            bloc: viewModel,
                            builder: (BuildContext context, ProcessingChainState state) {
                              if (state is EmptyProcessingChainState) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    FusionAppText(text: "No Processing Blocks Added yet.", style: context.textTheme.bodyLarge),
                                    const SizedBox(height: 10),
                                    AddProcessingBlockButton(
                                      params: params,
                                      viewModel: viewModel,
                                      child: AbsorbPointer(
                                        absorbing: true,
                                        child: FusionButton(
                                          onTap: () {},
                                          label: "+ Add",
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              if (state is! UpdatedProcessingChainState) {
                                return const SizedBox();
                              }

                              return Container(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    /// --------------------------------------------------------------------------------
                                    /// Sidebar
                                    /// --------------------------------------------------------------------------------
                                    _CollapsibleSideBar(
                                      builder: (BuildContext context, bool isOpen) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: const EdgeInsets.all(5.0),
                                                  child: AddProcessingBlockButton(
                                                    params: params,
                                                    viewModel: viewModel,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: context.colorScheme.elevation2,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      padding: const EdgeInsets.all(10),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: context.colorScheme.iconDefault,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(
                                              height: 20,
                                            ),
                                            Stack(
                                              alignment: Alignment.centerLeft,
                                              children: <Widget>[
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 23),
                                                  child: SizedBox(
                                                    height: state.blocks.length * 40.0,
                                                    child: DottedLine(
                                                      direction: Axis.vertical,
                                                      color: context.colorScheme.strokeLight,
                                                      dotSize: 4,
                                                      spacing: 2,
                                                    ),
                                                  ),
                                                ),
                                                ReorderableColumn<ProcessingBlockModel>(
                                                  onReorder: (int oldIndex, int newIndex) {
                                                    viewModel.reorderProcessingBlocks(oldIndex, newIndex);
                                                  },
                                                  items: state.blocks,
                                                  extractId: (ProcessingBlockModel item) => item.id,
                                                  itemBuilder:
                                                      (BuildContext context, ProcessingBlockModel block) => InkWell(
                                                        onTap: () {
                                                          viewModel.selectProcessingBlock(block);
                                                        },
                                                        child: Tooltip(
                                                          message: block.name,
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                                            child: Row(
                                                              spacing: 12,
                                                              children: <Widget>[
                                                                _PBIcon(
                                                                  icon: block.iconAsset,
                                                                  isActive: block.id == state.selectedBlock.id,
                                                                ),
                                                                if (isOpen)
                                                                  Text(
                                                                    block.name,
                                                                    style: context.textTheme.bodySmall?.copyWith(
                                                                      color: context.colorScheme.textPrimary,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),

                                    Flexible(
                                      child: ProcessingBlockPage(
                                        processingBlock: state.selectedBlock,
                                      ),
                                    ),
                                    // ProcessingBlockPage(
                                    //   processingBlock: state.selectedBlock,
                                    // ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static void showForSource(BuildContext context, Source source) {
    _showDialog(
      context,
      ProcessingChainParams(
        id: source.id,
        type: ProcessingChainDeviceType.source,
        name: source.name,
      ),
    );
  }

  static void showForSourceSet(BuildContext context, SourceSet sourceSet) {
    _showDialog(
      context,
      ProcessingChainParams(
        id: sourceSet.id,
        type: ProcessingChainDeviceType.sourceSet,
        name: sourceSet.name,
      ),
    );
  }

  static void showForZone(BuildContext context, Zone zone) {
    _showDialog(
      context,
      ProcessingChainParams(
        id: zone.id,
        type: ProcessingChainDeviceType.zone,
        name: zone.name,
      ),
    );
  }

  static void showForSubzone(BuildContext context, SubZone subzone) {
    _showDialog(
      context,
      ProcessingChainParams(
        id: subzone.id,
        type: ProcessingChainDeviceType.subzone,
        name: subzone.name,
      ),
    );
  }

  static void showForCircuit(BuildContext context, CircuitModel circuit) {
    _showDialog(
      context,
      ProcessingChainParams(
        id: circuit.id,
        type: ProcessingChainDeviceType.circuit,
        name: circuit.name,
      ),
    );
  }

  static void _showDialog(BuildContext context, ProcessingChainParams params) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => Dialog(
            child: ProcessingChainView(
              params: params,
            ),
          ),
    );
  }
}

class _PBIcon extends StatelessWidget {
  const _PBIcon({required this.icon, required this.isActive});
  final bool isActive;
  final String icon;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: isActive ? context.colorScheme.primary : context.colorScheme.elevation3, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        icon,
        color: isActive ? Colors.white : context.colorScheme.iconDefault,
        height: 18,
        width: 18,
        // package: '',
      ),
    );
  }
}

class AddProcessingBlockButton extends StatelessWidget {
  const AddProcessingBlockButton({super.key, required this.params, required this.viewModel, required this.child});
  final ProcessingChainParams params;
  final ProcessingChainCubit viewModel;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return FusionPopupMenu<ProcessingBlockModel>(
      tooltip: "Add Processing Block",
      matchChildWidth: false,
      items: switch (params.type) {
        ProcessingChainDeviceType.source || ProcessingChainDeviceType.sourceSet => ProcessingBlockModel.sourceBlocks,
        ProcessingChainDeviceType.zone || ProcessingChainDeviceType.subzone => ProcessingBlockModel.zoneBlocks,
        ProcessingChainDeviceType.circuit => ProcessingBlockModel.circuitBlocks,
      },
      itemBuilder:
          (BuildContext context, ProcessingBlockModel block) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Image.asset(
                  block.iconAsset,
                  color: context.colorScheme.iconDefault,
                  height: 18,
                  width: 18,
                ),
                const SizedBox(width: 15),
                FusionAppText(
                  text: block.name,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      // (BuildContext context) =>
      //     switch (params.type) {
      //           ProcessingChainDeviceType.source || ProcessingChainDeviceType.sourceSet => ProcessingBlockModel.sourceBlocks,
      //           ProcessingChainDeviceType.zone || ProcessingChainDeviceType.subzone => ProcessingBlockModel.zoneBlocks,
      //           ProcessingChainDeviceType.circuit => ProcessingBlockModel.circuitBlocks,
      //         }
      //         .map(
      //           (ProcessingBlockModel block) => PopupMenuItem<ProcessingBlockModel>(
      //             height: 40,
      //             value: block,
      //             child: Row(
      //               children: <Widget>[
      //                 Image.asset(
      //                   block.iconAsset,
      //                   color: Colors.black,
      //                   height: 18,
      //                   width: 18,
      //                 ),
      //                 const SizedBox(width: 15),
      //                 FusionAppText(
      //                   text: block.name,
      //                   style: context.textTheme.bodySmall,
      //                 ),
      //               ],
      //             ),
      //           ),
      //         )
      //         .toList(),
      onSelected: (ProcessingBlockModel block) {
        // if (params.type == ProcessingChainDeviceType.source) {
        //   viewModel.addProcessingBlockToSource(block);
        // } else {
        viewModel.addProcessingBlock(block);
        // }
      },
      child: child,
    );
  }
}

class _CollapsibleSideBar extends StatefulWidget {
  const _CollapsibleSideBar({
    super.key,
    required this.builder,
  });
  final Widget Function(BuildContext context, bool isExpanded) builder;

  @override
  State<_CollapsibleSideBar> createState() => _CollapsibleSideBarState();
}

class _CollapsibleSideBarState extends State<_CollapsibleSideBar> {
  bool isExpanded = true;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: isExpanded ? 220 : 70,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: context.colorScheme.strokeLight,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: IconButton(
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              icon: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isExpanded ? 0.5 : 0,
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            height: 1,

            color: context.colorScheme.strokeLight,
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: widget.builder(context, isExpanded),
            ),
          ),
        ],
      ),
    );
  }
}
