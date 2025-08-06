import 'package:fusion_design_tool_prototype/core/models/source_entity.dart';
import 'package:fusion_design_tool_prototype/core/models/speaker_entity.dart';
// Abstract base class for all device components
abstract class DeviceComponent {
  final String id;
  final String assetPath;
  final String name;
  final double price;

  const DeviceComponent({
    required this.id,
    required this.assetPath,
    required this.name,
    required this.price,
  });
}

class SpeakerData extends DeviceComponent {
  final String sku;
  final OutputType type;

  const SpeakerData({
    required this.sku,
    required this.type,
    required super.assetPath,
    required super.name,
    required super.price,
  }) : super(id: sku);

  static const List<SpeakerData> demoSpeakers = <SpeakerData>[
    SpeakerData(
      assetPath: 'assets/images/speakers/MSA12X.png',
      name: 'MSA12X',
      sku: 'MSA12X',
      type: OutputType.analogOutput,
      price: 500.0,
    ),
    SpeakerData(
      assetPath: 'assets/images/speakers/array1.png',
      name: 'ArenaMatch AM40',
      sku: 'CO-12 H120',
      type: OutputType.analogOutput,
      price: 600.0,
    ),
    SpeakerData(
      assetPath: 'assets/images/speakers/DM_pendant.png',
      name: 'DesignMax DM6PE',
      sku: 'MSA12XOHS',
      type: OutputType.analogOutput,
      price: 700.0,
    ),
    SpeakerData(
      assetPath: 'assets/icons/aes67.png',
      name: 'AES67 Output',
      sku: 'AES67OUT',
      type: OutputType.aes67output,
      price: 100.0,
    ),
  ];

  static const List<String> speakerTypes = <String>['Surface', 'Ceiling', 'Pendant', 'Sub'];
}

class SourceData extends DeviceComponent {
  final SourceType type;

  const SourceData({
    required this.type,
    required super.assetPath,
    required super.name,
    required super.id,
    required super.price,
  });

  static const List<SourceData> demoSources = <SourceData>[
    SourceData(
      assetPath: 'assets/images/products/mic1.png',
      name: 'Microphone',
      id: 'MIC01',
      type: SourceType.analogInput,
      price: 100.0,
    ),
    SourceData(
      assetPath: 'assets/images/products/dvdplayer.png',
      name: 'Music Player',
      id: 'LINE01',
      type: SourceType.analogInput,
      price: 150.0,
    ),
    SourceData(
      assetPath: 'assets/icons/aes67.png',
      name: 'AES67 Input',
      id: 'AES01',
      type: SourceType.aes67input,
      price: 200.0,
    ),
    SourceData(
      assetPath: 'assets/icons/bluetooth.png',
      name: 'Bluetooth Input',
      id: 'BLUETOOTH01',
      type: SourceType.bluetooth,
      price: 0.0,
    ),
  ];
}

class ControllerData extends DeviceComponent {
  final String sku;
  const ControllerData( {
    required super.assetPath,
    required super.name,
    required super.id,
    required super.price,
    required this.sku,
  });

  static const List<ControllerData> demoControllers = <ControllerData>[
    ControllerData(
      assetPath: 'assets/images/products/cc1.png',
      name: 'Analog Controller',
      id: 'CC1',
      price: 100.0,
      sku: 'CC1',
    ),
    ControllerData(
      assetPath: 'assets/images/products/cc2.png',
      name: 'Digital Controller',
      id: 'CC2',
      price: 150.0,
      sku: 'CC2',
    ),
  ];
}

class RackData extends DeviceComponent {
  const RackData({
    required super.assetPath,
    required super.name,
    required super.id,
    required super.price,
  });

  static const List<RackData> demoRacks = <RackData>[
    RackData(
      assetPath: 'assets/images/products/rack2.png',
      name: 'Small Rack',
      id: 'RACK2U',
      price: 1000.0,
    ),
    RackData(
      assetPath: 'assets/images/products/rack1.png',
      name: 'Big Rack',
      id: 'RACK4U',
      price: 2000.0,
    ),
  ];
}