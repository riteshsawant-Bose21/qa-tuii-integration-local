import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ProcessingBlockViewmodel on ProjectViewModel {
  void addProcessingBlock(ProcessingBlockModel processingBlock) {
    try {
      projectManager.addProcessingBlock(processingBlock);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add processing block: $e");
      throwError("Failed to add processing block: $e");
    }
  }

  void addProcessingBlockToParent(ProcessingBlockModel processingBlock, String parentId) {
    try {
      projectManager.addProcessingBlockToParent(processingBlock, parentId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add processing block to parent: $e");
      throwError("Failed to add processing block to parent: $e");
    }
  }

  void mapProcessingBlockToParent(String processingBlockId, String parentId) {
    try {
      projectManager.mapProcessingBlockToParent(processingBlockId, parentId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to map processing block to parent: $e");
      throwError("Failed to map processing block to parent: $e");
    }
  }

  void removeProcessingBlockFromParent(String processingBlockId, String parentId) {
    try {
      projectManager.removeProcessingBlockFromParent(processingBlockId, parentId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove processing block from parent: $e");
      throwError("Failed to remove processing block from parent: $e");
    }
  }

  void removeProcessingBlock(String processingBlockId) {
    try {
      projectManager.removeProcessingBlock(processingBlockId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove processing block: $e");
      throwError("Failed to remove processing block: $e");
    }
  }

  void updateProcessingBlock(ProcessingBlockModel processingBlock) {
    try {
      projectManager.updateProcessingBlock(processingBlock);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update processing block: $e");
      throwError("Failed to update processing block: $e");
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

  List<ProcessingBlockModel> getProcessingBlockFor(String parentId) {
    try {
      return projectManager.getProcessingBlockFor(parentId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get processing blocks for parent: $e");
      return <ProcessingBlockModel>[];
    }
  }

  void reOrderProcessingBlocks(String parentId, int oldIndex, int newIndex) {
    try {
      projectManager.reOrderProcessingBlocks(parentId, oldIndex, newIndex);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder processing blocks: $e");
      throwError("Failed to reorder processing blocks: $e");
    }
  }
}
