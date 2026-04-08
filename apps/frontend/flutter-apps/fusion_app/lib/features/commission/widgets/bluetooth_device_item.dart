import 'package:flutter/material.dart';
import 'package:fusion_app/features/commission/models/bluetooth_device_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
class BluetoothDeviceItem extends StatelessWidget {
  final BluetoothDeviceModel device;
  final VoidCallback onTap;

  const BluetoothDeviceItem({super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = device.selected;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.elevation2
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:context.colorScheme.strokeLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Selection indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.iconDefault,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),

            const SizedBox(width: 12),

            /// Device name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    device.name,
                    style: context.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                      color:context.colorScheme.textPrimary,
                    ),
                  ),
                  Text(
                    device.ipAddress!,
                    style: context.textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w400,
                      color:context.colorScheme.textBody,
                    ),
                  ),
                ],
              ),
            ),

            /// Blink icon
            Icon(
              Icons.lightbulb,
              color: false
                  ? context.colorScheme.primary
                  : context.colorScheme.iconDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
