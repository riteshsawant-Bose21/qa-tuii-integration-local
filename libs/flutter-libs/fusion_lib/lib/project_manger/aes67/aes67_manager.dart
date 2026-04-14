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
}
