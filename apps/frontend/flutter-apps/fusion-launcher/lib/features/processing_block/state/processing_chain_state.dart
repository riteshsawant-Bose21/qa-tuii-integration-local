import 'package:fusion_lib/fusion_lib.dart';

abstract class ProcessingChainState {
  ProcessingChainState();
}

class EmptyProcessingChainState extends ProcessingChainState {
  EmptyProcessingChainState();
}

class UpdatedProcessingChainState extends ProcessingChainState {
  final List<ProcessingBlockModel> blocks;
  final ProcessingBlockModel selectedBlock;
  UpdatedProcessingChainState({
    required this.blocks,
    required this.selectedBlock,
  });
}
