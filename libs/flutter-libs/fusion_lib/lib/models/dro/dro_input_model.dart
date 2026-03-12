class DroInputModel {
  final String? requestId;
  final String? version;
  final List<DroPropertySetting>? propertySettings;
  final List<DroInputStream>? inputStreams;
  final List<DroSource>? sources;
  final List<DroSourceSet>? sourceSets;
  final List<DroZoneFunction>? zoneFunctions;
  final List<DroSubzone>? subzones;
  final List<DroOutput>? outputs;
  final List<DroCompositeChain>? compositeChains;
  final List<DroOutputStream>? outputStreams;
  final DroUserSetting? userSetting;

  DroInputModel({
    this.requestId,
    this.version,
    this.propertySettings,
    this.inputStreams,
    this.sources,
    this.sourceSets,
    this.zoneFunctions,
    this.subzones,
    this.outputs,
    this.compositeChains,
    this.outputStreams,
    this.userSetting,
  });

  factory DroInputModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroInputModel();
    return DroInputModel(
      requestId: json['request_id'] as String?,
      version: json['version'] as String?,
      propertySettings: (json['property_settings'] as List<dynamic>?)?.map((e) => DroPropertySetting.fromJson(e as Map<String, dynamic>?)).toList(),
      inputStreams: (json['input_streams'] as List<dynamic>?)?.map((e) => DroInputStream.fromJson(e as Map<String, dynamic>?)).toList(),
      sources: (json['sources'] as List<dynamic>?)?.map((e) => DroSource.fromJson(e as Map<String, dynamic>?)).toList(),
      sourceSets: (json['source_sets'] as List<dynamic>?)?.map((e) => DroSourceSet.fromJson(e as Map<String, dynamic>?)).toList(),
      zoneFunctions: (json['zone_functions'] as List<dynamic>?)?.map((e) => DroZoneFunction.fromJson(e as Map<String, dynamic>?)).toList(),
      subzones: (json['subzones'] as List<dynamic>?)?.map((e) => DroSubzone.fromJson(e as Map<String, dynamic>?)).toList(),
      outputs: (json['outputs'] as List<dynamic>?)?.map((e) => DroOutput.fromJson(e as Map<String, dynamic>?)).toList(),
      compositeChains: (json['composite_chains'] as List<dynamic>?)?.map((e) => DroCompositeChain.fromJson(e as Map<String, dynamic>?)).toList(),
      outputStreams: (json['output_streams'] as List<dynamic>?)?.map((e) => DroOutputStream.fromJson(e as Map<String, dynamic>?)).toList(),
      userSetting: json['user_setting'] != null ? DroUserSetting.fromJson(json['user_setting'] as Map<String, dynamic>?) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'version': version,
    'property_settings': propertySettings?.map((e) => e.toJson()).toList(),
    'input_streams': inputStreams?.map((e) => e.toJson()).toList(),
    'sources': sources?.map((e) => e.toJson()).toList(),
    'source_sets': sourceSets?.map((e) => e.toJson()).toList(),
    'zone_functions': zoneFunctions?.map((e) => e.toJson()).toList(),
    'subzones': subzones?.map((e) => e.toJson()).toList(),
    'outputs': outputs?.map((e) => e.toJson()).toList(),
    'composite_chains': compositeChains?.map((e) => e.toJson()).toList(),
    'output_streams': outputStreams?.map((e) => e.toJson()).toList(),
    'user_setting': userSetting?.toJson(),
  };

  DroInputModel copyWith({
    String? requestId,
    String? version,
    List<DroPropertySetting>? propertySettings,
    List<DroInputStream>? inputStreams,
    List<DroSource>? sources,
    List<DroSourceSet>? sourceSets,
    List<DroZoneFunction>? zoneFunctions,
    List<DroSubzone>? subzones,
    List<DroOutput>? outputs,
    List<DroCompositeChain>? compositeChains,
    List<DroOutputStream>? outputStreams,
    DroUserSetting? userSetting,
  }) {
    return DroInputModel(
      requestId: requestId ?? this.requestId,
      version: version ?? this.version,
      propertySettings: propertySettings ?? this.propertySettings,
      inputStreams: inputStreams ?? this.inputStreams,
      sources: sources ?? this.sources,
      sourceSets: sourceSets ?? this.sourceSets,
      zoneFunctions: zoneFunctions ?? this.zoneFunctions,
      subzones: subzones ?? this.subzones,
      outputs: outputs ?? this.outputs,
      compositeChains: compositeChains ?? this.compositeChains,
      outputStreams: outputStreams ?? this.outputStreams,
      userSetting: userSetting ?? this.userSetting,
    );
  }
}

class DroPropertySetting {
  final String? name;
  final int? value;

  DroPropertySetting({this.name, this.value});

  factory DroPropertySetting.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroPropertySetting();
    return DroPropertySetting(
      name: json['name'] as String?,
      value: json['value'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
  };

  DroPropertySetting copyWith({String? name, int? value}) {
    return DroPropertySetting(
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class DroInputStream {
  final String? id;
  final String? name;
  final int? totalChannels;
  final String? serverLocation;
  final String? multicastDestinationIp;
  final List<StreamChannelMapping>? streamChannelMapping;

  DroInputStream({
    this.id,
    this.name,
    this.totalChannels,
    this.serverLocation,
    this.multicastDestinationIp,
    this.streamChannelMapping,
  });

  factory DroInputStream.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroInputStream();
    return DroInputStream(
      id: json['id'] as String?,
      name: json['name'] as String?,
      totalChannels: json['total_channels'] as int?,
      serverLocation: json['server_location'] as String?,
      multicastDestinationIp: json['multicast_destination_ip'] as String?,
      streamChannelMapping: (json['stream_channel_mapping'] as List<dynamic>?)?.map((e) => StreamChannelMapping.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'total_channels': totalChannels,
    'server_location': serverLocation,
    'multicast_destination_ip': multicastDestinationIp,
    'stream_channel_mapping': streamChannelMapping?.map((e) => e.toJson()).toList(),
  };

  DroInputStream copyWith({
    String? id,
    String? name,
    int? totalChannels,
    String? serverLocation,
    String? multicastDestinationIp,
    List<StreamChannelMapping>? streamChannelMapping,
  }) {
    return DroInputStream(
      id: id ?? this.id,
      name: name ?? this.name,
      totalChannels: totalChannels ?? this.totalChannels,
      serverLocation: serverLocation ?? this.serverLocation,
      multicastDestinationIp: multicastDestinationIp ?? this.multicastDestinationIp,
      streamChannelMapping: streamChannelMapping ?? this.streamChannelMapping,
    );
  }
}

class StreamChannelMapping {
  final String? ioId;
  final int? ioCh;

  StreamChannelMapping({this.ioId, this.ioCh});

  factory StreamChannelMapping.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StreamChannelMapping();
    return StreamChannelMapping(
      ioId: json['io_id'] as String?,
      ioCh: json['io_ch'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'io_id': ioId,
    'io_ch': ioCh,
  };

  StreamChannelMapping copyWith({String? ioId, int? ioCh}) {
    return StreamChannelMapping(
      ioId: ioId ?? this.ioId,
      ioCh: ioCh ?? this.ioCh,
    );
  }
}

class DroSource {
  final String? id;
  final String? name;
  final String? serverLocation;
  final String? ioType;
  final IoProperties? ioProperties;
  final List<DroProcessingBlock>? processingBlocks;

  DroSource({
    this.id,
    this.name,
    this.serverLocation,
    this.ioType,
    this.ioProperties,
    this.processingBlocks,
  });

  factory DroSource.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroSource();
    return DroSource(
      id: json['id'] as String?,
      name: json['name'] as String?,
      serverLocation: json['server_location'] as String?,
      ioType: json['io_type'] as String?,
      ioProperties: json['io_properties'] != null ? IoProperties.fromJson(json['io_properties'] as Map<String, dynamic>?) : null,
      processingBlocks: (json['processing_blocks'] as List<dynamic>?)?.map((e) => DroProcessingBlock.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'server_location': serverLocation,
    'io_type': ioType,
    'io_properties': ioProperties?.toJson(),
    'processing_blocks': processingBlocks?.map((e) => e.toJson()).toList(),
  };

  DroSource copyWith({
    String? id,
    String? name,
    String? serverLocation,
    String? ioType,
    IoProperties? ioProperties,
    List<DroProcessingBlock>? processingBlocks,
  }) {
    return DroSource(
      id: id ?? this.id,
      name: name ?? this.name,
      serverLocation: serverLocation ?? this.serverLocation,
      ioType: ioType ?? this.ioType,
      ioProperties: ioProperties ?? this.ioProperties,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }
}

class IoProperties {
  final int? channels;

  IoProperties({this.channels});

  factory IoProperties.fromJson(Map<String, dynamic>? json) {
    if (json == null) return IoProperties();
    return IoProperties(
      channels: json['channels'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'channels': channels,
  };

  IoProperties copyWith({int? channels}) {
    return IoProperties(
      channels: channels ?? this.channels,
    );
  }
}

class DroProcessingBlock {
  final String? id;
  final String? name;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;

  DroProcessingBlock({
    this.id,
    this.name,
    this.algorithm,
    this.algorithmProperties,
  });

  factory DroProcessingBlock.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroProcessingBlock();
    return DroProcessingBlock(
      id: json['id'] as String?,
      name: json['name'] as String?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
  };

  DroProcessingBlock copyWith({
    String? id,
    String? name,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
  }) {
    return DroProcessingBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
    );
  }
}

class DroSourceSet {
  final String? id;
  final String? name;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;
  final DroAlgorithmTerminals? algorithmTerminals;
  final List<String>? sources;
  final List<DroSourceConnection>? sourceConnections;
  final List<DroProcessingBlock>? processingBlocks;

  DroSourceSet({
    this.id,
    this.name,
    this.algorithm,
    this.algorithmProperties,
    this.algorithmTerminals,
    this.sources,
    this.sourceConnections,
    this.processingBlocks,
  });

  factory DroSourceSet.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroSourceSet();
    return DroSourceSet(
      id: json['id'] as String?,
      name: json['name'] as String?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
      algorithmTerminals: json['algorithm_terminals'] != null ? DroAlgorithmTerminals.fromJson(json['algorithm_terminals'] as Map<String, dynamic>?) : null,
      sources: (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sourceConnections: (json['source_connections'] as List<dynamic>?)?.map((e) => DroSourceConnection.fromJson(e as Map<String, dynamic>?)).toList(),
      processingBlocks: (json['processing_blocks'] as List<dynamic>?)?.map((e) => DroProcessingBlock.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
    'algorithm_terminals': algorithmTerminals?.toJson() ?? {},
    'sources': sources,
    'source_connections': sourceConnections?.map((e) => e.toJson()).toList(),
    'processing_blocks': processingBlocks?.map((e) => e.toJson()).toList(),
  };

  DroSourceSet copyWith({
    String? id,
    String? name,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
    DroAlgorithmTerminals? algorithmTerminals,
    List<String>? sources,
    List<DroSourceConnection>? sourceConnections,
    List<DroProcessingBlock>? processingBlocks,
  }) {
    return DroSourceSet(
      id: id ?? this.id,
      name: name ?? this.name,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
      algorithmTerminals: algorithmTerminals ?? this.algorithmTerminals,
      sources: sources ?? this.sources,
      sourceConnections: sourceConnections ?? this.sourceConnections,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }
}

class DroAlgorithmTerminals {
  final int? inTerminal;
  final int? outTerminal;

  DroAlgorithmTerminals({this.inTerminal, this.outTerminal});

  factory DroAlgorithmTerminals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroAlgorithmTerminals();
    return DroAlgorithmTerminals(
      inTerminal: json['in'] as int?,
      outTerminal: json['out'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'in': inTerminal,
    'out': outTerminal,
  };

  DroAlgorithmTerminals copyWith({int? inTerminal, int? outTerminal}) {
    return DroAlgorithmTerminals(
      inTerminal: inTerminal ?? this.inTerminal,
      outTerminal: outTerminal ?? this.outTerminal,
    );
  }
}

class DroSourceConnection {
  final String? sourceChainId;
  final String? sourceTerminal;
  final int? sourceChannel;
  final String? destinationTerminal;
  final int? destinationChannel;

  DroSourceConnection({
    this.sourceChainId,
    this.sourceTerminal,
    this.sourceChannel,
    this.destinationTerminal,
    this.destinationChannel,
  });

  factory DroSourceConnection.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroSourceConnection();
    return DroSourceConnection(
      sourceChainId: json['source_chain_id'] as String?,
      sourceTerminal: json['source_terminal'] as String?,
      sourceChannel: json['source_channel'] as int?,
      destinationTerminal: json['destination_terminal'] as String?,
      destinationChannel: json['destination_channel'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'source_chain_id': sourceChainId,
    'source_terminal': sourceTerminal,
    'source_channel': sourceChannel,
    'destination_terminal': destinationTerminal,
    'destination_channel': destinationChannel,
  };

  DroSourceConnection copyWith({
    String? sourceChainId,
    String? sourceTerminal,
    int? sourceChannel,
    String? destinationTerminal,
    int? destinationChannel,
  }) {
    return DroSourceConnection(
      sourceChainId: sourceChainId ?? this.sourceChainId,
      sourceTerminal: sourceTerminal ?? this.sourceTerminal,
      sourceChannel: sourceChannel ?? this.sourceChannel,
      destinationTerminal: destinationTerminal ?? this.destinationTerminal,
      destinationChannel: destinationChannel ?? this.destinationChannel,
    );
  }
}

class DroZoneFunction {
  final String? id;
  final String? name;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;
  final DroAlgorithmTerminals? algorithmTerminals;
  final List<DroSourceConnection>? sourceConnections;

  DroZoneFunction({
    this.id,
    this.name,
    this.algorithm,
    this.algorithmProperties,
    this.algorithmTerminals,
    this.sourceConnections,
  });

  factory DroZoneFunction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroZoneFunction();
    return DroZoneFunction(
      id: json['id'] as String?,
      name: json['name'] as String?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
      algorithmTerminals: json['algorithm_terminals'] != null ? DroAlgorithmTerminals.fromJson(json['algorithm_terminals'] as Map<String, dynamic>?) : null,
      sourceConnections: (json['source_connections'] as List<dynamic>?)?.map((e) => DroSourceConnection.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
    'algorithm_terminals': algorithmTerminals?.toJson(),
    'source_connections': sourceConnections?.map((e) => e.toJson()).toList(),
  };

  DroZoneFunction copyWith({
    String? id,
    String? name,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
    DroAlgorithmTerminals? algorithmTerminals,
    List<DroSourceConnection>? sourceConnections,
  }) {
    return DroZoneFunction(
      id: id ?? this.id,
      name: name ?? this.name,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
      algorithmTerminals: algorithmTerminals ?? this.algorithmTerminals,
      sourceConnections: sourceConnections ?? this.sourceConnections,
    );
  }
}

class DroSubzone {
  final DroSubzoneControl? subzoneControl;
  final DroSubzoneProcessing? subzoneProcessing;

  DroSubzone({
    this.subzoneControl,
    this.subzoneProcessing,
  });

  factory DroSubzone.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroSubzone();
    return DroSubzone(
      subzoneControl: json['subzone_control'] != null && (json['subzone_control'] as Map).isNotEmpty
          ? DroSubzoneControl.fromJson(json['subzone_control'] as Map<String, dynamic>?)
          : null,
      subzoneProcessing: json['subzone_processing'] != null ? DroSubzoneProcessing.fromJson(json['subzone_processing'] as Map<String, dynamic>?) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'subzone_control': subzoneControl?.toJson() ?? {},
    'subzone_processing': subzoneProcessing?.toJson() ?? {},
  };

  DroSubzone copyWith({
    DroSubzoneControl? subzoneControl,
    DroSubzoneProcessing? subzoneProcessing,
  }) {
    return DroSubzone(
      subzoneControl: subzoneControl ?? this.subzoneControl,
      subzoneProcessing: subzoneProcessing ?? this.subzoneProcessing,
    );
  }
}

class DroSubzoneControl {
  final String? id;
  final String? name;
  final int? sourceChannels;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;
  final DroAlgorithmTerminals? algorithmTerminals;
  final List<DroSourceConnection>? sourceConnections;
  final List<DroProcessingBlock>? processingBlocks;

  DroSubzoneControl({
    this.id,
    this.name,
    this.sourceChannels,
    this.algorithm,
    this.algorithmProperties,
    this.algorithmTerminals,
    this.sourceConnections,
    this.processingBlocks,
  });

  factory DroSubzoneControl.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroSubzoneControl();
    return DroSubzoneControl(
      id: json['id'] as String?,
      name: json['name'] as String?,
      sourceChannels: json['source_channels'] as int?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
      algorithmTerminals: json['algorithm_terminals'] != null ? DroAlgorithmTerminals.fromJson(json['algorithm_terminals'] as Map<String, dynamic>?) : null,
      sourceConnections: (json['source_connections'] as List<dynamic>?)?.map((e) => DroSourceConnection.fromJson(e as Map<String, dynamic>?)).toList(),
      processingBlocks: (json['processing_blocks'] as List<dynamic>?)?.map((e) => DroProcessingBlock.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'source_channels': sourceChannels,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
    'algorithm_terminals': algorithmTerminals?.toJson(),
    'source_connections': sourceConnections?.map((e) => e.toJson()).toList(),
    'processing_blocks': processingBlocks?.map((e) => e.toJson()).toList(),
  };

  DroSubzoneControl copyWith({
    String? id,
    String? name,
    int? sourceChannels,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
    DroAlgorithmTerminals? algorithmTerminals,
    List<DroSourceConnection>? sourceConnections,
    List<DroProcessingBlock>? processingBlocks,
  }) {
    return DroSubzoneControl(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceChannels: sourceChannels ?? this.sourceChannels,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
      algorithmTerminals: algorithmTerminals ?? this.algorithmTerminals,
      sourceConnections: sourceConnections ?? this.sourceConnections,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }
}

class DroSubzoneProcessing {
  final String? id;
  final String? name;
  final int? sourceChannels;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;
  final List<DroSourceConnection>? sourceConnections;
  final List<DroProcessingBlock>? processingBlocks;

  DroSubzoneProcessing({
    this.id,
    this.name,
    this.sourceChannels,
    this.algorithm,
    this.algorithmProperties,
    this.sourceConnections,
    this.processingBlocks,
  });

  factory DroSubzoneProcessing.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroSubzoneProcessing();
    return DroSubzoneProcessing(
      id: json['id'] as String?,
      name: json['name'] as String?,
      sourceChannels: json['source_channels'] as int?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
      sourceConnections: (json['source_connections'] as List<dynamic>?)?.map((e) => DroSourceConnection.fromJson(e as Map<String, dynamic>?)).toList(),
      processingBlocks: (json['processing_blocks'] as List<dynamic>?)?.map((e) => DroProcessingBlock.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'source_channels': sourceChannels,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
    'source_connections': sourceConnections?.map((e) => e.toJson()).toList(),
    'processing_blocks': processingBlocks?.map((e) => e.toJson()).toList(),
  };

  DroSubzoneProcessing copyWith({
    String? id,
    String? name,
    int? sourceChannels,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
    List<DroSourceConnection>? sourceConnections,
    List<DroProcessingBlock>? processingBlocks,
  }) {
    return DroSubzoneProcessing(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceChannels: sourceChannels ?? this.sourceChannels,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
      sourceConnections: sourceConnections ?? this.sourceConnections,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }
}

class DroOutput {
  final String? id;
  final String? name;
  final String? serverLocation;
  final String? ioType;
  final IoProperties? ioProperties;
  final int? sourceChannels;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;
  final DroAlgorithmTerminals? algorithmTerminals;
  final List<DroSourceConnection>? sourceConnections;
  final List<DroProcessingBlock>? processingBlocks;

  DroOutput({
    this.id,
    this.name,
    this.serverLocation,
    this.ioType,
    this.ioProperties,
    this.sourceChannels,
    this.algorithm,
    this.algorithmProperties,
    this.algorithmTerminals,
    this.sourceConnections,
    this.processingBlocks,
  });

  factory DroOutput.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroOutput();
    return DroOutput(
      id: json['id'] as String?,
      name: json['name'] as String?,
      serverLocation: json['server_location'] as String?,
      ioType: json['io_type'] as String?,
      ioProperties: json['io_properties'] != null ? IoProperties.fromJson(json['io_properties'] as Map<String, dynamic>?) : null,
      sourceChannels: json['source_channels'] as int?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
      algorithmTerminals: json['algorithm_terminals'] != null ? DroAlgorithmTerminals.fromJson(json['algorithm_terminals'] as Map<String, dynamic>?) : null,
      sourceConnections: (json['source_connections'] as List<dynamic>?)?.map((e) => DroSourceConnection.fromJson(e as Map<String, dynamic>?)).toList(),
      processingBlocks: (json['processing_blocks'] as List<dynamic>?)?.map((e) => DroProcessingBlock.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'server_location': serverLocation,
    'io_type': ioType,
    'io_properties': ioProperties?.toJson(),
    'source_channels': sourceChannels,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
    'algorithm_terminals': algorithmTerminals?.toJson(),
    'source_connections': sourceConnections?.map((e) => e.toJson()).toList(),
    'processing_blocks': processingBlocks?.map((e) => e.toJson()).toList(),
  };

  DroOutput copyWith({
    String? id,
    String? name,
    String? serverLocation,
    String? ioType,
    IoProperties? ioProperties,
    int? sourceChannels,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
    DroAlgorithmTerminals? algorithmTerminals,
    List<DroSourceConnection>? sourceConnections,
    List<DroProcessingBlock>? processingBlocks,
  }) {
    return DroOutput(
      id: id ?? this.id,
      name: name ?? this.name,
      serverLocation: serverLocation ?? this.serverLocation,
      ioType: ioType ?? this.ioType,
      ioProperties: ioProperties ?? this.ioProperties,
      sourceChannels: sourceChannels ?? this.sourceChannels,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
      algorithmTerminals: algorithmTerminals ?? this.algorithmTerminals,
      sourceConnections: sourceConnections ?? this.sourceConnections,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }
}

class DroCompositeChain {
  final String? id;
  final String? name;
  final String? algorithm;
  final Map<String, dynamic>? algorithmProperties;
  final List<DroSourceConnection>? sourceConnections;

  DroCompositeChain({
    this.id,
    this.name,
    this.algorithm,
    this.algorithmProperties,
    this.sourceConnections,
  });

  factory DroCompositeChain.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroCompositeChain();
    return DroCompositeChain(
      id: json['id'] as String?,
      name: json['name'] as String?,
      algorithm: json['algorithm'] as String?,
      algorithmProperties: json['algorithm_properties'] as Map<String, dynamic>?,
      sourceConnections: (json['source_connections'] as List<dynamic>?)?.map((e) => DroSourceConnection.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'algorithm': algorithm,
    'algorithm_properties': algorithmProperties,
    'source_connections': sourceConnections?.map((e) => e.toJson()).toList(),
  };

  DroCompositeChain copyWith({
    String? id,
    String? name,
    String? algorithm,
    Map<String, dynamic>? algorithmProperties,
    List<DroSourceConnection>? sourceConnections,
  }) {
    return DroCompositeChain(
      id: id ?? this.id,
      name: name ?? this.name,
      algorithm: algorithm ?? this.algorithm,
      algorithmProperties: algorithmProperties ?? this.algorithmProperties,
      sourceConnections: sourceConnections ?? this.sourceConnections,
    );
  }
}

class DroOutputStream {
  final String? id;
  final String? name;
  final int? totalChannels;
  final String? serverLocation;
  final String? multicastDestinationIp;
  final List<StreamChannelMapping>? streamChannelMapping;

  DroOutputStream({
    this.id,
    this.name,
    this.totalChannels,
    this.serverLocation,
    this.multicastDestinationIp,
    this.streamChannelMapping,
  });

  factory DroOutputStream.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroOutputStream();
    return DroOutputStream(
      id: json['id'] as String?,
      name: json['name'] as String?,
      totalChannels: json['total_channels'] as int?,
      serverLocation: json['server_location'] as String?,
      multicastDestinationIp: json['multicast_destination_ip'] as String?,
      streamChannelMapping: (json['stream_channel_mapping'] as List<dynamic>?)?.map((e) => StreamChannelMapping.fromJson(e as Map<String, dynamic>?)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'total_channels': totalChannels,
    'server_location': serverLocation,
    'multicast_destination_ip': multicastDestinationIp,
    'stream_channel_mapping': streamChannelMapping?.map((e) => e.toJson()).toList(),
  };

  DroOutputStream copyWith({
    String? id,
    String? name,
    int? totalChannels,
    String? serverLocation,
    String? multicastDestinationIp,
    List<StreamChannelMapping>? streamChannelMapping,
  }) {
    return DroOutputStream(
      id: id ?? this.id,
      name: name ?? this.name,
      totalChannels: totalChannels ?? this.totalChannels,
      serverLocation: serverLocation ?? this.serverLocation,
      multicastDestinationIp: multicastDestinationIp ?? this.multicastDestinationIp,
      streamChannelMapping: streamChannelMapping ?? this.streamChannelMapping,
    );
  }
}

class DroUserSetting {
  final List<DroMaxDevice>? maxDevices;
  final List<DroIoPorts>? ioPorts;
  final int? deviceCapacity;
  final int? maxSolveTime;
  final int? maxDeviceHopCount;
  final int? maxNetworkLatency;
  final int? costOption;

  DroUserSetting({
    this.maxDevices,
    this.ioPorts,
    this.deviceCapacity,
    this.maxSolveTime,
    this.maxDeviceHopCount,
    this.maxNetworkLatency,
    this.costOption,
  });

  factory DroUserSetting.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroUserSetting();
    return DroUserSetting(
      maxDevices: (json['max_devices'] as List<dynamic>?)?.map((e) => DroMaxDevice.fromJson(e as Map<String, dynamic>?)).toList(),
      ioPorts: (json['io_ports'] as List<dynamic>?)?.map((e) => DroIoPorts.fromJson(e as Map<String, dynamic>?)).toList(),
      deviceCapacity: json['device_capacity'] as int?,
      maxSolveTime: json['max_solve_time'] as int?,
      maxDeviceHopCount: json['max_device_hop_count'] as int?,
      maxNetworkLatency: json['max_network_latency'] as int?,
      costOption: json['cost_option'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'max_devices': maxDevices?.map((e) => e.toJson()).toList(),
    'io_ports': ioPorts?.map((e) => e.toJson()).toList(),
    'device_capacity': deviceCapacity,
    'max_solve_time': maxSolveTime,
    'max_device_hop_count': maxDeviceHopCount,
    'max_network_latency': maxNetworkLatency,
    'cost_option': costOption,
  };

  DroUserSetting copyWith({
    List<DroMaxDevice>? maxDevices,
    List<DroIoPorts>? ioPorts,
    int? deviceCapacity,
    int? maxSolveTime,
    int? maxDeviceHopCount,
    int? maxNetworkLatency,
    int? costOption,
  }) {
    return DroUserSetting(
      maxDevices: maxDevices ?? this.maxDevices,
      ioPorts: ioPorts ?? this.ioPorts,
      deviceCapacity: deviceCapacity ?? this.deviceCapacity,
      maxSolveTime: maxSolveTime ?? this.maxSolveTime,
      maxDeviceHopCount: maxDeviceHopCount ?? this.maxDeviceHopCount,
      maxNetworkLatency: maxNetworkLatency ?? this.maxNetworkLatency,
      costOption: costOption ?? this.costOption,
    );
  }
}

class DroMaxDevice {
  final String? deviceId;
  final String? deviceType;
  final String? deviceLocation;

  DroMaxDevice({
    this.deviceId,
    this.deviceType,
    this.deviceLocation,
  });

  factory DroMaxDevice.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroMaxDevice();
    return DroMaxDevice(
      deviceId: json['device_id'] as String?,
      deviceType: json['device_type'] as String?,
      deviceLocation: json['device_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_type': deviceType,
    'device_location': deviceLocation,
  };

  DroMaxDevice copyWith({
    String? deviceId,
    String? deviceType,
    String? deviceLocation,
  }) {
    return DroMaxDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceLocation: deviceLocation ?? this.deviceLocation,
    );
  }
}

class DroIoPorts {
  final String? ioId;
  final String? deviceId;
  final String? portType;
  final List<int>? portNums;

  DroIoPorts({
    this.ioId,
    this.deviceId,
    this.portType,
    this.portNums,
  });

  factory DroIoPorts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DroIoPorts();
    return DroIoPorts(
      ioId: json['io_id'] as String?,
      deviceId: json['device_id'] as String?,
      portType: json['port_type'] as String?,
      portNums: (json['port_nums'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'io_id': ioId,
    'device_id': deviceId,
    'port_type': portType,
    'port_nums': portNums,
  };

  DroIoPorts copyWith({
    String? ioId,
    String? deviceId,
    String? portType,
    List<int>? portNums,
  }) {
    return DroIoPorts(
      ioId: ioId ?? this.ioId,
      deviceId: deviceId ?? this.deviceId,
      portType: portType ?? this.portType,
      portNums: portNums ?? this.portNums,
    );
  }
}
