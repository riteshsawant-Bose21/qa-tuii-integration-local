// Abstract base class for all device components
import 'package:fusion_lib/models/fusion_models.dart';

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
  final SourceConnectionType connectionType;

  const SourceData({
    required this.type,
    required this.connectionType,
    required super.assetPath,
    required super.name,
    required super.id,
    required super.price,
  });

  static const List<SourceData> microphoneItems = <SourceData>[
    SourceData(
      id: "gooseneck",
      name: "Gooseneck",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "hanging",
      name: "Hanging",
      assetPath: "assets/images/products/hanging_mic.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "condenser",
      name: "Condenser",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "dynamic",
      name: "Dynamic",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "shotgun",
      name: "Shotgun",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "pzm",
      name: "PZM",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "lavalier",
      name: "Lavalier",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "headset",
      name: "Headset",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "handheld",
      name: "Handheld",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "beltpack",
      name: "Beltpack",
      assetPath: "assets/images/products/mic1.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "paging",
      name: "Paging",
      assetPath: "assets/images/products/paging_mic.png",
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
  ];

  static const List<SourceData> mediaSourceItems = <SourceData>[
    SourceData(
      id: "generic_mono",
      name: "Generic Mono",
      assetPath: "assets/images/products/dvdplayer.png",
      type: SourceType.generic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "generic_stereo",
      name: "Generic Stereo",
      assetPath: "assets/images/products/dvdplayer.png",
      type: SourceType.generic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "cd",
      name: "CD",
      assetPath: "assets/images/products/dvdplayer.png",
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "sat_cable_hdmi",
      name: "Sat/Cable - HDMI",
      assetPath: "assets/images/products/hdmi.png",
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "media_player",
      name: "Media Player",
      assetPath: "assets/images/products/dvdplayer.png",
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "tuner",
      name: "Tuner",
      assetPath: "assets/images/products/dvdplayer.png",
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "dvd_hdmi",
      name: "DVD - HDMI",
      assetPath: "assets/images/products/hdmi.png",
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "bluray_hdmi",
      name: "BluRay HDMI",
      assetPath: "assets/images/products/hdmi.png",
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      id: "laptop_usb_hdmi",
      name: "Laptop - USB - or HDMI",
      assetPath: "assets/images/products/laptop.png",
      connectionType: SourceConnectionType.usb,
      type: SourceType.media,
      price: 100.0,
    ),
    SourceData(
      id: "deskpc_usb_hdmi",
      name: "DeskPC - USB - or HDMI",
      assetPath: "assets/images/products/laptop.png",
      connectionType: SourceConnectionType.usb,
      type: SourceType.media,
      price: 100.0,
    ),
  ];

  static SourceConnectionType getSourceConnectionType(String id) {
    //search both microphone list and media list and return type
    for (SourceData item in <SourceData>[...microphoneItems, ...mediaSourceItems]) {
      if (item.id == id) {
        return item.connectionType;
      }
    }

    return SourceConnectionType.analogInput;
  }

  static SourceType getSourceType(String id) {
    //search both microphone list and media list and return type
    for (SourceData item in <SourceData>[...microphoneItems, ...mediaSourceItems]) {
      if (item.id == id) {
        return item.type;
      }
    }

    return SourceType.mic;
  }

  static const List<SourceData> demoSources = <SourceData>[
    SourceData(
      assetPath: 'assets/images/products/mic1.png',
      name: 'Microphone',
      id: 'MIC01',
      type: SourceType.mic,
      connectionType: SourceConnectionType.analogInput,
      price: 100.0,
    ),
    SourceData(
      assetPath: 'assets/images/products/dvdplayer.png',
      name: 'Music Player',
      id: 'LINE01',
      type: SourceType.media,
      connectionType: SourceConnectionType.analogInput,
      price: 150.0,
    ),
    SourceData(
      assetPath: 'assets/icons/aes67.png',
      name: 'AES67 Input',
      id: 'AES01',
      type: SourceType.media,
      connectionType: SourceConnectionType.aes67input,
      price: 200.0,
    ),
    SourceData(
      assetPath: 'assets/icons/bluetooth.png',
      name: 'Bluetooth Input',
      id: 'BLUETOOTH01',
      type: SourceType.media,
      connectionType: SourceConnectionType.bluetooth,
      price: 0.0,
    ),
  ];
}

class ControllerData extends DeviceComponent {
  final String sku;

  const ControllerData({
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

class SwitchData extends DeviceComponent {
  const SwitchData({
    required super.assetPath,
    required super.name,
    required super.id,
    required super.price,
  });

  static const List<SwitchData> demoSwitchs = <SwitchData>[
    SwitchData(
      assetPath: 'assets/images/products/rack2.png',
      name: 'Switch 1',
      id: '1',
      price: 1000.0,
    ),
    SwitchData(
      assetPath: 'assets/images/products/rack1.png',
      name: 'Switch 2',
      id: '2',
      price: 2000.0,
    ),
  ];
}
