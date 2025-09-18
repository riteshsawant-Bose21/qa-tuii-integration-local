import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../models/device_item_model.dart';

enum DeviceType {
  speakers,
  sources,
  endpoints,
  amplifiers,
  dsp,
  controllers,
  rack,
}

extension DeviceTypeExtension on DeviceType {
  String get name {
    switch (this) {
      case DeviceType.speakers:
        return 'Speakers';
      case DeviceType.sources:
        return 'Sources';
      case DeviceType.endpoints:
        return 'Endpoints';
      case DeviceType.amplifiers:
        return 'Amplifiers';
      case DeviceType.dsp:
        return 'DSPs';
      case DeviceType.controllers:
        return 'Controllers';
      case DeviceType.rack:
        return 'Rack';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.speakers:
        return Icons.speaker;
      case DeviceType.sources:
        return Icons.mic;
      case DeviceType.endpoints:
        return Icons.hub_outlined;
      case DeviceType.amplifiers:
        return Icons.amp_stories;
      case DeviceType.dsp:
        return Icons.dns_outlined;
      case DeviceType.controllers:
        return Icons.tune;
      case DeviceType.rack:
        return Icons.tune;
    }
  }

  bool get hasAddButton {
    return this == DeviceType.sources || this == DeviceType.rack;
  }

  int get index {
    return DeviceType.values.indexOf(this);
  }
}

class DevicesPanel extends StatefulWidget {
  final Function() onProductSelected;

  const DevicesPanel({
    super.key,
    required this.onProductSelected,
  });

  @override
  State<DevicesPanel> createState() => _DevicesPanelState();
}

class _DevicesPanelState extends State<DevicesPanel> {
  // Define device items using the model
  static const List<DeviceItemModel> _microphoneItems = <DeviceItemModel>[
    DeviceItemModel(sku: "gooseneck", name: "Gooseneck", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "hanging", name: "Hanging", image: "assets/images/products/hanging_mic.png"),
    DeviceItemModel(sku: "condenser", name: "Condenser", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "dynamic", name: "Dynamic", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "shotgun", name: "Shotgun", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "pzm", name: "PZM", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "lavalier", name: "Lavalier", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "headset", name: "Headset", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "handheld", name: "Handheld", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "beltpack", name: "Beltpack", image: "assets/images/products/mic1.png"),
    DeviceItemModel(sku: "paging", name: "Paging", image: "assets/images/products/paging_mic.png"),
  ];

  static const List<DeviceItemModel> _mediaSourceItems = <DeviceItemModel>[
    DeviceItemModel(sku: "generic_mono", name: "Generic Mono", image: "assets/images/products/dvdplayer.png"),
    DeviceItemModel(sku: "generic_stereo", name: "Generic Stereo", image: "assets/images/products/dvdplayer.png"),
    DeviceItemModel(sku: "cd", name: "CD", image: "assets/images/products/dvdplayer.png"),
    DeviceItemModel(sku: "sat_cable_hdmi", name: "Sat/Cable - HDMI", image: "assets/images/products/hdmi.png"),
    DeviceItemModel(sku: "media_player", name: "Media Player", image: "assets/images/products/dvdplayer.png"),
    DeviceItemModel(sku: "tuner", name: "Tuner", image: "assets/images/products/dvdplayer.png"),
    DeviceItemModel(sku: "dvd_hdmi", name: "DVD - HDMI", image: "assets/images/products/hdmi.png"),
    DeviceItemModel(sku: "bluray_hdmi", name: "BluRay HDMI", image: "assets/images/products/hdmi.png"),
    DeviceItemModel(sku: "laptop_usb_hdmi", name: "Laptop - USB - or HDMI", image: "assets/images/products/laptop.png"),
    DeviceItemModel(sku: "deskpc_usb_hdmi", name: "DeskPC - USB - or HDMI", image: "assets/images/products/laptop.png"),
  ];

  void goToDevicePlacementMode() {
    widget.onProductSelected();
  }

  static const List<String> rackOptions = <String>[
    '4U',
    '8U',
    '12U',
    '24U',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return Container(
          margin: const EdgeInsets.only(left: 10),
          child: Column(
            children:
                DeviceType.values.map((DeviceType deviceType) {
                  return _buildSubItem(
                    deviceType,
                    isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == deviceType.index,
                    onTap: () {
                      if (deviceType != DeviceType.sources && deviceType != DeviceType.rack) {
                        goToDevicePlacementMode();
                      }
                      print("Device type selected: ${deviceType.name}, index: ${deviceType.index}");
                      serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(deviceType.index);
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSubItem(
    DeviceType deviceType, {
    bool isSelected = false,
    required Function() onTap,
  }) {
    return Stack(
      children: <Widget>[
        Container(
          color: isSelected ? Colors.grey[100] : Colors.transparent,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            leading: Icon(
              deviceType.icon,
              size: 14,
              color: Colors.black87,
            ),
            title: FusionAppText(
              text: deviceType.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            trailing: (deviceType.hasAddButton && isSelected) ? _buildAddButton(deviceType) : null,
            onTap: onTap,
          ),
        ),
        if (isSelected)
          Container(
            width: 4,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton(DeviceType deviceType) {
    return SizedBox(
      child: PopupMenuButton<DeviceItemModel>(
        icon: const Icon(
          Icons.add,
          size: 14,
          color: Colors.black87,
        ),
        constraints: const BoxConstraints(
          maxHeight: 500,
          maxWidth: 320,
        ),
        onSelected: (DeviceItemModel selectedItem) {
          final ProductQueryModel product = ProductQueryModel(
            name: selectedItem.name,
            price: 0.0,
            image: selectedItem.image,
            type: deviceType == DeviceType.sources ? ProductType.sources : ProductType.racks,
            sku: selectedItem.sku,
          );

          serviceLocator<ProjectViewModel>().setSelectedProductToAdd(product);
        },
        color: Colors.white,
        itemBuilder: (BuildContext context) {
          if (deviceType == DeviceType.sources) {
            return <PopupMenuEntry<DeviceItemModel>>[
              const PopupMenuItem<DeviceItemModel>(
                enabled: false,
                child: Text(
                  'MICROPHONES',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
                ),
              ),
              ..._microphoneItems.map(
                (DeviceItemModel item) => PopupMenuItem<DeviceItemModel>(
                  height: 30,
                  value: item,
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        item.image,
                        height: 14,
                        width: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<DeviceItemModel>(
                enabled: false,
                child: Text(
                  'MEDIA SOURCES',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
                ),
              ),
              ..._mediaSourceItems.map(
                (DeviceItemModel item) => PopupMenuItem<DeviceItemModel>(
                  height: 30,
                  value: item,
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        item.image,
                        height: 14,
                        width: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          } else if (deviceType == DeviceType.rack) {
            return <PopupMenuEntry<DeviceItemModel>>[
              const PopupMenuItem<DeviceItemModel>(
                enabled: false,
                child: Text(
                  'RACK OPTIONS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              ...rackOptions.map(
                (String option) => PopupMenuItem<DeviceItemModel>(
                  height: 30,
                  value: DeviceItemModel(
                    sku: option.toLowerCase(),
                    name: '$option Rack',
                    image: 'assets/images/products/rack.png',
                  ),
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/images/products/rack.png',
                        height: 14,
                        width: 14,
                      ),
                      const SizedBox(width: 8),
                      Text('$option Rack'),
                    ],
                  ),
                ),
              ),
            ];
          }
          return <PopupMenuEntry<DeviceItemModel>>[];
        },
      ),
    );
  }
}
