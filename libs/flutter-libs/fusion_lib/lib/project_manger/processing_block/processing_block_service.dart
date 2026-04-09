import 'package:fusion_lib/fusion_lib.dart';

extension ProcessingBlockService on ProjectService {
  void addProcessingBlock(ProcessingBlockModel processingBlock) {
    processingBlocks.add(processingBlock.id, processingBlock);
  }

  void addProcessingBlockToParent(ProcessingBlockModel processingBlock, String parentId) {
    processingBlocks.add(processingBlock.id, processingBlock);

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.processingBlock, parentId, processingBlock.id);
  }

  void mapProcessingBlockToParent(String processingBlockId, String parentId) {
    if (!processingBlocks.exists(processingBlockId)) throw Exception('Processing Block $processingBlockId not found');

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.processingBlock, parentId, processingBlockId);
  }

  void removeProcessingBlockFromParent(String processingBlockId, String parentId) {
    if (!processingBlocks.exists(processingBlockId)) return;

    relationships.unlink(RelationshipType.processingBlock, parentId, processingBlockId);
  }

  void removeProcessingBlock(String processingBlockId) {
    processingBlocks.remove(processingBlockId);
    relationships.removeAllRelationships(processingBlockId);
  }

  void updateProcessingBlock(ProcessingBlockModel processingBlock) {
    processingBlocks.add(processingBlock.id, processingBlock);
  }

  ProcessingBlockModel? getProcessingBlock(String id) {
    return processingBlocks.get(id);
  }

  List<ProcessingBlockModel> getAllProcessingBlocks() {
    return processingBlocks.getAll();
  }

  List<ProcessingBlockModel> getProcessingBlockFor({required String parentId, bool includeUserBlocks = false}) {
    final processingBlockIds = relationships.getChildren(RelationshipType.processingBlock, parentId);
    return processingBlockIds
        .map((id) => processingBlocks.get(id))
        .whereType<ProcessingBlockModel>()
        .where((block) => (includeUserBlocks || !block.isforUser))
        .toList();
  }

  void reOrderProcessingBlocks(String parentId, int oldIndex, int newIndex) {
    final processingBlockIds = relationships.getChildren(RelationshipType.processingBlock, parentId).toList();

    final item = processingBlockIds.removeAt(oldIndex);
    processingBlockIds.insert(newIndex, item);

    relationships.reOrder(RelationshipType.processingBlock, parentId, processingBlockIds);
  }
}
