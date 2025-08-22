import 'dart:math';

import 'package:fusion_launcher/core/models/floor_entity.dart';
import 'package:fusion_launcher/core/models/fusion_device.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/project_manager.dart';
import 'package:fusion_lib/models/fusion_models.dart';

class JsonFormatConverter {
  static Map<String, dynamic> getAudioStreamsData(
    Map<String, dynamic> droOutput,
  ) {
    final List<Map<String, dynamic>> audioStreams = <Map<String, dynamic>>[];

    // Get the result section from DRO output
    final Map<String, dynamic>? result = droOutput['result'] as Map<String, dynamic>?;
    if (result == null) {
      return <String, dynamic>{"audio_streams": audioStreams};
    }

    // Process AES67 streams
    final List<dynamic> aes67Streams = result['aes67_streams'] as List<dynamic>? ?? <dynamic>[];
    for (final Map<String, dynamic> stream in aes67Streams) {
      final Map<String, dynamic> streamMap = stream;
      final String? direction = streamMap['direction'] as String?;

      if (direction == 'RX') {
        // AES67 Sink
        audioStreams.add(<String, dynamic>{
          "dest_device_uid": streamMap['destination_device'] ?? "",
          "properties": <String, dynamic>{
            "stream_name": streamMap['stream_id'] ?? "",
            "dest_ip": streamMap['multicast_destination_ip'] ?? "",
            "channels": streamMap['channels'] ?? 1,
            "is_source": false,
            "is_fusion_connect": false,
          },
        });
      } else if (direction == 'TX') {
        // AES67 Source
        audioStreams.add(<String, dynamic>{
          "source_device_uid": streamMap['source_device'] ?? "",
          "properties": <String, dynamic>{
            "stream_name": streamMap['stream_id'] ?? "",
            "dest_ip": streamMap['multicast_destination_ip'] ?? "",
            "channels": streamMap['channels'] ?? 1,
            "source_port": 49152, // Default port as mentioned
            "is_source": true,
            "is_fusion_connect": false,
          },
        });
      }
    }

    // Process Device Connections (Fusion Connect)
    final List<dynamic> deviceConnections = result['device_connections'] as List<dynamic>? ?? <dynamic>[];
    for (final Map<String, dynamic> connection in deviceConnections) {
      final Map<String, dynamic> connectionMap = connection;

      audioStreams.add(<String, dynamic>{
        "source_device_uid": connectionMap['source_device'] ?? "",
        "dest_device_uid": connectionMap['destination_device'] ?? "",
        "properties": <String, dynamic>{
          "channels": connectionMap['channels'] ?? 1,
          "source_port":
              int.tryParse(
                connectionMap['source_port']?.toString() ?? '49152',
              ) ??
              49152,
          "is_fusion_connect": true,
        },
      });
    }

    return <String, dynamic>{"audio_streams": audioStreams};
  }

  /// Converts the input JSON format to the expected output format
  static Map<String, dynamic> convertFormat(Map<String, dynamic> inputJson, List<FusionDevice> fusionDevices) {
    // Create the base structure with only property_settings and user_setting as defaults
    final Map<String, dynamic> outputJson = <String, dynamic>{
      "request_id": _generateRequestId(),
      "version": "v0.0.1",
      "property_settings": <Map<String, dynamic>>[
        <String, dynamic>{"name": "sample_rate", "value": 48000},
        <String, dynamic>{"name": "frame_size", "value": 256},
      ],
      "input_streams": <Map<String, dynamic>>[],
      "inputs": <Map<String, dynamic>>[],
      "mixes": <Map<String, dynamic>>[],
      "zones": <Map<String, dynamic>>[],
      "output_streams": <Map<String, dynamic>>[],
      "user_setting": <String, dynamic>{
        "max_devices": <dynamic>[],
        "device_capacity": 90,
        "max_solve_time": 60,
        "max_device_hop_count": 10,
        "max_network_latency": 50,
        "cost_option": 1,
      },
    };

    // Convert hardware components to inputs and streams
    final List<Map<String, dynamic>> inputStreams = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> inputs = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> outputStreams = <Map<String, dynamic>>[];

    if (inputJson['hardwareComponents'] != null) {
      final List<dynamic> hardwareComponents = inputJson['hardwareComponents'] as List<dynamic>;
      for (int i = 0; i < hardwareComponents.length; i++) {
        final Map<String, dynamic> component = hardwareComponents[i];
        final Map<String, dynamic> comp = component;
        if (comp['componentType'] == 'source') {
          // Create input from source component
          final Map<String, dynamic> input = <String, dynamic>{
            "id": comp['id']?.toString() ?? _generateId(),
            "name": comp['name']?.toString() ?? "Unknown Input",
            "server_location": _extractServerLocation(comp),
            "to_mono": comp['type'] == 'bluetooth',
            "io_type": _mapComponentTypeToIoType(comp['type']?.toString()),
            "io_properties": <String, dynamic>{
              "channels": comp['type'] == 'bluetooth' ? 2 : 1,
            },
            "processing_blocks": _convertProcessingBlocks(
              comp['blocks'] ?? <dynamic>[],
            ),
          };
          inputs.add(input);

          // Create input stream for AES67 inputs only
          if (comp['type'] == 'aes67input') {
            final Map<String, dynamic> inputStream = <String, dynamic>{
              "id": "FUSION_${comp['id']}",
              "name": "${comp['name']}",
              "total_channels": 1,
              "server_location": _extractServerLocation(comp),
              "multicast_destination_ip": comp['ipAddress']?.toString() ?? "",
              "stream_channel_mapping": <Map<String, dynamic>>[
                <String, dynamic>{"io_id": comp['id']?.toString(), "io_ch": 1},
              ],
            };
            inputStreams.add(inputStream);
          }
        } else if (comp['componentType'] == 'speaker' && comp['type'] == 'aes67output' && _isHardwareComponentInsideAnyZone(component)) {
          // Create output stream for AES67 outputs
          final String componentName = comp['name']?.toString() ?? comp['id']?.toString() ?? 'unknown';
          final Map<String, dynamic> outputStream = <String, dynamic>{
            "id": "FUSION_${comp['id']}",
            "name": "${comp['name']}",
            "total_channels": 1,
            "server_location": _extractServerLocation(comp),
            "multicast_destination_ip": comp['ipAddress']?.toString() ?? "",
            "stream_channel_mapping": <Map<String, dynamic>>[
              <String, dynamic>{
                "io_id": comp['id']?.toString() ?? _generateId(),
                "io_ch": 1,
              },
            ],
          };
          outputStreams.add(outputStream);
        }
      }
    }

    // Convert mixes
    final List<Map<String, dynamic>> convertedMixes = <Map<String, dynamic>>[];
    if (inputJson['mixes'] != null) {
      final List<dynamic> mixes = inputJson['mixes'] as List<dynamic>;
      for (int i = 0; i < mixes.length; i++) {
        final Map<String, dynamic> mix = mixes[i];
        final Map<String, dynamic> mixMap = mix;
        if (mixMap['sourceIds'] != null && (mixMap['sourceIds'] as List<dynamic>).isNotEmpty) {
          final Map<String, dynamic> convertedMix = <String, dynamic>{
            "id": mixMap['id']?.toString() ?? _generateId(),
            "name": mixMap['name']?.toString() ?? "Unknown Mix",
            "channels": 1,
            "sources": _convertMixSources(
              mixMap['sourceIds'] as List<dynamic>,
              mixMap['sourceMixLevels'] as Map<String, dynamic>?,
            ),
            "processing_blocks": _convertProcessingBlocks(
              mixMap['processingBlocks'] ?? <dynamic>[],
            ),
          };
          convertedMixes.add(convertedMix);
        }
      }
    }

    // Convert zones
    final List<Map<String, dynamic>> convertedZones = <Map<String, dynamic>>[];
    if (inputJson['zones'] != null) {
      final List<dynamic> zones = inputJson['zones'] as List<dynamic>;
      for (int j = 0; j < zones.length; j++) {
        final Map<String, dynamic> zone = zones[j];
        final Map<String, dynamic> zoneMap = zone;

        // Get mix IDs for this zone
        final List<String> mixIds = <String>[];
        if (zoneMap['mixes'] != null) {
          final List<dynamic> zoneMixes = zoneMap['mixes'] as List<dynamic>;
          for (int i = 0; i < zoneMixes.length; i++) {
            final String mixId = zoneMixes[i];
            final String mixIdStr = mixId.toString();
            // Find the actual mix by ID
            final bool mixExists = convertedMixes.any(
              (Map<String, dynamic> mix) => mix['id'] == mixIdStr,
            );
            if (mixExists) {
              mixIds.add(mixIdStr);
            }
          }
        }

        final Map<String, dynamic> convertedZone = <String, dynamic>{
          "id": zoneMap['id']?.toString() ?? _generateId(),
          "name": zoneMap['name']?.toString() ?? "Unknown Zone",
          "channels": 1,
          "source_ids": mixIds,
          "processing_blocks": _convertProcessingBlocks(
            zoneMap['processingBlocks'] ?? <dynamic>[],
          ),
          "xover_splits": <Map<String, dynamic>>[
            <String, dynamic>{
              "id": _generateId(),
              "split_type": "full range",
              "split_count": 1,
              "outputs": _createZoneOutputs(
                zoneMap['id']?.toString(),
                inputJson['hardwareComponents'] as List<dynamic>?,
              ),
            },
          ],
        };
        convertedZones.add(convertedZone);
      }
    }

    Map<String, dynamic> userSetting = inputJson['userSetting'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final List<dynamic> maxDevices = <dynamic>[];

    for (FusionDevice device in fusionDevices) {
      final String deviceId = device.id;
      // Add device to max_devices
      maxDevices.add(<String, dynamic>{
        "device_id": deviceId,
        "device_type": "fusion_mini",
        "device_location": device.location,
      });
    }
    // Assign max_devices and other user settings
    userSetting = <String, dynamic>{
      "max_devices": maxDevices,
      "device_capacity": userSetting['deviceCapacity'] ?? 90,
      "max_solve_time": userSetting['maxSolveTime'] ?? 60,
      "max_device_hop_count": userSetting['maxDeviceHopCount'] ?? 10,
      "max_network_latency": userSetting['maxNetworkLatency'] ?? 50,
      "cost_option": userSetting['costOption'] ?? 1,
    };

    // Assign converted data
    outputJson['input_streams'] = inputStreams;
    outputJson['inputs'] = inputs;
    outputJson['mixes'] = convertedMixes;
    outputJson['zones'] = convertedZones;
    outputJson['output_streams'] = outputStreams;
    outputJson['user_setting'] = userSetting;

    return outputJson;
  }

  static String _generateRequestId() {
    return "${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}";
  }

  static String _generateId() {
    return "id-${Random().nextInt(100000)}";
  }

  static bool _isHardwareComponentInsideAnyZone(
    Map<String, dynamic> component,
  ) {
    if (component['locationEntity'] == null) return false;

    final Map<String, dynamic> locationEntity = component['locationEntity'] as Map<String, dynamic>;
    final String? zoneId = locationEntity['zoneId']?.toString();

    if (zoneId == null || zoneId.isEmpty) return false;

    return true;
  }

  static String _extractServerLocation(Map<String, dynamic> component) {
    if (component['locationEntity'] != null) {
      final Map<String, dynamic> location = component['locationEntity'] as Map<String, dynamic>;
      String? floorName;
      if (location['floorId'] != null && location['floorId'].toString().isNotEmpty) {
        final String floorId = location['floorId'].toString();

        final ProjectManager projectManager = serviceLocator<ProjectManager>();
        //fetch Floor name from project manager
        floorName = projectManager.value.floors.firstWhere((Floor floor) => floor.id == floorId).name;

        if (location['listeningAreaId'] != null && location['listeningAreaId'].toString().isNotEmpty) {
          final String areaId = location['listeningAreaId'].toString();
          final ProjectManager projectManager = serviceLocator<ProjectManager>();
          //fetch Area name from project manager floors by looping floor and mathing area id
          final ListeningArea area = projectManager.value.floors
              .firstWhere((Floor floor) => floor.id == floorId)
              .listeningAreas
              .firstWhere(
                (ListeningArea area) => area.id == areaId,
              );

          return "$floorName/${area.name}";
        }
      }
    }
    return "";
  }

  static String _mapComponentTypeToIoType(String? type) {
    if (type == null) return 'analog';

    switch (type) {
      case 'aes67input':
      case 'aes67output':
        return 'aes67';
      case 'bluetooth':
        return 'bluetooth';
      case 'analogInput':
      case 'analogOutput':
        return 'analog';
      default:
        return 'analog';
    }
  }

  static List<Map<String, dynamic>> _convertProcessingBlocks(
    List<dynamic> blocks,
  ) {
    final List<Map<String, dynamic>> processedBlocks = <Map<String, dynamic>>[];

    for (int i = 0; i < blocks.length; i++) {
      final Map<String, dynamic> block = blocks[i];
      final Map<String, dynamic> blockMap = block;
      final Map<String, dynamic> processedBlock = <String, dynamic>{
        "id": blockMap['id']?.toString() ?? _generateId(),
        "algorithm": blockMap['algorithmId']?.toString() ?? blockMap['algorithm']?.toString() ?? '',
        "algorithm_properties": <dynamic, dynamic>{},
        // "algorithm_properties": blockMap['properties'] as List<dynamic>,
      };
      processedBlocks.add(processedBlock);
    }

    return processedBlocks;
  }

  static List<Map<String, dynamic>> _convertMixSources(
    List<dynamic> sourceIds,
    Map<String, dynamic>? sourceMixLevels,
  ) {
    final List<Map<String, dynamic>> sources = <Map<String, dynamic>>[];

    for (int i = 0; i < sourceIds.length; i++) {
      final String sourceId = sourceIds[i];
      final String sourceIdStr = sourceId.toString();
      final Map<String, dynamic> source = <String, dynamic>{
        "source_id": sourceIdStr,
        "source_terminal": "out",
        "source_channel": 1,
      };

      sources.add(source);
    }

    return sources;
  }

  static List<Map<String, dynamic>> _createZoneOutputs(
    String? zoneId,
    List<dynamic>? hardwareComponents,
  ) {
    final List<Map<String, dynamic>> outputs = <Map<String, dynamic>>[];

    if (hardwareComponents == null || zoneId == null) {
      return outputs;
    }

    // Find all speaker components assigned to this zone
    final List<Map<String, dynamic>> zoneComponents = <Map<String, dynamic>>[];
    for (int i = 0; i < hardwareComponents.length; i++) {
      final Map<String, dynamic> comp = hardwareComponents[i];
      final Map<String, dynamic> component = comp;
      if (component['componentType'] == 'speaker' && component['locationEntity'] != null) {
        final Map<String, dynamic> locationEntity = component['locationEntity'] as Map<String, dynamic>;
        if (locationEntity['zoneId']?.toString() == zoneId) {
          zoneComponents.add(component);
        }
      }
    }

    for (Map<String, dynamic> component in zoneComponents) {
      final Map<String, dynamic> output = <String, dynamic>{
        "id": component['id']?.toString() ?? _generateId(),
        "name": component['name']?.toString() ?? "Unknown Output",
        "server_location": _extractServerLocation(component),
        "io_type": _mapComponentTypeToIoType(component['type']?.toString()),
        "io_properties": <String, dynamic>{"channels": 1},
        "processing_blocks": _convertProcessingBlocks(
          component['blocks'] ?? <dynamic>[],
        ),
      };

      outputs.add(output);
    }

    return outputs;
  }
}
