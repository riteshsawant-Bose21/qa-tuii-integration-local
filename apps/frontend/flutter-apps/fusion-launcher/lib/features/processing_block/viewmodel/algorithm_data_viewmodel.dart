import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/data/algorithm_layout_data.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item_param.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';
import 'package:fusion_launcher/features/projects/view_model/block_data/block_data_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/algorithm/property_settings.dart';
import 'package:fusion_lib/models/project_entities/processing_block_model.dart';

import '../view/item_widget_builder.dart';

class AlgorithmDataViewmodel extends PBWidgetValueHandler with ChangeNotifier {
  final ProcessingBlockModel processingBlock;
  final FusionAlgorithmsConfig config;

  AlgorithmDataViewmodel({required this.processingBlock, required this.config}) {
    final String algorithmId = processingBlock.algorithmId;
    algorithm = config.algorithms.firstWhereOrNull((Algorithm element) => element.name == algorithmId);
    _loadLayout();
    getParameterValueFromServer();
    //initlize websocket
  }

  final ScrollController scrollController = ScrollController();
  Algorithm? algorithm;
  PBLayout? _layout;
  PBLayout? get layout => _layout;

  /// Throttle timer for updateValue calls
  Timer? _updateThrottleTimer;

  /// Trailing timer to flush the last pending update after a burst ends
  Timer? _updateTrailingTimer;

  /// The latest pending update request (top of stack)
  ({String field, int? dimension, dynamic value})? _pendingUpdate;

  /// Whether a throttle window is currently active
  bool _isThrottling = false;

  Future<void> _loadLayout() async {
    _layout = await AlgorithmLayoutData.getForAlgorithm(algorithm?.name ?? "");
    notifyListeners();
  }

  /// Reload the layout from local storage (useful after customization changes)
  Future<void> reloadLayout() async {
    await _loadLayout();
  }

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
    updateValue(field: item.field, dimension: item.dimension, value: value);
  }

  void getParameterValueFromServer() async {
    final Map<String, dynamic>? responseCallback = await serviceLocator<BlockDataViewmodel>().getBlockData(blockId: processingBlock.id);
    if (responseCallback != null) {
      responseCallback.forEach((String key, dynamic value) {
        if (value is List<dynamic>) {
          for (int i = 0; i < value.length; i++) {
            if (value[i] != null) {
              processingBlock.updateProperty(PropertySetting(name: key, value: value[i], dimension: i));
            }
          }
        } else {
          processingBlock.updateProperty(PropertySetting(name: key, value: value));
        }
      });
      notifyListeners();
    }
  }

  void updateValue({required String field, int? dimension, required dynamic value}) {
    // Always update the local model immediately for responsive UI
    processingBlock.updateProperty(PropertySetting(name: field, value: value, dimension: dimension));
    notifyListeners();

    // Store the latest request (discards any older pending one)
    _pendingUpdate = (field: field, dimension: dimension, value: value);

    if (!_isThrottling) {
      // No throttle window active — send immediately and start the window
      _flushPendingUpdate();
      _isThrottling = true;
      _updateThrottleTimer = Timer(const Duration(milliseconds: 150), () {
        // Throttle window ended — if another update arrived during the window, send it now
        _isThrottling = false;
        if (_pendingUpdate != null) {
          _flushPendingUpdate();
        }
      });
    }

    // Reset trailing timer so the very last update in a burst is never lost
    _updateTrailingTimer?.cancel();
    _updateTrailingTimer = Timer(const Duration(milliseconds: 80), () {
      if (_pendingUpdate != null) {
        _flushPendingUpdate();
      }
    });
  }

  void _flushPendingUpdate() {
    final ({String field, int? dimension, dynamic value})? pending = _pendingUpdate;
    if (pending == null) return;
    _pendingUpdate = null;

    if (serviceLocator<ProjectViewModel>().isInControlMode) {
      serviceLocator<BlockDataViewmodel>().updateBlockParameter(
        blockId: processingBlock.id,
        parameter: pending.field,
        value: pending.value,
        dimension: pending.dimension,
      );
    } else {
      serviceLocator<ProjectViewModel>().updateProcessingBlock(
        processingBlock: processingBlock,
      );
    }
  }

  @override
  void addValue(PBItem item, dynamic value) {
    addProperty(PropertySetting(name: item.field, value: value, dimension: item.dimension));
  }

  void addProperty(PropertySetting property) {
    processingBlock.addProperty(property);
    serviceLocator<ProjectViewModel>().updateProcessingBlock(
      processingBlock: processingBlock,
    );
    notifyListeners();
  }

  void removeProperty(PropertySetting property) {
    processingBlock.removeProperty(property);
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
