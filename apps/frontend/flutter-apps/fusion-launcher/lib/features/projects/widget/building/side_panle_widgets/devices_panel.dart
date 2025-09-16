import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../models/device_item_model.dart';

class DevicesPanel extends StatefulWidget {
  final ExpansibleController productsController;

  const DevicesPanel({
    super.key,
    required this.productsController,
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
    widget.productsController.expand();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(left: 10),
          // color: Colors.grey[50],
          child: Column(
            children: <Widget>[
              _buildSubItem(
                Icons.speaker,
                'Speaker',
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 0,
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(0);
                },
              ),
              _buildSubItem(
                Icons.mic,
                'Sources',
                isSource: true,
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 1,
                onTap: () {
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(1);
                },
              ),
              _buildSubItem(
                Icons.tune,
                'Controllers',
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 2,
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(2);
                },
              ),
              _buildSubItem(
                Icons.hub_outlined,
                'Endpoints',
                onTap: () {},
              ),
              _buildSubItem(
                Icons.dns_outlined,
                'Endpoints',
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    bool isSource = false,
    required Function() onTap,
  }) {
    return Stack(
      children: <Widget>[
        Container(
          // margin: const EdgeInsets.only(bottom: 2),
          //if selected is true change background color to light blue
          color: isSelected ? Colors.grey[100] : Colors.transparent,

          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            leading: Icon(
              icon,
              size: 14,
              color: Colors.black87,
            ),
            title: FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),

            trailing: (isSource && isSelected) ? _buildAddButton() : null,
            onTap: () {
              onTap();
            },
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

  Widget _buildAddButton() {
    return SizedBox(
      child: PopupMenuButton<DeviceItemModel>(
        icon: const Icon(
          Icons.add,
          size: 14,
          color: Colors.black87,
        ),
        constraints: const BoxConstraints(
          maxHeight: 400,
          maxWidth: 300,
        ),
        onSelected: (DeviceItemModel selectedItem) {
          final ProductQueryModel product = ProductQueryModel(
            name: selectedItem.name,
            price: 0.0,
            image: selectedItem.image,
            type: ProductType.sources,
            sku: selectedItem.sku,
          );

          serviceLocator<ProjectViewModel>().setSelectedProductToAdd(product);
        },
        color: Colors.white,
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<DeviceItemModel>>[
              const PopupMenuItem<DeviceItemModel>(
                enabled: false,
                child: Text(
                  'MICROPHONES',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                        // color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(item.name),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<DeviceItemModel>(
                enabled: false,
                child: Text(
                  'MEDIA SOURCES',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                        // color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(item.name),
                    ],
                  ),
                ),
              ),
            ],
      ),
    );
  }
}
