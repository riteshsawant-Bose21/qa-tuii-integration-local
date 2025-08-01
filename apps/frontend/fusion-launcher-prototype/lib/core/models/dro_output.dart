// import 'dart:convert';
//
// // Define the top-level model class
// class DROResponse {
//   final String requestId;
//   final String responseId;
//   final DROResult result;
//
//   DROResponse({
//     required this.requestId,
//     required this.responseId,
//     required this.result,
//   });
//
//   factory DROResponse.fromJson(Map<String, dynamic> json) {
//     return DROResponse(
//       requestId: json['request_id'] as String,
//       responseId: json['response_id'] as String,
//       result: DROResult.fromJson(json['result'] as Map<String, dynamic>),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'request_id': requestId,
//       'response_id': responseId,
//       'result': result.toJson(),
//     };
//   }
// }
//
// // Define the Result class
// class DROResult {
//   final List<Aes67Stream> aes67Streams;
//   final List<DeviceConnection> deviceConnections;
//   final List<Device> devices;
//
//   DROResult({
//     required this.aes67Streams,
//     required this.deviceConnections,
//     required this.devices,
//   });
//
//   factory DROResult.fromJson(Map<String, dynamic> json) {
//     return DROResult(
//       aes67Streams: (json['aes67_streams'] as List<dynamic>)
//           .map((e) => Aes67Stream.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       deviceConnections: (json['device_connections'] as List<dynamic>)
//           .map((e) => DeviceConnection.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       devices: (json['devices'] as List<dynamic>)
//           .map((e) => Device.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'aes67_streams': aes67Streams.map((Aes67Stream e) => e.toJson()).toList(),
//       'device_connections': deviceConnections.map((DeviceConnection e) => e.toJson()).toList(),
//       'devices': devices.map((Device e) => e.toJson()).toList(),
//     };
//   }
// }
//
// // Define the Aes67Stream class
// class Aes67Stream {
//   final int channels;
//   final String description;
//   final String destinationDevice;
//   final String direction;
//   final String multicastDestinationIp;
//   final String sourceDevice;
//   final String streamId;
//   final String streamName;
//
//   Aes67Stream({
//     required this.channels,
//     required this.description,
//     required this.destinationDevice,
//     required this.direction,
//     required this.multicastDestinationIp,
//     required this.sourceDevice,
//     required this.streamId,
//     required this.streamName,
//   });
//
//   factory Aes67Stream.fromJson(Map<String, dynamic> json) {
//     return Aes67Stream(
//       channels: json['channels'] as int,
//       description: json['description'] as String,
//       destinationDevice: json['destination_device'] as String,
//       direction: json['direction'] as String,
//       multicastDestinationIp: json['multicast_destination_ip'] as String,
//       sourceDevice: json['source_device'] as String,
//       streamId: json['stream_id'] as String,
//       streamName: json['stream_name'] as String,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'channels': channels,
//       'description': description,
//       'destination_device': destinationDevice,
//       'direction': direction,
//       'multicast_destination_ip': multicastDestinationIp,
//       'source_device': sourceDevice,
//       'stream_id': streamId,
//       'stream_name': streamName,
//     };
//   }
// }
//
// // Define the DeviceConnection class
// class DeviceConnection {
//   final int channels;
//   final String destinationDevice;
//   final String sourceDevice;
//   final String sourcePort;
//
//   DeviceConnection({
//     required this.channels,
//     required this.destinationDevice,
//     required this.sourceDevice,
//     required this.sourcePort,
//   });
//
//   factory DeviceConnection.fromJson(Map<String, dynamic> json) {
//     return DeviceConnection(
//       channels: json['channels'] as int,
//       destinationDevice: json['destination_device'] as String,
//       sourceDevice: json['source_device'] as String,
//       sourcePort: json['source_port'] as String,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'channels': channels,
//       'destination_device': destinationDevice,
//       'source_device': sourceDevice,
//       'source_port': sourcePort,
//     };
//   }
// }
//
// // Define the Device class
// class Device {
//   final List<List<String>> connectionsDeviceIn;
//   final List<List<String>> connectionsDeviceOut;
//   final List<Core> cores;
//   final int cost;
//   final String deviceType;
//   final DspStaticConfig dspStaticConfig;
//
//   Device({
//     required this.connectionsDeviceIn,
//     required this.connectionsDeviceOut,
//     required this.cores,
//     required this.cost,
//     required this.deviceType,
//     required this.dspStaticConfig,
//   });
//
//   factory Device.fromJson(Map<String, dynamic> json) {
//     return Device(
//       connectionsDeviceIn: (json['connections_device_in'] as List<dynamic>)
//           .map((e) => List<String>.from(e as List<dynamic>))
//           .toList(),
//       connectionsDeviceOut: (json['connections_device_out'] as List<dynamic>)
//           .map((e) => List<String>.from(e as List<dynamic>))
//           .toList(),
//       cores: (json['cores'] as List<dynamic>)
//           .map((e) => Core.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       cost: json['cost'] as int,
//       deviceType: json['device_type'] as String,
//       dspStaticConfig: DspStaticConfig.fromJson(
//           json['dsp_static_config'] as Map<String, dynamic>),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'connections_device_in': connectionsDeviceIn,
//       'connections_device_out': connectionsDeviceOut,
//       'cores': cores.map((Core e) => e.toJson()).toList(),
//       'cost': cost,
//       'device_type': deviceType,
//       'dsp_static_config': dspStaticConfig.toJson(),
//     };
//   }
// }
//
// // Define the Core class
// class Core {
//   final List<String> blockIds;
//   final String label;
//   final double utilAlgs;
//   final int utilDeviceConnect;
//   final double utilTaskConnect;
//   final double utilTotal;
//
//   Core({
//     required this.blockIds,
//     required this.label,
//     required this.utilAlgs,
//     required this.utilDeviceConnect,
//     required this.utilTaskConnect,
//     required this.utilTotal,
//   });
//
//   factory Core.fromJson(Map<String, dynamic> json) {
//     return Core(
//       blockIds: List<String>.from(json['block_ids'] as List<dynamic>),
//       label: json['label'] as String,
//       utilAlgs: (json['util_algs'] as num).toDouble(),
//       utilDeviceConnect: json['util_device_connect'] as int,
//       utilTaskConnect: (json['util_task_connect'] as num).toDouble(),
//       utilTotal: (json['util_total'] as num).toDouble(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'block_ids': blockIds,
//       'label': label,
//       'util_algs': utilAlgs,
//       'util_device_connect': utilDeviceConnect,
//       'util_task_connect': utilTaskConnect,
//       'util_total': utilTotal,
//     };
//   }
// }
//
// // Define the DspStaticConfig class
// class DspStaticConfig {
//   final List<AudioTask> audioTasks;
//
//   DspStaticConfig({
//     required this.audioTasks,
//   });
//
//   factory DspStaticConfig.fromJson(Map<String, dynamic> json) {
//     return DspStaticConfig(
//       audioTasks: (json['audio_tasks'] as List<dynamic>)
//           .map((e) => AudioTask.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{'audio_tasks': audioTasks.map((AudioTask e) => e.toJson()).toList()};
//   }
// }
//
// // Define the AudioTask class
// class AudioTask {
//   final List<BlockConnection> blockConnections;
//   final List<Block> blocks;
//   final String name;
//   final List<PropertySetting> propertySettings;
//
//   AudioTask({
//     required this.blockConnections,
//     required this.blocks,
//     required this.name,
//     required this.propertySettings,
//   });
//
//   factory AudioTask.fromJson(Map<String, dynamic> json) {
//     return AudioTask(
//       blockConnections: (json['block_connections'] as List<dynamic>)
//           .map((e) => BlockConnection.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       blocks: (json['blocks'] as List<dynamic>)
//           .map((e) => Block.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       name: json['name'] as String,
//       propertySettings: (json['property_settings'] as List<dynamic>)
//           .map((e) => PropertySetting.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'block_connections': blockConnections.map((BlockConnection e) => e.toJson()).toList(),
//       'blocks': blocks.map((Block e) => e.toJson()).toList(),
//       'name': name,
//       'property_settings': propertySettings.map((PropertySetting e) => e.toJson()).toList(),
//     };
//   }
// }
//
// // Define the BlockConnection class
// class BlockConnection {
//   final String destinationBlock;
//   final int inputChannel;
//   final String inputTerminal;
//   final int outputChannel;
//   final String outputTerminal;
//   final String sourceBlock;
//
//   BlockConnection({
//     required this.destinationBlock,
//     required this.inputChannel,
//     required this.inputTerminal,
//     required this.outputChannel,
//     required this.outputTerminal,
//     required this.sourceBlock,
//   });
//
//   factory BlockConnection.fromJson(Map<String, dynamic> json) {
//     return BlockConnection(
//       destinationBlock: json['destination_block'] as String,
//       inputChannel: json['input_channel'] as int,
//       inputTerminal: json['input_terminal'] as String,
//       outputChannel: json['output_channel'] as int,
//       outputTerminal: json['output_terminal'] as String,
//       sourceBlock: json['source_block'] as String,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'destination_block': destinationBlock,
//       'input_channel': inputChannel,
//       'input_terminal': inputTerminal,
//       'output_channel': outputChannel,
//       'output_terminal': outputTerminal,
//       'source_block': sourceBlock,
//     };
//   }
// }
//
// // Define the Block class
// class Block {
//   final String algorithm;
//   final String name;
//   final List<PropertySetting> propertySettings;
//   final List<TerminalChannel> terminalChannels;
//
//   Block({
//     required this.algorithm,
//     required this.name,
//     required this.propertySettings,
//     required this.terminalChannels,
//   });
//
//   factory Block.fromJson(Map<String, dynamic> json) {
//     return Block(
//       algorithm: json['algorithm'] as String,
//       name: json['name'] as String,
//       propertySettings: (json['property_settings'] as List<dynamic>)
//           .map((e) => PropertySetting.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       terminalChannels: (json['terminal_channels'] as List<dynamic>)
//           .map((e) => TerminalChannel.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'algorithm': algorithm,
//       'name': name,
//       'property_settings': propertySettings.map((PropertySetting e) => e.toJson()).toList(),
//       'terminal_channels': terminalChannels.map((TerminalChannel e) => e.toJson()).toList(),
//     };
//   }
// }
//
// // Define the PropertySetting class
// class PropertySetting {
//   final String name;
//   final dynamic value; // Value can be int or String
//
//   PropertySetting({
//     required this.name,
//     required this.value,
//   });
//
//   factory PropertySetting.fromJson(Map<String, dynamic> json) {
//     return PropertySetting(
//       name: json['name'] as String,
//       value: json['value'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'name': name,
//       'value': value,
//     };
//   }
// }
//
// // Define the TerminalChannel class
// class TerminalChannel {
//   final int channels;
//   final String name;
//
//   TerminalChannel({
//     required this.channels,
//     required this.name,
//   });
//
//   factory TerminalChannel.fromJson(Map<String, dynamic> json) {
//     return TerminalChannel(
//       channels: json['channels'] as int,
//       name: json['name'] as String,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'channels': channels,
//       'name': name,
//     };
//   }
// }
