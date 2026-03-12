import 'package:fusion_lib/fusion_lib.dart';

extension ProcessingBlockManager on ProjectManager {
  //implement methods in ProjectService
  void addProcessingBlock(ProcessingBlockModel processingBlock) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addProcessingBlock(processingBlock);
  }

  void addProcessingBlockToParent(ProcessingBlockModel processingBlock, String parentId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addProcessingBlockToParent(processingBlock, parentId);
  }

  void mapProcessingBlockToParent(String processingBlockId, String parentId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.mapProcessingBlockToParent(processingBlockId, parentId);
  }

  void removeProcessingBlockFromParent(String processingBlockId, String parentId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeProcessingBlockFromParent(processingBlockId, parentId);
  }

  void removeProcessingBlock(String processingBlockId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeProcessingBlock(processingBlockId);
  }

  void updateProcessingBlock(ProcessingBlockModel processingBlock) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateProcessingBlock(processingBlock);
  }

  List<ProcessingBlockModel> getAllProcessingBlocks() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllProcessingBlocks();
  }

  ProcessingBlockModel? getProcessingBlockById({required String processingBlockId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getProcessingBlock(processingBlockId);
  }

  List<ProcessingBlockModel> getProcessingBlockFor(String parentId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getProcessingBlockFor(parentId: parentId);
  }

  void reOrderProcessingBlocks(String parentId, int oldIndex, int newIndex) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.reOrderProcessingBlocks(parentId, oldIndex, newIndex);
  }
}
