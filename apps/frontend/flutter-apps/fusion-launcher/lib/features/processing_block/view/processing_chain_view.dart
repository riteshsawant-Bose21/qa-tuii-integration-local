import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../state/processing_chain_state.dart';
import '../viewmodel/processing_chain_cubit.dart';
import 'customization/processing_block_customizer.dart';
import 'processing_block_page.dart';
import 'widgets/dotted_line.dart';

class ProcessingChainView extends StatelessWidget {
  const ProcessingChainView({super.key, required this.params});
  final ProcessingChainParams params;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        /// --------------------------------------------------------------------------------
        /// HEADING
        /// --------------------------------------------------------------------------------
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text:
                      "${switch (params.type) {
                        ProcessingChainDeviceType.source => "SOURCE PROCESSING ",
                        ProcessingChainDeviceType.sourceSet => "SOURCE SET PROCESSING ",
                        ProcessingChainDeviceType.zone => "ZONE PROCESSING ",
                        ProcessingChainDeviceType.subzone => "SUBZONE PROCESSING ",
                        ProcessingChainDeviceType.circuit => "CIRCUIT PROCESSING ",
                      }} - ${params.name}",
                  // "SOURCE PROCESSING_WIRELESS MIC 1",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        /// --------------------------------------------------------------------------------
                        /// HEADING
                        /// --------------------------------------------------------------------------------
                        SizedBox(
                          width: 600,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              const DottedLine(
                                dotSize: 5,
                                spacing: 4,
                                color: Colors.grey,
                              ),
                              Row(
                                spacing: 10,
                                children: <Widget>[
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: ReorderableRow<ProcessingBlockModel>(
                                        // scrollDirection: Axis.horizontal,
                                        // buildDefaultDragHandles: true,
                                        onReorder: (int oldIndex, int newIndex) {
                                          viewModel.reorderProcessingBlocks(oldIndex, newIndex);
                                        },
                                        items: state.blocks,
                                        itemBuilder:
                                            (BuildContext context, ProcessingBlockModel block) => InkWell(
                                              key: ValueKey<String>(block.id),
                                              onTap: () {
                                                viewModel.selectProcessingBlock(block);
                                              },
                                              child: Tooltip(
                                                message: block.name,
                                                child: _PBIcon(
                                                  icon: block.iconAsset,
                                                  isActive: block.id == state.selectedBlock.id,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  AddProcessingBlockButton(
                                    params: params,
                                    viewModel: viewModel,
                                    child: Container(
                                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(5)),
                                      padding: const EdgeInsets.all(5),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Row(
                          spacing: 10,
                          children: <Widget>[
                            const SizedBox(),
                            Container(
                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                state.selectedBlock.iconAsset,
                                color: Colors.black,
                                height: 18,
                                width: 18,
                              ),
                            ),

                            Text(
                              state.selectedBlock.name,
                            ),
                            const Spacer(),
                            Tooltip(
                              message: "Delete Selected Processing Block",
                              child: InkWell(
                                onTap: () {
                                  viewModel.deleteSelectedProcessingBlock();
                                },
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            Tooltip(
                              message: "Customize Processing Block Layout",
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute<void>(
                                          builder:
                                              (BuildContext context) => Scaffold(
                                                appBar: AppBar(),
                                                body: ProcessingBlockCustomizer(
                                                  selectedAlgorithmId: state.selectedBlock.algorithmId,
                                                ),
                                              ),
                                        ),
                                      )
                                      // refresh the layout from storage
                                      .whenComplete(
                                        () {
                                          viewModel.refreshProcessingBlock(state.selectedBlock);
                                        },
                                      );
                                },
                                child: const Icon(Icons.edit_outlined),
                              ),
                            ),
                            const SizedBox(),
                          ],
                        ),
                        const Divider(),
                        Flexible(
                          child: ProcessingBlockPage(
                            processingBlock: state.selectedBlock,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
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
      decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        icon,
        color: Colors.white,
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
    return PopupMenuButton<ProcessingBlockModel>(
      tooltip: "Add Processing Block",
      child: child,
      itemBuilder:
          (BuildContext context) =>
              switch (params.type) {
                    ProcessingChainDeviceType.source || ProcessingChainDeviceType.sourceSet => ProcessingBlockModel.sourceBlocks,
                    ProcessingChainDeviceType.zone || ProcessingChainDeviceType.subzone => ProcessingBlockModel.zoneBlocks,
                    ProcessingChainDeviceType.circuit => ProcessingBlockModel.circuitBlocks,
                  }
                  .map(
                    (ProcessingBlockModel block) => PopupMenuItem<ProcessingBlockModel>(
                      height: 40,
                      value: block,
                      child: Row(
                        children: <Widget>[
                          Image.asset(
                            block.iconAsset,
                            color: Colors.black,
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
                  )
                  .toList(),
      onSelected: (ProcessingBlockModel block) {
        // if (params.type == ProcessingChainDeviceType.source) {
        //   viewModel.addProcessingBlockToSource(block);
        // } else {
        viewModel.addProcessingBlock(block);
        // }
      },
    );
  }
}
