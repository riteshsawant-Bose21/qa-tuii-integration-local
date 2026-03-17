import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ProcessingBlockViewmodel on ProjectViewModel {
  void addProcessingBlock({required ProcessingBlockModel processingBlock, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addProcessingBlock(processingBlock);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add processing block: $e");
      throwError("Failed to add processing block: $e");
    }
  }

  void addProcessingBlockToParent({required ProcessingBlockModel processingBlock, required String parentId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addProcessingBlockToParent(processingBlock, parentId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add processing block to parent: $e");
      throwError("Failed to add processing block to parent: $e");
    }
  }

  void mapProcessingBlockToParent({required String processingBlockId, required String parentId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.mapProcessingBlockToParent(processingBlockId, parentId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to map processing block to parent: $e");
      throwError("Failed to map processing block to parent: $e");
    }
  }

  void removeProcessingBlockFromParent({required String processingBlockId, required String parentId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeProcessingBlockFromParent(processingBlockId, parentId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove processing block from parent: $e");
      throwError("Failed to remove processing block from parent: $e");
    }
  }

  void removeProcessingBlock({required String processingBlockId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeProcessingBlock(processingBlockId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove processing block: $e");
      throwError("Failed to remove processing block: $e");
    }
  }

  void updateProcessingBlock({required ProcessingBlockModel processingBlock, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateProcessingBlock(processingBlock);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update processing block: $e");
      throwError("Failed to update processing block: $e");
    }
  }

  void updateBlockProperty({required String blockId, required PropertySetting property, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }

      final ProcessingBlockModel? processingBlock = projectManager.getProcessingBlockById(processingBlockId: blockId);

      if (processingBlock == null) {
        throwError("Processing block with id $blockId not found");
      } else {
        final ProcessingBlockModel updatedBlock = processingBlock.updateProperty(property);
        projectManager.updateProcessingBlock(updatedBlock);
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update block property: $e");
      throwError("Failed to update block property: $e");
    }
  }

  List<ProcessingBlockModel> getAllProcessingBlocks() {
    try {
      return projectManager.getAllProcessingBlocks();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all processing blocks: $e");
      return <ProcessingBlockModel>[];
    }
  }

  List<ProcessingBlockModel> getProcessingBlockFor({required String parentId, bool includeUserBlocks = false}) {
    try {
      return projectManager.getProcessingBlockFor(parentId: parentId, includeUserBlocks: includeUserBlocks);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get processing blocks for parent: $e");
      return <ProcessingBlockModel>[];
    }
  }

  void reOrderProcessingBlocks({required String parentId, required int oldIndex, required int newIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderProcessingBlocks(parentId, oldIndex, newIndex);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder processing blocks: $e");
      throwError("Failed to reorder processing blocks: $e");
    }
  }

  ProcessingBlockModel? getProcessingBlockById({required String processingBlockId}) {
    try {
      return projectManager.getProcessingBlockById(processingBlockId: processingBlockId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get processing block by id: $e");
      return null;
    }
  }

  ProcessingBlockModel? getUserFacingGainBlockForZone({required String zoneId}) {
    try {
      final List<ProcessingBlockModel> processingBlocks = projectManager.getProcessingBlockFor(parentId: zoneId, includeUserBlocks: true);
      return processingBlocks.firstWhereOrNull((ProcessingBlockModel block) => block.algorithmId == "gain" && block.isforUser);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get user facing gain block for zone: $e");
      return null;
    }
  }
}
