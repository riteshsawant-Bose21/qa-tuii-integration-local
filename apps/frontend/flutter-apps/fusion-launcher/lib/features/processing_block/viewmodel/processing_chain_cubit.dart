import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/state/processing_chain_methods.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/processing_chain_state.dart';

class ProcessingChainCubit extends Cubit<ProcessingChainState> {
  final String parentId;
  final ProjectViewModel viewModel;
  ProcessingChainCubit({required this.parentId, required this.viewModel}) : super(EmptyProcessingChainState()) {
    load();
  }

  void load() {
    final List<ProcessingBlockModel> blocks = viewModel.getProcessingBlockFor(parentId: parentId);
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
      parentId: parentId,
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
      parentId: parentId,
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
