class SchemaModel {
  List<Devices>? devices;
  WallControllerConfig? wallControllerConfig;
  SchemaModel({this.devices,this.wallControllerConfig});

  SchemaModel.fromJson(Map<String, dynamic> json) {
    if (json['devices'] != null) {
      devices = <Devices>[];
      json['devices'].forEach((v) {
        devices!.add(Devices.fromJson(v));
      });
    }
    wallControllerConfig = json['wall_controller_config'] != null
        ? WallControllerConfig.fromJson(json['wall_controller_config'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (devices != null) {
      data['devices'] = devices!.map((v) => v.toJson()).toList();
    }
    if (this.wallControllerConfig != null) {
      data['wall_controller_config'] = this.wallControllerConfig!.toJson();
    }
    return data;
  }
}

class Devices {
  List<dynamic>? connectionsDeviceIn;
  List<dynamic>? connectionsDeviceOut;
  List<Cores>? cores;
  int? cost;
  String? deviceType;
  DspStaticConfig? dspStaticConfig;
  String? id;
  String? label;
  String? location;

  Devices(
      {this.connectionsDeviceIn,
        this.connectionsDeviceOut,
        this.cores,
        this.cost,
        this.deviceType,
        this.dspStaticConfig,
        this.id,
        this.label,
        this.location});

  Devices.fromJson(Map<String, dynamic> json) {
    if (json['connections_device_in'] != null) {
      connectionsDeviceIn = <Null>[];
      json['connections_device_in'].forEach((v) {
        connectionsDeviceIn!.add(v.toString());
      });
    }
    if (json['connections_device_out'] != null) {
      connectionsDeviceOut = <Null>[];
      json['connections_device_out'].forEach((v) {
        connectionsDeviceOut!.add(v.toString());
      });
    }
    if (json['cores'] != null) {
      cores = <Cores>[];
      json['cores'].forEach((v) {
        cores!.add(Cores.fromJson(v));
      });
    }
    cost = toInt(json['cost']);
    deviceType = json['device_type'];
    dspStaticConfig = json['dsp_static_config'] != null
        ? DspStaticConfig.fromJson(json['dsp_static_config'])
        : null;
    id = json['id'];
    label = json['label'];
    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (connectionsDeviceIn != null) {
      data['connections_device_in'] =
          connectionsDeviceIn!.map((v) => v.toJson()).toList();
    }
    if (connectionsDeviceOut != null) {
      data['connections_device_out'] =
          connectionsDeviceOut!.map((v) => v.toJson()).toList();
    }
    if (cores != null) {
      data['cores'] = cores!.map((v) => v.toJson()).toList();
    }
    data['cost'] = cost;
    data['device_type'] = deviceType;
    if (dspStaticConfig != null) {
      data['dsp_static_config'] = dspStaticConfig!.toJson();
    }
    data['id'] = id;
    data['label'] = label;
    data['location'] = location;
    return data;
  }
}

class Cores {
  List<String>? blockIds;
  String? label;
  double? utilAlgs;
  int? utilDeviceConnect;
  double? utilTaskConnect;
  double? utilTotal;

  Cores(
      {this.blockIds,
        this.label,
        this.utilAlgs,
        this.utilDeviceConnect,
        this.utilTaskConnect,
        this.utilTotal});

  Cores.fromJson(Map<String, dynamic> json) {
    blockIds = json['block_ids'].cast<String>();
    label = json['label'];

    utilAlgs =  toDouble(json['util_algs']);
    utilDeviceConnect = toInt(json['util_device_connect']);
    utilTaskConnect = toDouble(json['util_task_connect']);
    utilTotal =  toDouble(json['util_total']);
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['block_ids'] = blockIds;
    data['label'] = label;
    data['util_algs'] = utilAlgs;
    data['util_device_connect'] = utilDeviceConnect;
    data['util_task_connect'] = utilTaskConnect;
    data['util_total'] = utilTotal;
    return data;
  }
}

class DspStaticConfig {
  List<AudioTasks>? audioTasks;
  List<dynamic>? parameterSettings;
  Session? session;
  List<TaskConnections>? taskConnections;

  DspStaticConfig(
      {this.audioTasks,
        this.parameterSettings,
        this.session,
        this.taskConnections});

  DspStaticConfig.fromJson(Map<String, dynamic> json) {
    if (json['audio_tasks'] != null) {
      audioTasks = <AudioTasks>[];
      json['audio_tasks'].forEach((v) {
        audioTasks!.add(AudioTasks.fromJson(v));
      });
    }
    if (json['parameter_settings'] != null) {
      parameterSettings = <Null>[];
      json['parameter_settings'].forEach((v) {
        parameterSettings!.add(v.toString());
      });
    }
    session =
    json['session'] != null ? Session.fromJson(json['session']) : null;
    if (json['task_connections'] != null) {
      taskConnections = <TaskConnections>[];
      json['task_connections'].forEach((v) {
        taskConnections!.add(TaskConnections.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (audioTasks != null) {
      data['audio_tasks'] = audioTasks!.map((v) => v.toJson()).toList();
    }
    if (parameterSettings != null) {
      data['parameter_settings'] =
          parameterSettings!.map((v) => v.toJson()).toList();
    }
    if (session != null) {
      data['session'] = session!.toJson();
    }
    if (taskConnections != null) {
      data['task_connections'] =
          taskConnections!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AudioTasks {
  List<BlockConnections>? blockConnections;
  List<Blocks>? blocks;
  String? name;
  List<PropertySettings>? propertySettings;

  AudioTasks(
      {this.blockConnections, this.blocks, this.name, this.propertySettings});

  AudioTasks.fromJson(Map<String, dynamic> json) {
    if (json['block_connections'] != null) {
      blockConnections = <BlockConnections>[];
      json['block_connections'].forEach((v) {
        blockConnections!.add(BlockConnections.fromJson(v));
      });
    }
    if (json['blocks'] != null) {
      blocks = <Blocks>[];
      json['blocks'].forEach((v) {
        blocks!.add(Blocks.fromJson(v));
      });
    }
    name = json['name'];
    if (json['property_settings'] != null) {
      propertySettings = <PropertySettings>[];
      json['property_settings'].forEach((v) {
        propertySettings!.add(PropertySettings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (blockConnections != null) {
      data['block_connections'] =
          blockConnections!.map((v) => v.toJson()).toList();
    }
    if (blocks != null) {
      data['blocks'] = blocks!.map((v) => v.toJson()).toList();
    }
    data['name'] = name;
    if (propertySettings != null) {
      data['property_settings'] =
          propertySettings!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BlockConnections {
  String? destinationBlock;
  int? inputChannel;
  String? inputTerminal;
  int? outputChannel;
  String? outputTerminal;
  String? sourceBlock;

  BlockConnections(
      {this.destinationBlock,
        this.inputChannel,
        this.inputTerminal,
        this.outputChannel,
        this.outputTerminal,
        this.sourceBlock});

  BlockConnections.fromJson(Map<String, dynamic> json) {
    destinationBlock = json['destination_block'];
    inputChannel = toInt(json['input_channel']);
    outputChannel = toInt(json['output_channel']);
    inputTerminal = json['input_terminal'];
    outputTerminal = json['output_terminal'];
    sourceBlock = json['source_block'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['destination_block'] = destinationBlock;
    data['input_channel'] = inputChannel;
    data['input_terminal'] = inputTerminal;
    data['output_channel'] = outputChannel;
    data['output_terminal'] = outputTerminal;
    data['source_block'] = sourceBlock;
    return data;
  }
}

class Blocks {
  String? algorithm;
  String? name;
  List<PropertySettings>? propertySettings;
  List<TerminalChannels>? terminalChannels;

  Blocks(
      {this.algorithm,
        this.name,
        this.propertySettings,
        this.terminalChannels});

  Blocks.fromJson(Map<String, dynamic> json) {
    algorithm = json['algorithm'];
    name = json['name'];
    if (json['property_settings'] != null) {
      propertySettings = <PropertySettings>[];
      json['property_settings'].forEach((v) {
        propertySettings!.add(PropertySettings.fromJson(v));
      });
    }
    if (json['terminal_channels'] != null) {
      terminalChannels = <TerminalChannels>[];
      json['terminal_channels'].forEach((v) {
        terminalChannels!.add(TerminalChannels.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['algorithm'] = algorithm;
    data['name'] = name;
    if (propertySettings != null) {
      data['property_settings'] =
          propertySettings!.map((v) => v.toJson()).toList();
    }
    if (terminalChannels != null) {
      data['terminal_channels'] =
          terminalChannels!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PropertySettings {
  String? name;
  int? value;

  PropertySettings({this.name, this.value});

  PropertySettings.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    value =toInt(json['value']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['value'] = value;
    return data;
  }
}

class TerminalChannels {
  int? channels;
  String? name;

  TerminalChannels({this.channels, this.name});

  TerminalChannels.fromJson(Map<String, dynamic> json) {
    channels = toInt(json['channels']);
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['channels'] = channels;
    data['name'] = name;
    return data;
  }
}

class Session {
  List<PropertySettings>? propertySettings;

  Session({this.propertySettings});

  Session.fromJson(Map<String, dynamic> json) {
    if (json['property_settings'] != null) {
      propertySettings = <PropertySettings>[];
      json['property_settings'].forEach((v) {
        propertySettings!.add(PropertySettings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (propertySettings != null) {
      data['property_settings'] =
          propertySettings!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TaskConnections {
  String? destinationTask;
  String? inputBlock;
  int? inputChannel;
  String? outputBlock;
  int? outputChannel;
  String? sourceTask;

  TaskConnections(
      {this.destinationTask,
        this.inputBlock,
        this.inputChannel,
        this.outputBlock,
        this.outputChannel,
        this.sourceTask});

  TaskConnections.fromJson(Map<String, dynamic> json) {
    destinationTask = json['destination_task'];
    inputBlock = json['input_block'];
    inputChannel = toInt(json['input_channel']);
    outputChannel = toInt(json['output_channel']);
    outputBlock = json['output_block'];
    sourceTask = json['source_task'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['destination_task'] = destinationTask;
    data['input_block'] = inputBlock;
    data['input_channel'] = inputChannel;
    data['output_block'] = outputBlock;
    data['output_channel'] = outputChannel;
    data['source_task'] = sourceTask;
    return data;
  }
}

class WallControllerConfig {
  List<Controllers>? controllers;
  List<Zones>? zones;

  WallControllerConfig({this.controllers, this.zones});

  WallControllerConfig.fromJson(Map<String, dynamic> json) {
    if (json['controllers'] != null) {
      controllers = <Controllers>[];
      json['controllers'].forEach((v) {
        controllers!.add(Controllers.fromJson(v));
      });
    }
    if (json['zones'] != null) {
      zones = <Zones>[];
      json['zones'].forEach((v) {
        zones!.add(Zones.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.controllers != null) {
      data['controllers'] = this.controllers!.map((v) => v.toJson()).toList();
    }
    if (this.zones != null) {
      data['zones'] = this.zones!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Controllers {
  String? id;
  String? name;
  List<String>? zoneIds;

  Controllers({this.id, this.name, this.zoneIds});

  Controllers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    zoneIds = json['zoneIds'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['zoneIds'] = this.zoneIds;
    return data;
  }
}

class Zones {
  Gain? gain;
  String? id;
  String? name;
  Ono? ono;
  List<Sources>? sources;

  Zones({this.gain, this.id, this.name, this.ono, this.sources});

  Zones.fromJson(Map<String, dynamic> json) {
    gain = json['gain'] != null ? Gain.fromJson(json['gain']) : null;
    id = json['id'];
    name = json['name'];
    ono = json['ono'] != null ? Ono.fromJson(json['ono']) : null;
    if (json['sources'] != null) {
      sources = <Sources>[];
      json['sources'].forEach((v) {
        sources!.add(Sources.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.gain != null) {
      data['gain'] = this.gain!.toJson();
    }
    data['id'] = this.id;
    data['name'] = this.name;
    if (this.ono != null) {
      data['ono'] = this.ono!.toJson();
    }
    if (this.sources != null) {
      data['sources'] = this.sources!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Gain {
  String? defaultGainValue;
  String? defaultMuteValue;
  String? gainID;
  String? maxValue;
  String? minValue;

  Gain(
      {this.defaultGainValue,
        this.defaultMuteValue,
        this.gainID,
        this.maxValue,
        this.minValue});

  Gain.fromJson(Map<String, dynamic> json) {
    defaultGainValue = json['default_gain_value'];
    defaultMuteValue = json['default_mute_value'];
    gainID = json['gainID'];
    maxValue = json['max_value'];
    minValue = json['min_value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['default_gain_value'] = this.defaultGainValue;
    data['default_mute_value'] = this.defaultMuteValue;
    data['gainID'] = this.gainID;
    data['max_value'] = this.maxValue;
    data['min_value'] = this.minValue;
    return data;
  }
}

class Ono {
  int? gain;
  int? mute;
  int? sourceSelector;
  int? zone;

  Ono({this.gain, this.mute, this.sourceSelector, this.zone});

  Ono.fromJson(Map<String, dynamic> json) {
    gain = json['gain'];
    mute = json['mute'];
    sourceSelector = json['sourceSelector'];
    zone = json['zone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['gain'] = this.gain;
    data['mute'] = this.mute;
    data['sourceSelector'] = this.sourceSelector;
    data['zone'] = this.zone;
    return data;
  }
}

class Sources {
  int? index;
  String? sourceId;
  String? sourceName;

  Sources({this.index, this.sourceId,this.sourceName});

  Sources.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    sourceId = json['sourceId'];
    sourceName = json['sourceName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['index'] = this.index;
    data['sourceId'] = this.sourceId;
    data['sourceName'] = this.sourceName;
    return data;
  }
}

double? toDouble(dynamic value) {
  return (value as num?)?.toDouble();
}

int? toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}