import 'package:fusion_lib/models/project_entities/processing_block_model.dart';

import 'processing_chain_state.dart';

extension ProcessingChainMethods on ProcessingChainState {
  ProcessingChainState add(ProcessingBlockModel block) {
    if (this is UpdatedProcessingChainState) {
      final UpdatedProcessingChainState currentState = this as UpdatedProcessingChainState;
      final List<ProcessingBlockModel> updatedBlocks = List<ProcessingBlockModel>.from(currentState.blocks)..add(block);
      return UpdatedProcessingChainState(
        blocks: updatedBlocks,
        selectedBlock: currentState.selectedBlock,
      );
    } else {
      return UpdatedProcessingChainState(
        blocks: <ProcessingBlockModel>[block],
        selectedBlock: block,
      );
    }
  }

  ProcessingChainState select(ProcessingBlockModel block) {
    if (this is UpdatedProcessingChainState) {
      final UpdatedProcessingChainState currentState = this as UpdatedProcessingChainState;
      return UpdatedProcessingChainState(
        blocks: currentState.blocks,
        selectedBlock: block,
      );
    } else {
      return UpdatedProcessingChainState(
        blocks: <ProcessingBlockModel>[],
        selectedBlock: block,
      );
    }
  }
}
