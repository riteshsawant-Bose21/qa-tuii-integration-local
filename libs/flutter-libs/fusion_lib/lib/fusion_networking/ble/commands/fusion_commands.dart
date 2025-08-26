import '../../../models/response_callback.dart';

abstract class FusionBleCommands {
  Future<ResponseCallback<dynamic>> blinkLed();

  // Future<ResponseCallback<dynamic>> getFusionDeviceDetails(String deviceId);

  Future<ResponseCallback<dynamic>> updateFusionVIP(String vip);

  Future<ResponseCallback<dynamic>> checkVipConfiguration();
}
