import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/data/algorithm_layout_data.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item_param.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';
import 'package:fusion_lib/models/algorithm/property_settings.dart';
import 'package:fusion_lib/models/project_entities/processing_block_model.dart';

import '../view/item_widget_builder.dart';

class AlgorithmDataViewmodel extends PBWidgetValueHandler with ChangeNotifier {
  final ProcessingBlockModel processingBlock;
  final FusionAlgorithmsConfig config;

  AlgorithmDataViewmodel({required this.processingBlock, required this.config}) {
    final String algorithmId = processingBlock.algorithmId;
    algorithm = config.algorithms.firstWhereOrNull((Algorithm element) => element.name == algorithmId);
    layout = AlgorithmLayoutData.getForAlgorithm(algorithmId);
  }

  Algorithm? algorithm;
  PBLayout? layout;

  @override
  dynamic getValue(PBItem param) {
    return processingBlock.properties
            .firstWhereOrNull((PropertySetting element) => element.name == param.field && element.dimension == param.dimension)
            ?.value ??
        resolveValue(
          algorithm?.parameters?.firstWhereOrNull((Parameter element) => element.name == param.field)?.defaultValue ??
              algorithm?.telemetry?.firstWhereOrNull((Telemetry e) => e.name == param.field)?.defaultValue,
        );
  }

  @override
  void onValueChanged(PBItem item, dynamic value) {
    processingBlock.updateProperty(PropertySetting(name: item.field, value: value, dimension: item.dimension));
    serviceLocator<ProjectViewModel>().updateProcessingBlock(
      processingBlock: processingBlock,
    );
    notifyListeners();
  }

  @override
  PBItemParam resolveForItem(PBItem item) {
    if (item.param is PBSliderParam) {
      return resolveSliderParam(item);
    }
    if (item.param is PBTextfieldParam) {
      return resolveTextfieldParam(item);
    }
    if (item.param is PBMeterParam) {
      return resolveMeterParam(item);
    }
    if (item.param is PBDropdownParam) {
      return resolveDropdownParam(item);
    }

    return item.param;
  }

  PBSliderParam resolveSliderParam(PBItem item) {
    final Parameter? parameter = algorithm?.parameters?.firstWhereOrNull((Parameter element) => element.name == item.field);
    if (parameter != null) {
      return (item.param as PBSliderParam).copyWith(
        min: resolveValue(parameter.minimumValue) ?? 0,
        max: resolveValue(parameter.maximumValue) ?? 100,
      );
    }
    final Telemetry? telemetry = algorithm?.telemetry?.firstWhereOrNull((Telemetry element) => element.name == item.field);
    if (telemetry != null) {
      return (item.param as PBSliderParam).copyWith(
        min: resolveValue(telemetry.minimumValue) ?? 0,
        max: resolveValue(telemetry.maximumValue) ?? 100,
      );
    }
    return item.param as PBSliderParam;
  }

  PBTextfieldParam resolveTextfieldParam(PBItem item) {
    final Parameter? parameter = algorithm?.parameters?.firstWhereOrNull((Parameter element) => element.name == item.field);
    if (parameter != null) {
      return (item.param as PBTextfieldParam).copyWith(
        min: resolveValue(parameter.minimumValue) ?? 0,
        max: resolveValue(parameter.maximumValue) ?? 100,
      );
    }
    final Telemetry? telemetry = algorithm?.telemetry?.firstWhereOrNull((Telemetry element) => element.name == item.field);
    if (telemetry != null) {
      return (item.param as PBTextfieldParam).copyWith(
        min: resolveValue(telemetry.minimumValue) ?? 0,
        max: resolveValue(telemetry.maximumValue) ?? 100,
      );
    }
    return item.param as PBTextfieldParam;
  }

  PBDropdownParam resolveDropdownParam(PBItem item) {
    final Parameter? parameter = algorithm?.parameters?.firstWhereOrNull((Parameter element) => element.name == item.field);
    if (parameter != null) {
      final List<String> options = <String>[];
      if (parameter.allowedValues != null) {
        for (final dynamic option in parameter.allowedValues!) {
          options.add(option.toString());
        }
      }
      return (item.param as PBDropdownParam).copyWith(
        options: options,
      );
    }
    return item.param as PBDropdownParam;
  }

  PBMeterParam resolveMeterParam(PBItem item) {
    final Parameter? parameter = algorithm?.parameters?.firstWhereOrNull((Parameter element) => element.name == item.field);
    if (parameter != null) {
      return (item.param as PBMeterParam).copyWith(
        min: resolveValue(parameter.minimumValue) ?? 0,
        max: resolveValue(parameter.maximumValue) ?? 100,
      );
    }
    final Telemetry? telemetry = algorithm?.telemetry?.firstWhereOrNull((Telemetry element) => element.name == item.field);
    if (telemetry != null) {
      return (item.param as PBMeterParam).copyWith(
        min: resolveValue(telemetry.minimumValue) ?? 0,
        max: resolveValue(telemetry.maximumValue) ?? 100,
      );
    }
    return item.param as PBMeterParam;
  }

  dynamic resolveValue(dynamic val) {
    if (val is String) {
      return algorithm?.properties?.firstWhereOrNull((Property element) => element.name == val)?.defaultValue ?? val;
    }
    return val;
  }
}
