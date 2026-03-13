import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/commission/models/bluetooth_device_model.dart';
import 'package:fusion_app/features/commission/widgets/bluetooth_device_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_lib/fusion_lib.dart';

class BluetoothAvailableScreen extends StatefulWidget {

  List<BluetoothDeviceModel> devices;
  BluetoothAvailableScreen({super.key, required this.devices});

  @override
  State<BluetoothAvailableScreen> createState() =>
      _BluetoothAvailableScreenState();
}

class _BluetoothAvailableScreenState extends State<BluetoothAvailableScreen> {
  void _selectDevice(int index) {
    setState(() {
      widget.devices = widget.devices
          .asMap()
          .entries
          .map(
            (e) => e.key == index
                ? e.value.copyWith(selected: true)
                : e.value.copyWith(selected: false),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Bluetooth Devices',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                child:  Icon(Icons.refresh, color:context.colorScheme.onPrimary),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'You can use Blink to confirm the correct device',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          /// Devices list
          ...widget.devices.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BluetoothDeviceItem(
                device: entry.value,
                onTap: () => _selectDevice(entry.key),
              ),
            ),
          ),

          const Spacer(),

          /// CTA Button
          CustomButton(
            enabled:  ValueNotifier(widget.devices.any((d) => d.selected)),
            buttonText: 'Send Wifi Credentials',
            onPressed: () {
              Navigator.pushNamed(context, Routes.configureWifiCreds);
            },
          )
        ],
      ),
    );
  }
}
