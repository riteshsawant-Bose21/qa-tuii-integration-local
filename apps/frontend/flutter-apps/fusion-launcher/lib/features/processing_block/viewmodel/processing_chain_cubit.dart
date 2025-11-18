// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/state/processing_chain_methods.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/processing_chain_state.dart';

enum ProcessingChainDeviceType { source, sourceSet, zone, subzone, circuit }

class ProcessingChainCubit extends Cubit<ProcessingChainState> {
  final ProcessingChainParams param;
  final ProjectViewModel viewModel;
  ProcessingChainCubit({required this.param, required this.viewModel}) : super(EmptyProcessingChainState()) {
    load();
  }

  void load() {
    final List<ProcessingBlockModel> blocks = viewModel.getProcessingBlockFor(parentId: param.id);
    if (blocks.isNotEmpty) {
      emit(
        UpdatedProcessingChainState(
          blocks: blocks,
          selectedBlock: blocks.first,
        ),
      );
    }
  }

  void addProcessingBlock(ProcessingBlockModel block) {
    final ProcessingBlockModel newBlock = block.copyWith(
      id: block.algorithmId.toUpperCase() + FusionUtils.shortStringUUID(),
    );
    viewModel.addProcessingBlockToParent(
      processingBlock: newBlock,
      parentId: param.id,
    );
    emit(
      state.add(newBlock).select(newBlock),
    );
  }

  void selectProcessingBlock(ProcessingBlockModel block) {
    emit(
      state.select(block),
    );
  }

  void reorderProcessingBlocks(int oldIndex, int newIndex) {
    viewModel.reOrderProcessingBlocks(
      parentId: param.id,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (state is UpdatedProcessingChainState) {
      final UpdatedProcessingChainState currentState = state as UpdatedProcessingChainState;
      final List<ProcessingBlockModel> updatedBlocks = List<ProcessingBlockModel>.from(currentState.blocks);
      final ProcessingBlockModel movedBlock = updatedBlocks.removeAt(oldIndex);
      updatedBlocks.insert(newIndex, movedBlock);
      emit(
        UpdatedProcessingChainState(
          blocks: updatedBlocks,
          selectedBlock: currentState.selectedBlock,
        ),
      );
    } else {
      load();
    }
  }
}

class ProcessingChainParams {
  final String id;
  final ProcessingChainDeviceType type;
  final String name;

  ProcessingChainParams({required this.id, required this.type, required this.name});

  @override
  bool operator ==(covariant ProcessingChainParams other) {
    if (identical(this, other)) return true;

    return other.id == id && other.type == type && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ name.hashCode;
}
