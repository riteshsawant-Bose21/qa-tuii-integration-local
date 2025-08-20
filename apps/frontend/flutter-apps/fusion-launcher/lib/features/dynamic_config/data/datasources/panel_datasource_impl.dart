import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/processing_block_entity.dart';
import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/models/zmq_meter_data/meter_data.dart';
import '../../../../core/service_locator.dart';
import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';
import '../models/audio_widget_model.dart';
import '../models/panel_model.dart';
import '../repositories/metadata_generator.dart';
import 'panel_datasource.dart';

class PanelDataSourceImpl implements PanelDataSource {
  // final FusionNetworkingInterface restNetworkingInterface = serviceLocator<FusionNetworkingInterface>(instanceName: 'rest');
  // final FusionNetworkingInterface zeroMQNetworkingInterface = serviceLocator<FusionNetworkingInterface>(instanceName: 'zeromq');

  final FusionNetworkClient fusionNetworkClient = serviceLocator<FusionNetworkClient>();

  @override
  Future<PanelEntity> fetchPanelData(PanelEntity panelEntity) async {
    try {
      final ResponseCallback<dynamic> response = await fusionNetworkClient.get(
        api: FusionApiEndpoint.fusionGetValue,
      );

      if (response.success) {
        final PanelModel panelModel = PanelModel.fromDomain(panelEntity);
        late Map<String, dynamic> responseDict;
        try {
          responseDict = response.data as Map<String, dynamic>;
        } catch (e) {
          debugPrint("Error parsing response data: $e");
        }

        final List<AudioWidgetEntity> updatedList =
            panelModel.listOfAudioWidgets
                .map(
                  (AudioWidgetEntity audioWidget) =>
                      _getUpdatedWidgetModelFromJSON(
                        responseDict,
                        audioWidget,
                      ) ??
                      audioWidget,
                )
                .toList();

        return panelModel.copyWith(listOfAudioWidgets: updatedList).toDomain();
      } else {
        return panelEntity;
      }
    } catch (e, stackTrace) {
      FusionLogger.log(
        tag: LogTag.panel,
        message: "Error in _getPanelDataFromServer: $e\n$stackTrace",
        logLevel: LogLevel.error,
      );
    }
    return panelEntity;
  }

  //fetch current value for given block
  @override
  Future<dynamic> getCurrentValueForBlock(
    String blockId,
    String blockName,
  ) async {
    final ResponseCallback<dynamic> response = await fusionNetworkClient.get(
      api: FusionApiEndpoint.fusionGetValue,
    );

    if (response.success) {
      final Map<String, dynamic> responseDict = response.data as Map<String, dynamic>;
      final Map<String, dynamic> settings = responseDict['settings'] as Map<String, dynamic>;

      if (settings['audio'] is Map<String, dynamic>) {
        final Map<String, dynamic> audio = settings['audio'] as Map<String, dynamic>;

        if (audio.containsKey(blockId)) {
          final Map<String, dynamic> blockData = audio[blockId] as Map<String, dynamic>;
          if (blockData.containsKey(blockName)) {
            if (blockData[blockName] is List) {
              // If the block data is a list, return the first element
              return blockData[blockName][0];
            } else if (blockData[blockName] is Map) {
              // If the block data is a map, return the map
              return blockData[blockName];
            } else {
              // Otherwise, return the value directly
              return blockData[blockName];
            }
          }
        }
      }
    }
    return null;
  }

  AudioWidgetEntity? _getUpdatedWidgetModelFromJSON(Map<String, dynamic> widgetUpdateJSON, AudioWidgetEntity oldModel) {
    Map<String, dynamic> settings = <String, dynamic>{};
    Map<String, dynamic> audio = <String, dynamic>{};

    if (widgetUpdateJSON['settings'] is Map<String, dynamic>) {
      settings = widgetUpdateJSON['settings'] as Map<String, dynamic>;

      if (settings['audio'] is Map<String, dynamic>) {
        audio = settings['audio'] as Map<String, dynamic>;

        for (final MapEntry<String, dynamic> entry in audio.entries) {
          final String blockId = entry.key;
          final Map<String, dynamic> values = entry.value as Map<String, dynamic>;

          for (final MapEntry<String, dynamic> parameterEntry in values.entries) {
            final String parameterName = parameterEntry.key;
            final dynamic updatedValue = parameterEntry.value;
            //FIXME: 2 loops?

            if ((oldModel.isWidgetDependentOnDimensions && oldModel.id == blockId && oldModel.name == parameterName)) {
              if (updatedValue is List && updatedValue.length > (oldModel.dimensionIndex!)) {
                return oldModel.copyWith(
                  value: AudioWidgetValue.from(updatedValue[oldModel.dimensionIndex!], oldModel.value.valueType),
                );
              } else {
                FusionLogger.log(
                  tag: LogTag.panel,
                  message: "widget id ${oldModel.id} doesn't exist in the response $updatedValue, $entry, $parameterEntry ",
                  logLevel: LogLevel.warning,
                );
              }
            } else if ((!oldModel.isWidgetDependentOnDimensions && oldModel.id == blockId && oldModel.name == parameterName)) {
              return oldModel.copyWith(value: AudioWidgetValue.from(updatedValue, oldModel.value.valueType));
            }
          }
        }
      } else if (settings['fw'] is Map<String, dynamic>) {
        //TODO: remove this as it is debug code for proto1 (phantom_power)

        audio = settings['fw'] as Map<String, dynamic>;

        for (final MapEntry<String, dynamic> entry in audio.entries) {
          final String blockName = entry.key;
          final Map<String, dynamic> values = entry.value as Map<String, dynamic>;

          for (final MapEntry<String, dynamic> parameterEntry in values.entries) {
            final String parameterName = parameterEntry.key;
            final dynamic updatedValue = parameterEntry.value;
            //FIXME: 2 loops?

            if ((oldModel.isWidgetDependentOnDimensions && oldModel.id == blockName && oldModel.name == parameterName)) {
              if (updatedValue is List && updatedValue.length > (oldModel.dimensionIndex! - 1)) {
                return oldModel.copyWith(value: updatedValue[oldModel.dimensionIndex!]);
              } else {
                debugPrint("Failed to fetch panel data - could not find the expected meter info at the specified index");
              }
            } else if ((!oldModel.isWidgetDependentOnDimensions && oldModel.id == blockName && oldModel.name == parameterName)) {
              return oldModel.copyWith(value: updatedValue);
            }
          }
        }
      } else {
        FusionLogger.log(
          tag: LogTag.panel,
          message: "Warning: 'audio' key is missing or not a valid Map<String, dynamic> ",
          logLevel: LogLevel.warning,
        );
        return oldModel;
      }
    } else {
      FusionLogger.log(
        tag: LogTag.panel,
        message: "Warning: 'settings' key is missing or not a valid Map<String, dynamic>",
        logLevel: LogLevel.warning,
      );
      return oldModel;
    }
    return null;
  }

  @override
  Future<AudioWidgetEntity> sendWidgetData(AudioWidgetEntity audioWidgetEntity, AudioWidgetValue updatedValue) async {
    Map<String, String> urlParams;
    final AudioWidgetModel audioWidget = AudioWidgetModel.fromDomain(audioWidgetEntity);

    final dynamic newValue = updatedValue.value;

    if (audioWidget.isWidgetDependentOnDimensions) {
      urlParams = <String, String>{
        "key": "settings.audio.${audioWidget.id}.${audioWidget.name}[${audioWidget.dimensionIndex}]",
      };
    } else {
      urlParams = <String, String>{};
    }

    final Map<String, dynamic> messageToSend = _getUpdateRequestJSONForWidget(audioWidget, newValue);

    final ResponseCallback<dynamic> responseCallback = await fusionNetworkClient.patch(
      api: FusionApiEndpoint.fusionUpdateValue,
      data: messageToSend,
      urlParameters: urlParams,
    );

    if (responseCallback.success) {
      final String? response = responseCallback.data;
      Map<String, dynamic> responseDict = <String, dynamic>{};

      if (response != null) {
        try {
          responseDict = jsonDecode(response);
        } catch (e) {
          debugPrint("Error parsing response data: $e");
        }
      }

      print("Response from server: $responseDict");

      if (responseDict['status'] == 'success') {
        print("Widget data updated successfully: ${audioWidget.name}  ${audioWidget.value.toString()}");
        return audioWidget.copyWith(value: updatedValue.value).toDomain();

        /// FIXME: Currently updateValue API return complete information and not just the updated part and hence things
        /// were failing. commented out check and update after response.
        // final AudioWidgetModel? updatedWidget = _getUpdatedWidgetModelFromJSON(
        //     responseDict["updates"], audioWidget);
        // if (updatedWidget != null) {
        //   return updatedWidget;
        // } else {
        //   throw FError(
        //     errorCode: ErrorCode.UI_WIDGET_NOT_FOUND_IN_STATE,
        //     customError:
        //         'Widget id not found converting ${responseDict} widget ${audioWidget.id}',
        //   );
        // }
      } else {
        FusionLogger.log(
          tag: LogTag.panel,
          message: "Error in sendWidgetData: ${responseDict['error']}",
          logLevel: LogLevel.error,
        );
      }
    }

    return audioWidgetEntity;
  }

  Map<String, dynamic> _getUpdateRequestJSONForWidget(AudioWidgetModel widgetModel, dynamic newValue) {
    if (widgetModel.isWidgetDependentOnDimensions) {
      return <String, dynamic>{"value": newValue};
    } else if (widgetModel.isWidgetPhantomPower) {
      //TODO: remove this as it is debug code for proto1 (phantom_power)
      return <String, dynamic>{
        "settings": <String, dynamic>{
          "fw": <String, dynamic>{
            widgetModel.id: <String, dynamic>{widgetModel.name: newValue},
          },
        },
      };
    } else {
      return <String, dynamic>{
        "settings": <String, dynamic>{
          "audio": <String, dynamic>{
            widgetModel.id: <String, dynamic>{
              widgetModel.name: newValue, // Use newValue directly
            },
          },
        },
      };
    }
  }

  @override
  Future<bool> resetFusion() async {
    //final String? response = await restNetworkingInterface.send("", APIType.DELETE, EndPoint.FUSION_DELETE, "");
    final ResponseCallback<dynamic> responseCallback = await fusionNetworkClient.delete(
      api: FusionApiEndpoint.fusionDelete,
    );

    if (responseCallback.success) {
      final Map<String, dynamic> responseDict = responseCallback.data;

      if (responseDict['status'] == 'success') {
        return true;
      } else {
        FusionLogger.log(
          tag: LogTag.panel,
          message: "Error in resetFusion: ${responseDict['error']}",
          logLevel: LogLevel.error,
        );
      }
    } else {
      FusionLogger.log(
        tag: LogTag.panel,
        message: "Error in resetFusion: ${responseCallback.message}",
        logLevel: LogLevel.error,
      );
    }
    return false;
  }

  @override
  Stream<Map<String, dynamic>> getMeterStream() async* {
    // print("getMeterStream called");
    await for (ResponseCallback<dynamic> response in fusionNetworkClient.responseMessages) {
      try {
        // print("getMeterStream response received: ${response.success} ${response.data} ${response.message}");
        if (response.success) {
          final MeterDataModel meterData = MeterDataModel.fromJson(response.data as Map<String, dynamic>);

          if (meterData.messageName == MessageName.meterData) {
            final List<ValueItem> listOfMessages = meterData.parameters.value;
            for (ValueItem meterMessage in listOfMessages) {
              //FIXME: There are two ways of checking if meter has dimensions or not. Need to check which one is correct.
              //// if (meterMessage.dimensions != "[0]") {
              ///   if (meterMessage.value is List) {

              if (meterMessage.value is List) {
                // Property is a dimensional value
                for (int i = 0; i < meterMessage.value.length; i++) {
                  if (meterMessage.valueType == 'float') {
                    meterMessage.value[i] = double.parse(meterMessage.value[i]);
                  } else if (meterMessage.valueType == 'int') {
                    meterMessage.value[i] = int.parse(meterMessage.value[i]);
                  } else if (meterMessage.valueType == 'bool') {
                    meterMessage.value[i] = meterMessage.value[i].toString() == 'true';
                  } else {
                    meterMessage.value[i] = meterMessage.value[i];
                  }
                  final dynamic value = meterMessage.value[i];
                  final String key = '${meterMessage.blockName}#${meterMessage.meterName}';
                  yield <String, dynamic>{key: value};
                }
              } else {
                // Property is a dimensionless value
                final String key = '${meterMessage.blockName}#${meterMessage.meterName}';

                if (meterMessage.valueType == 'float') {
                  yield <String, dynamic>{key: double.parse(meterMessage.value)};
                } else if (meterMessage.valueType == 'int') {
                  yield <String, dynamic>{key: int.parse(meterMessage.value)};
                } else if (meterMessage.valueType == 'bool') {
                  yield <String, dynamic>{key: meterMessage.value.toString() == 'true'};
                } else {
                  yield <String, dynamic>{key: double.parse(meterMessage.value)};
                }
              }
            }
          }
        } else {
          FusionLogger.log(tag: LogTag.panel, message: response.message, logLevel: LogLevel.error);
        }
      } catch (ex) {
        FusionLogger.log(
          tag: LogTag.panel,
          message: "Error while parsing the zmq response $ex",
          logLevel: LogLevel.error,
        );
      }
    }
  }

  @override
  Future<PanelEntity> getPanelEntity(ProcessingBlockEntity processingBloc) async {
    return buildPanelModelsForDesign(processingBloc: processingBloc);
  }

  @override
  Future<void> connectMeteringStream() {
    return fusionNetworkClient.connect();
  }

  @override
  void disconnectMeteringStream() {
    fusionNetworkClient.disconnect();
  }
}
