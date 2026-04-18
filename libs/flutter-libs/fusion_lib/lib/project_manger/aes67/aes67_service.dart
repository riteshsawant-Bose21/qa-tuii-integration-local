import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

extension Aes67Service on ProjectService {
  // ==================== Input Streams ====================

  /// Add a new AES67 input stream
  void addAes67InputStream(Aes67Config stream) {
    if (stream.streamType != Aes67StreamType.input) {
      throw Exception('Stream type must be input for addAes67InputStream');
    }
    aes67Devices.add(stream.id, stream);
    relationships.link(RelationshipType.aes67InputStreams, id, stream.id);
  }

  /// Update an existing AES67 input stream
  void updateAes67InputStream(Aes67Config stream) {
    if (!aes67Devices.exists(stream.id)) {
      throw Exception('AES67 input stream with id ${stream.id} does not exist');
    }
    aes67Devices.add(stream.id, stream);
  }

  /// Remove an AES67 input stream
  void removeAes67InputStream(String streamId) {
    if (!aes67Devices.exists(streamId)) {
      throw Exception('AES67 input stream with id $streamId does not exist');
    }
    relationships.unlink(RelationshipType.aes67InputStreams, id, streamId);
    aes67Devices.remove(streamId);
  }

  /// Get all AES67 input streams
  List<Aes67Config> getAllAes67InputStreams() {
    final streamIds = relationships.getChildren(RelationshipType.aes67InputStreams, id);
    return streamIds
        .map((streamId) => aes67Devices.get(streamId))
        .whereType<Aes67Config>()
        .where((stream) => stream.streamType == Aes67StreamType.input)
        .toList();
  }

  /// Get an AES67 input stream by ID
  Aes67Config? getAes67InputStreamById(String streamId) {
    final stream = aes67Devices.get(streamId);
    if (stream != null && stream.streamType == Aes67StreamType.input) {
      return stream;
    }
    return null;
  }

  /// Toggle input stream enabled status
  void toggleAes67InputStreamEnabled(String streamId) {
    final stream = aes67Devices.get(streamId);
    if (stream == null || stream.streamType != Aes67StreamType.input) {
      throw Exception('AES67 input stream with id $streamId does not exist');
    }
    final updatedStream = stream.copyWith(isEnabled: !stream.isEnabled);
    aes67Devices.add(streamId, updatedStream);
  }

  // ==================== Output Streams ====================

  /// Add a new AES67 output stream
  void addAes67OutputStream(Aes67Config stream) {
    if (stream.streamType != Aes67StreamType.output) {
      throw Exception('Stream type must be output for addAes67OutputStream');
    }
    aes67Devices.add(stream.id, stream);
    relationships.link(RelationshipType.aes67OutputStreams, id, stream.id);
  }

  /// Update an existing AES67 output stream
  void updateAes67OutputStream(Aes67Config stream) {
    if (!aes67Devices.exists(stream.id)) {
      throw Exception('AES67 output stream with id ${stream.id} does not exist');
    }
    aes67Devices.add(stream.id, stream);
  }

  /// Remove an AES67 output stream
  void removeAes67OutputStream(String streamId) {
    if (!aes67Devices.exists(streamId)) {
      throw Exception('AES67 output stream with id $streamId does not exist');
    }
    relationships.unlink(RelationshipType.aes67OutputStreams, id, streamId);
    aes67Devices.remove(streamId);
  }

  /// Get all AES67 output streams
  List<Aes67Config> getAllAes67OutputStreams() {
    final streamIds = relationships.getChildren(RelationshipType.aes67OutputStreams, id);
    return streamIds
        .map((streamId) => aes67Devices.get(streamId))
        .whereType<Aes67Config>()
        .where((stream) => stream.streamType == Aes67StreamType.output)
        .toList();
  }

  /// Get an AES67 output stream by ID
  Aes67Config? getAes67OutputStreamById(String streamId) {
    final stream = aes67Devices.get(streamId);
    if (stream != null && stream.streamType == Aes67StreamType.output) {
      return stream;
    }
    return null;
  }

  /// Toggle output stream enabled status
  void toggleAes67OutputStreamEnabled(String streamId) {
    final stream = aes67Devices.get(streamId);
    if (stream == null || stream.streamType != Aes67StreamType.output) {
      throw Exception('AES67 output stream with id $streamId does not exist');
    }
    final updatedStream = stream.copyWith(isEnabled: !stream.isEnabled);
    aes67Devices.add(streamId, updatedStream);
  }

  // ==================== General Operations ====================

  /// Get all AES67 streams (both input and output)
  List<Aes67Config> getAllAes67Streams() {
    return aes67Devices.getAll();
  }

  /// Get an AES67 stream by ID (regardless of type)
  Aes67Config? getAes67StreamById(String streamId) {
    return aes67Devices.get(streamId);
  }

  /// Duplicate an AES67 stream
  Aes67Config duplicateAes67Stream(String streamId) {
    final stream = aes67Devices.get(streamId);
    if (stream == null) {
      throw Exception('AES67 stream with id $streamId does not exist');
    }

    final duplicatedStream = Aes67Config(
      name: '${stream.name} (Copy)',
      device: stream.device,
      streamType: stream.streamType,
      streamOrAdvertisement: stream.streamOrAdvertisement,
      ipAddress: stream.ipAddress,
      port: stream.port,
      channels: stream.channels,
      bitDepth: stream.bitDepth,
      sampleRate: stream.sampleRate,
      packetTime: stream.packetTime,
      isEnabled: stream.isEnabled,
      channelConfigs: stream.channelConfigs,
      sessions: stream.sessions,
    );

    aes67Devices.add(duplicatedStream.id, duplicatedStream);

    // Link to appropriate relationship based on stream type
    if (stream.streamType == Aes67StreamType.input) {
      relationships.link(RelationshipType.aes67InputStreams, id, duplicatedStream.id);
    } else {
      relationships.link(RelationshipType.aes67OutputStreams, id, duplicatedStream.id);
    }

    return duplicatedStream;
  }

  /// Reorder input streams
  void reorderAes67InputStreams({
    required String streamIdToMove,
    required String streamIdAtNewIndex,
  }) {
    final currentOrder = relationships.getChildren(RelationshipType.aes67InputStreams, id).toList();
    final oldIndex = currentOrder.indexOf(streamIdToMove);
    final newIndex = currentOrder.indexOf(streamIdAtNewIndex);

    if (oldIndex == -1 || newIndex == -1) return;

    currentOrder.removeAt(oldIndex);
    currentOrder.insert(newIndex, streamIdToMove);

    relationships.reOrder(RelationshipType.aes67InputStreams, id, currentOrder);
  }

  /// Reorder output streams
  void reorderAes67OutputStreams({
    required String streamIdToMove,
    required String streamIdAtNewIndex,
  }) {
    final currentOrder = relationships.getChildren(RelationshipType.aes67OutputStreams, id).toList();
    final oldIndex = currentOrder.indexOf(streamIdToMove);
    final newIndex = currentOrder.indexOf(streamIdAtNewIndex);

    if (oldIndex == -1 || newIndex == -1) return;

    currentOrder.removeAt(oldIndex);
    currentOrder.insert(newIndex, streamIdToMove);

    relationships.reOrder(RelationshipType.aes67OutputStreams, id, currentOrder);
  }

  // ==================== Source ↔ Stream+Channel Mapping ====================

  /// Assigns multiple stream-channel mappings to [sourceId].
  void assignStreamChannelsToSource({
    required String sourceId,
    required List<AssignedStreamChannel> channels,
  }) {
    // Clear any existing mapping for this source first.
    final Set<String> existing = relationships.getChildren(RelationshipType.sourceStreamMapping, sourceId);
    for (final String old in List<String>.from(existing)) {
      relationships.unlink(RelationshipType.sourceStreamMapping, sourceId, old);
    }

    // Link each channel mapping.
    for (final AssignedStreamChannel ch in channels) {
      final String entry = '${ch.streamId}:${ch.channelNumber}:${ch.channelName}';
      relationships.link(RelationshipType.sourceStreamMapping, sourceId, entry);
    }
  }

  /// Returns a raw map of streamId → Map<sourceId, Set<channelNumber>>
  /// by reading all [RelationshipType.sourceStreamMapping] entries across
  /// every hardware component.
  Map<String, Map<String, Set<int>>> getAllSourceStreamMappings() {
    final Map<String, Map<String, Set<int>>> streamToSourceChannels = <String, Map<String, Set<int>>>{};

    for (final HardwareComponent hw in hardware.getAll()) {
      final Set<String> entries = relationships.getChildren(RelationshipType.sourceStreamMapping, hw.id);
      for (final String entry in entries) {
        final List<String> parts = entry.split(':');
        if (parts.length < 3) continue;
        final int? ch = int.tryParse(parts[parts.length - 2]);
        if (ch == null) continue;
        final String streamId = parts.sublist(0, parts.length - 2).join(':');

        streamToSourceChannels.putIfAbsent(streamId, () => <String, Set<int>>{});
        streamToSourceChannels[streamId]!.putIfAbsent(hw.id, () => <int>{}).add(ch);
      }
    }

    return streamToSourceChannels;
  }

  /// Returns all input streams that have at least one source mapped to them,
  /// along with the source-to-channel assignments for each stream.
  List<AssignedInputStreamInfo> getAssignedInputStreamChannelsForSource() {
    final Map<String, Map<String, Set<int>>> streamToSourceChannels = getAllSourceStreamMappings();

    return streamToSourceChannels.entries.map((MapEntry<String, Map<String, Set<int>>> e) {
      final String streamId = e.key;
      final Aes67Config? stream = aes67Devices.get(streamId);

      final List<StreamSourceChannelMapping> sourceMappings = e.value.entries
          .map(
            (MapEntry<String, Set<int>> sm) => StreamSourceChannelMapping(
              sourceId: sm.key,
              channelNumbers: sm.value.toList()..sort(),
            ),
          )
          .toList();

      print(
        JsonEncoder.withIndent('  ').convert({
          'streamId': streamId,
          'streamName': stream?.name ?? streamId,
          'ipAddress': stream?.ipAddress ?? '-',
          'sourceMappings': sourceMappings
              .map(
                (s) => {
                  'sourceId': s.sourceId,
                  'channelNumbers': s.channelNumbers,
                },
              )
              .toList(),
        }),
      );

      return AssignedInputStreamInfo(
        streamId: streamId,
        streamName: stream?.name ?? streamId,
        ipAddress: stream?.ipAddress ?? '-',
        sourceMappings: sourceMappings,
      );
    }).toList();
  }
}
