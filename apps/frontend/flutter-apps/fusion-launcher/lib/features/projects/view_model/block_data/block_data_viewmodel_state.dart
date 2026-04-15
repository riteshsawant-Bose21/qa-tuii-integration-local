part of 'block_data_viewmodel.dart';

/// Describes why the WebSocket config stream is currently inactive.
enum BlockDataInactiveReason { notStarted, controlModeOff, projectClosed }

class BlockDataState {
  final String? blockId;
  final Map<String, dynamic>? blockData;

  /// All block data from WebSocket config subscription, keyed by block ID.
  /// e.g. {"GAIN117180817": {"gain": 5.43}, "GAIN467199143": {"gain": 12}}
  final Map<String, Map<String, dynamic>> allBlockData;

  /// Whether the WebSocket is currently connected and subscribed.
  final bool isConnected;

  /// Non-null when the connection is intentionally inactive.
  final BlockDataInactiveReason? inactiveReason;

  BlockDataState({
    this.blockId,
    this.blockData,
    this.allBlockData = const <String, Map<String, dynamic>>{},
    this.isConnected = false,
    this.inactiveReason = BlockDataInactiveReason.notStarted,
  });

  /// Convenience: get data for a specific block from the live WebSocket feed.
  Map<String, dynamic>? dataForBlock(String blockId) => allBlockData[blockId];

  BlockDataState copyWith({
    String? blockId,
    Map<String, dynamic>? blockData,
    Map<String, Map<String, dynamic>>? allBlockData,
    bool? isConnected,
    BlockDataInactiveReason? inactiveReason,
    bool clearInactiveReason = false,
  }) {
    return BlockDataState(
      blockId: blockId ?? this.blockId,
      blockData: blockData ?? this.blockData,
      allBlockData: allBlockData ?? this.allBlockData,
      isConnected: isConnected ?? this.isConnected,
      inactiveReason: clearInactiveReason ? null : (inactiveReason ?? this.inactiveReason),
    );
  }
}
