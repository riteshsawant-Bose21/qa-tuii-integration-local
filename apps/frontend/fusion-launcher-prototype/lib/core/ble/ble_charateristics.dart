import 'package:flutter_blue_plus/flutter_blue_plus.dart';


import 'ble_connection_manager.dart';
import 'ble_helper.dart';

class BleCharacteristics {
  static DeviceIdentifier getRemoteId() {
    final String remoteId = BleConnectionManager().getDeviceRemoteId()!;
    return DeviceIdentifier(remoteId);
  }

  static BluetoothCharacteristic getCharacteristic({
    required Characteristics characteristicsName,
    required String remoteId,
  }) {
    switch (characteristicsName) {
      case Characteristics.fusionControl:
        return getSensorCharacteristic(remoteId);
    }
  }

  static BluetoothCharacteristic getSensorCharacteristic(String remoteId) {
    return BluetoothCharacteristic(
      remoteId: DeviceIdentifier(remoteId),
      serviceUuid: ServiceUUIDs.getUUID(Services.fusion),
      characteristicUuid: CharacteristicUUIDs.getUUID(Characteristics.fusionControl),
    );
  }
}
