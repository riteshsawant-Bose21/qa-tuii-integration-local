import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/dro/dro_input_model.dart';
import 'package:fusion_lib/project_manger/dro/dro_input_mapper_service.dart';

extension DroInputMapper on ProjectManager {
  DroInputModel getDroInputData() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getDroInputData();
  }

  Map<String, dynamic> getAllProcessingBlockData() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    List<ProcessingBlockModel> processingBlocks = projectService!.getAllProcessingBlocks();
    Map<String, dynamic> processingBlockData = {};
    for (ProcessingBlockModel block in processingBlocks) {
      if (block.properties.isNotEmpty) {
        Map<String, dynamic> blocksProperties = {};
        for (PropertySetting property in block.properties) {
          if (property.dimension == null) {
            blocksProperties[property.name] = property.value;
          } else {
            //if has dimension then value is list of items where dimension is index, insert value at index with all other values set to null till index
            final int index = property.dimension!;
            List<dynamic> valueList = blocksProperties[property.name] is List<dynamic> ? blocksProperties[property.name] as List<dynamic> : <dynamic>[];
            if (valueList.length <= index) {
              valueList.addAll(List<dynamic>.filled(index - valueList.length + 1, null));
            }
            valueList[index] = property.value;
            blocksProperties[property.name] = valueList;
          }
        }
        processingBlockData[block.id] = blocksProperties;
      }
    }
    return processingBlockData;
  }
}
