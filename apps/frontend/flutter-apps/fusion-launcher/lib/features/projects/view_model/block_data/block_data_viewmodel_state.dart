part of 'block_data_viewmodel.dart';

class BlockDataState {
  final String? blockId;
  final Map<String, dynamic>? blockData;

  BlockDataState({
    this.blockId,
    this.blockData,
  });

  // Add a copyWith method for easier state updates
  BlockDataState copyWith({
    String? blockId,
    Map<String, dynamic>? blockData,
  }) {
    return BlockDataState(
      blockId: blockId ?? this.blockId,
      blockData: blockData ?? this.blockData,
    );
  }
}
