import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/models/processing_block_entity.dart';
import 'package:fusion_design_tool_prototype/core/service_locator.dart';

import '../../../../core/models/algorithm/algorithm_metadata.dart';
import '../../../../core/models/algorithm/property_settings.dart';
import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';

PanelEntity buildPanelModelsForDesign({
  required ProcessingBlockEntity processingBloc,
}) {

  late final List<Algorithm> algoTypesListSchema = serviceLocator<FusionAlgorithmsConfig>().algorithms;

// converting list into a map so that its easier to extract.
  final Map<String, Algorithm> schemaAlgorithmsMap = <String, Algorithm>{for (final Algorithm algo in algoTypesListSchema) algo.name: algo};

  //get panels definitions from input, block is represented with a panel.


    final String algorithmType = processingBloc.algorithmId;
    // final String blockId = block.id;

    final Algorithm? algoDefinition = schemaAlgorithmsMap[algorithmType];
    if (algoDefinition == null) {
      throw Exception(
        "Algorithm '$algorithmType' not found in the schema for block '${processingBloc.name}'.",
      );
    }

    debugPrint("Building panel for block: ${processingBloc.name} with algorithm type: $algorithmType algorithm definition: $algoDefinition");

    final List<AudioWidgetEntity> audioWidgets = <AudioWidgetEntity>[];

    final List<Parameter> parameters = algoDefinition.parameters ?? <Parameter>[];

    //PARAMETERS
    for (final Parameter paramDefinition in parameters) {
      AudioWidgetType widgetType = AudioWidgetType.unknown;
      if (paramDefinition.valueType == "bool") {
        widgetType = AudioWidgetType.toggleButton;
      } else if (paramDefinition.valueType == "float") {
        widgetType = AudioWidgetType.gainFader;
      } else if (paramDefinition.valueType == "integer") {
        widgetType = AudioWidgetType.gainFader;
      } else if (paramDefinition.valueType == "string") {
        widgetType = AudioWidgetType.unknown;
      }

      final List<dynamic>? dimensionsDefinition = paramDefinition.dimensions;

      if (dimensionsDefinition == null) {
        //parameter is scalar

        audioWidgets.add(
          AudioWidgetEntity(
            id: processingBloc.id, // blockName_parameterName
            name: paramDefinition.name,
            parentPanelBlockName: processingBloc.name,
            audioWidgetType: widgetType,
            audioWidgetOrientation: AudioWidgetOrientation.vertical,
            isWidgetDependentOnDimensions: false,
            value: AudioWidgetValue.from(paramDefinition.defaultValue, paramDefinition.valueType),
            minValue: AudioWidgetValue.from(paramDefinition.minimumValue, paramDefinition.valueType),
            maxValue: AudioWidgetValue.from(paramDefinition.maximumValue, paramDefinition.valueType),
          ),
        );
      } else {
        //parameter is vector
        for (final dynamic dimensionName in dimensionsDefinition) {
          final List<PropertySetting> foundPropertiesInBlock = processingBloc.properties
              .where(
                (PropertySetting propertyName) => propertyName.name == dimensionName,
              )
              .toList();
          final PropertySetting? foundPropertyInBlock = foundPropertiesInBlock.isNotEmpty ? foundPropertiesInBlock.first : null;
          if (foundPropertyInBlock != null) {
            final int foundPropertyValue = foundPropertyInBlock.value;

            for (int i = 1; i <= foundPropertyValue; i++) {
              audioWidgets.add(
                AudioWidgetEntity(
                  id: processingBloc.id, // blockName_parameterName_dimensionIndex
                  name: paramDefinition.name,
                  parentPanelBlockName: processingBloc.name,
                  audioWidgetType: widgetType,
                  audioWidgetOrientation: AudioWidgetOrientation.vertical,
                  value: AudioWidgetValue.from(paramDefinition.defaultValue, paramDefinition.valueType),
                  minValue: AudioWidgetValue.from(paramDefinition.minimumValue, paramDefinition.valueType),
                  maxValue: AudioWidgetValue.from(paramDefinition.maximumValue, paramDefinition.valueType),
                  isWidgetDependentOnDimensions: true,
                  dimensionIndex: i - 1,
                ),
              );
            }
          }
        }
      }
    }

    //METERS
    final List<Telemetry> telemetryDefinitions = algoDefinition.telemetry ?? <Telemetry>[];

    for (final Telemetry telemetryDefinition in telemetryDefinitions) {
      AudioWidgetType widgetType = AudioWidgetType.unknown;
      if (telemetryDefinition.valueType == "bool") {
        widgetType = AudioWidgetType.toggleButton;
      } else if (telemetryDefinition.valueType == "float") {
        widgetType = AudioWidgetType.meter;
      } else if (telemetryDefinition.valueType == "integer") {
        widgetType = AudioWidgetType.meter;
      } else if (telemetryDefinition.valueType == "string") {
        widgetType = AudioWidgetType.unknown;
      }

      final List<dynamic>? dimensionsDefinition = telemetryDefinition.dimensions;

      if (dimensionsDefinition == null) {
        //meter is scalar
        audioWidgets.add(
          AudioWidgetEntity(
            id: processingBloc.id, // blockName_parameterName
            name: telemetryDefinition.name,
            parentPanelBlockName: processingBloc.name,
            audioWidgetType: widgetType,
            audioWidgetOrientation: AudioWidgetOrientation.vertical,
            isWidgetDependentOnDimensions: false,
            value: AudioWidgetValue.from(telemetryDefinition.defaultValue, telemetryDefinition.valueType),
            minValue: AudioWidgetValue.from(telemetryDefinition.minimumValue, telemetryDefinition.valueType),
            maxValue: AudioWidgetValue.from(telemetryDefinition.maximumValue, telemetryDefinition.valueType),
          ),
        );
      } else {
        //meter is vector
        for (final String dimensionName in dimensionsDefinition) {
          final List<PropertySetting> foundPropertiesInBlock = processingBloc.properties
              .where(
                (PropertySetting propertyName) => propertyName.name == dimensionName,
              )
              .toList();
          final PropertySetting? foundPropertyInBlock = foundPropertiesInBlock.isNotEmpty ? foundPropertiesInBlock.first : null;
          if (foundPropertyInBlock != null) {
            final int foundPropertyValue = foundPropertyInBlock.value;

            for (int i = 1; i <= foundPropertyValue; i++) {
              audioWidgets.add(
                AudioWidgetEntity(
                  id: processingBloc.id, // blockName_parameterName_dimensionIndex
                  name: telemetryDefinition.name,
                  parentPanelBlockName: processingBloc.name,
                  audioWidgetType: widgetType,
                  audioWidgetOrientation: AudioWidgetOrientation.vertical,
                  isWidgetDependentOnDimensions: true,
                  dimensionIndex: i - 1,
                  value: AudioWidgetValue.from(telemetryDefinition.defaultValue, telemetryDefinition.valueType),
                  minValue: AudioWidgetValue.from(telemetryDefinition.minimumValue, telemetryDefinition.valueType),
                  maxValue: AudioWidgetValue.from(telemetryDefinition.maximumValue, telemetryDefinition.valueType),
                ),
              );
            }
          }
        }
      }
    }
  final PanelEntity panel = PanelEntity(
    id: processingBloc.id,
    name: processingBloc.name,
    algorithmType: algorithmType,
    listOfAudioWidgets: audioWidgets,
  );

    return panel;

}
