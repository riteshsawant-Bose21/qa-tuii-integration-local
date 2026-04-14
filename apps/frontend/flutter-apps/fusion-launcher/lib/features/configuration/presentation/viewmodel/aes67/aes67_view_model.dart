import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension Aes67ViewModel on ProjectViewModel {
  // ==================== Input Streams ====================

  void addAes67InputStream({required Aes67Config stream, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addAes67InputStream(stream);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add AES67 Input Stream Error: ${e.toString()}");
    }
  }

  void updateAes67InputStream({required Aes67Config stream, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateAes67InputStream(stream);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update AES67 Input Stream Error: ${e.toString()}");
    }
  }

  void removeAes67InputStream(String streamId, {bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeAes67InputStream(streamId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove AES67 Input Stream Error: ${e.toString()}");
    }
  }

  List<Aes67Config> getAllAes67InputStreams() {
    try {
      return projectManager.getAllAes67InputStreams();
    } catch (e) {
      throwError("Get All AES67 Input Streams Error: ${e.toString()}");
      return <Aes67Config>[];
    }
  }

  Aes67Config? getAes67InputStreamById(String streamId) {
    try {
      return projectManager.getAes67InputStreamById(streamId);
    } catch (e) {
      throwError("Get AES67 Input Stream By Id Error: ${e.toString()}");
      return null;
    }
  }

  void toggleAes67InputStreamEnabled(String streamId, {bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.toggleAes67InputStreamEnabled(streamId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Toggle AES67 Input Stream Enabled Error: ${e.toString()}");
    }
  }

  // ==================== Output Streams ====================

  void addAes67OutputStream({required Aes67Config stream, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addAes67OutputStream(stream);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add AES67 Output Stream Error: ${e.toString()}");
    }
  }

  void updateAes67OutputStream({required Aes67Config stream, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateAes67OutputStream(stream);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update AES67 Output Stream Error: ${e.toString()}");
    }
  }

  void removeAes67OutputStream(String streamId, {bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeAes67OutputStream(streamId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove AES67 Output Stream Error: ${e.toString()}");
    }
  }

  List<Aes67Config> getAllAes67OutputStreams() {
    try {
      return projectManager.getAllAes67OutputStreams();
    } catch (e) {
      throwError("Get All AES67 Output Streams Error: ${e.toString()}");
      return <Aes67Config>[];
    }
  }

  Aes67Config? getAes67OutputStreamById(String streamId) {
    try {
      return projectManager.getAes67OutputStreamById(streamId);
    } catch (e) {
      throwError("Get AES67 Output Stream By Id Error: ${e.toString()}");
      return null;
    }
  }

  void toggleAes67OutputStreamEnabled(String streamId, {bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.toggleAes67OutputStreamEnabled(streamId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Toggle AES67 Output Stream Enabled Error: ${e.toString()}");
    }
  }

  // ==================== General Operations ====================

  List<Aes67Config> getAllAes67Streams() {
    try {
      return projectManager.getAllAes67Streams();
    } catch (e) {
      throwError("Get All AES67 Streams Error: ${e.toString()}");
      return <Aes67Config>[];
    }
  }

  Aes67Config? getAes67StreamById(String streamId) {
    try {
      return projectManager.getAes67StreamById(streamId);
    } catch (e) {
      throwError("Get AES67 Stream By Id Error: ${e.toString()}");
      return null;
    }
  }

  Aes67Config? duplicateAes67Stream(String streamId, {bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final Aes67Config duplicated = projectManager.duplicateAes67Stream(streamId);
      if (autoSave) {
        saveProject();
      }
      return duplicated;
    } catch (e) {
      throwError("Duplicate AES67 Stream Error: ${e.toString()}");
      return null;
    }
  }

  void reorderAes67InputStreams({
    required String streamIdToMove,
    required String streamIdAtNewIndex,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reorderAes67InputStreams(
        streamIdToMove: streamIdToMove,
        streamIdAtNewIndex: streamIdAtNewIndex,
      );
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Reorder AES67 Input Streams Error: ${e.toString()}");
    }
  }

  void reorderAes67OutputStreams({
    required String streamIdToMove,
    required String streamIdAtNewIndex,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reorderAes67OutputStreams(
        streamIdToMove: streamIdToMove,
        streamIdAtNewIndex: streamIdAtNewIndex,
      );
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Reorder AES67 Output Streams Error: ${e.toString()}");
    }
  }
}
