import 'package:fusion_lib/fusion_lib.dart';

extension Aes67Manager on ProjectManager {
  // ==================== Input Streams ====================

  /// Add a new AES67 input stream
  void addAes67InputStream(Aes67Config stream) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.addAes67InputStream(stream);
  }

  /// Update an existing AES67 input stream
  void updateAes67InputStream(Aes67Config stream) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.updateAes67InputStream(stream);
  }

  /// Remove an AES67 input stream
  void removeAes67InputStream(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.removeAes67InputStream(streamId);
  }

  /// Get all AES67 input streams
  List<Aes67Config> getAllAes67InputStreams() {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.getAllAes67InputStreams();
  }

  /// Get an AES67 input stream by ID
  Aes67Config? getAes67InputStreamById(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.getAes67InputStreamById(streamId);
  }

  /// Toggle input stream enabled status
  void toggleAes67InputStreamEnabled(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.toggleAes67InputStreamEnabled(streamId);
  }

  // ==================== Output Streams ====================

  /// Add a new AES67 output stream
  void addAes67OutputStream(Aes67Config stream) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.addAes67OutputStream(stream);
  }

  /// Update an existing AES67 output stream
  void updateAes67OutputStream(Aes67Config stream) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.updateAes67OutputStream(stream);
  }

  /// Remove an AES67 output stream
  void removeAes67OutputStream(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.removeAes67OutputStream(streamId);
  }

  /// Get all AES67 output streams
  List<Aes67Config> getAllAes67OutputStreams() {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.getAllAes67OutputStreams();
  }

  /// Get an AES67 output stream by ID
  Aes67Config? getAes67OutputStreamById(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.getAes67OutputStreamById(streamId);
  }

  /// Toggle output stream enabled status
  void toggleAes67OutputStreamEnabled(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.toggleAes67OutputStreamEnabled(streamId);
  }

  // ==================== General Operations ====================

  /// Get all AES67 streams (both input and output)
  List<Aes67Config> getAllAes67Streams() {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.getAllAes67Streams();
  }

  /// Get an AES67 stream by ID (regardless of type)
  Aes67Config? getAes67StreamById(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.getAes67StreamById(streamId);
  }

  /// Duplicate an AES67 stream
  Aes67Config duplicateAes67Stream(String streamId) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    return projectService!.duplicateAes67Stream(streamId);
  }

  /// Reorder input streams
  void reorderAes67InputStreams({
    required String streamIdToMove,
    required String streamIdAtNewIndex,
  }) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.reorderAes67InputStreams(
      streamIdToMove: streamIdToMove,
      streamIdAtNewIndex: streamIdAtNewIndex,
    );
  }

  /// Reorder output streams
  void reorderAes67OutputStreams({
    required String streamIdToMove,
    required String streamIdAtNewIndex,
  }) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    projectService!.reorderAes67OutputStreams(
      streamIdToMove: streamIdToMove,
      streamIdAtNewIndex: streamIdAtNewIndex,
    );
  }

  // ==================== Source ↔ Stream+Channel Mapping ====================

  /// Assigns multiple stream-channel mappings to [sourceId].
  /// Each entry is stored as "streamId:channelNumber:channelName" under
  /// [RelationshipType.sourceStreamMapping].
  void assignStreamChannelsToSource({
    required String sourceId,
    required List<AssignedStreamChannel> channels,
  }) {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }
    final RelationshipManager rel = projectService!.relationships;

    // Clear any existing mapping for this source first.
    final Set<String> existing = rel.getChildren(RelationshipType.sourceStreamMapping, sourceId);
    for (final String old in List<String>.from(existing)) {
      rel.unlink(RelationshipType.sourceStreamMapping, sourceId, old);
    }

    // Link each channel mapping.
    for (final AssignedStreamChannel ch in channels) {
      final String entry = '${ch.streamId}:${ch.channelNumber}:${ch.channelName}';
      print('[AES67] assignStreamChannelsToSource: linking sourceId=$sourceId → "$entry"');
      rel.link(
        RelationshipType.sourceStreamMapping,
        sourceId,
        entry,
      );
    }
    print('[AES67] assignStreamChannelsToSource done. sourceId=$sourceId total=${channels.length} channels');
  }

  /// Returns all input streams that have at least one source mapped to them,
  /// along with the source-to-channel assignments for each stream.
  ///
  /// Result shape:
  /// ```
  /// [
  ///   AssignedInputStreamInfo(
  ///     streamId: "stream1",
  ///     streamName: "Vocal Mic",
  ///     ipAddress: "239.x.x.x",
  ///     sourceMappings: [
  ///       StreamSourceChannelMapping(sourceId: "src1", channelNumbers: [1, 2]),
  ///       StreamSourceChannelMapping(sourceId: "src2", channelNumbers: [1]),
  ///     ],
  ///   ),
  /// ]
  /// ```
  List<AssignedInputStreamInfo> getAssignedInputStreamChannelsForSource() {
    if (projectService == null) {
      throw Exception('Project service is not initialized.');
    }

    final RelationshipManager rel = projectService!.relationships;

    // Map of streamId → Map<sourceId, Set<channelNumber>>
    final Map<String, Map<String, Set<int>>> streamToSourceChannels = <String, Map<String, Set<int>>>{};

    // Walk every hardware component and inspect their stream mappings.
    final List<HardwareComponent> allHardware = projectService!.hardware.getAll();

    for (final HardwareComponent hw in allHardware) {
      final Set<String> entries = rel.getChildren(RelationshipType.sourceStreamMapping, hw.id);
      for (final String entry in entries) {
        ///
        final List<String> parts = entry.split(':');
        if (parts.length < 3) {
          continue;
        }
        final int? ch = int.tryParse(parts[parts.length - 2]);
        if (ch == null) {
          continue;
        }
        final String streamId = parts.sublist(0, parts.length - 2).join(':');

        streamToSourceChannels.putIfAbsent(streamId, () => <String, Set<int>>{});
        streamToSourceChannels[streamId]!.putIfAbsent(hw.id, () => <int>{}).add(ch);
      }
    }

    // Build the result list, enriching each entry with stream metadata.
    final List<AssignedInputStreamInfo> result = streamToSourceChannels.entries.map((MapEntry<String, Map<String, Set<int>>> e) {
      final String streamId = e.key;
      final Aes67Config? stream = projectService!.aes67Devices.get(streamId);

      final List<StreamSourceChannelMapping> sourceMappings = e.value.entries
          .map(
            (MapEntry<String, Set<int>> sm) => StreamSourceChannelMapping(
              sourceId: sm.key,
              channelNumbers: sm.value.toList()..sort(),
            ),
          )
          .toList();

      return AssignedInputStreamInfo(
        streamId: streamId,
        streamName: stream?.name ?? streamId,
        ipAddress: stream?.ipAddress ?? '-',
        sourceMappings: sourceMappings,
      );
    }).toList();

    // Print result as JSON-like structure
    final List<Map<String, dynamic>> jsonOutput = result
        .map(
          (AssignedInputStreamInfo info) => <String, dynamic>{
            'streamId': info.streamId,
            'streamName': info.streamName,
            'ipAddress': info.ipAddress,
            'source_mapping': info.sourceMappings
                .map(
                  (StreamSourceChannelMapping m) => <String, dynamic>{
                    'sourceId': m.sourceId,
                    'channelNumbers': m.channelNumbers,
                  },
                )
                .toList(),
          },
        )
        .toList();

    print('[AES67] getAssignedInputStreamChannelsForSource result:\n$jsonOutput');

    return result;
  }
}
