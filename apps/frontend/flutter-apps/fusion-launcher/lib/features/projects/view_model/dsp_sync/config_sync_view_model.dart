import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/service/dro/dro_config_service.dart';

part 'config_sync_view_model_state.dart';

class ConfigSyncViewModel extends Cubit<ConfigSyncState> {
  final DroConfigService droConfigService;
  final FusionConfigSyncService fusionConfigSyncService;

  String get droServerUrl => serviceLocator<FusionPreferences>().droServerUrl;

  ConfigSyncViewModel({
    required this.droConfigService,
    required this.fusionConfigSyncService,
  }) : super(ConfigSyncInitial());

  String get vip => serviceLocator<ProjectViewModel>().virtualIP ?? "";

  Future<ResponseCallback<DroResponseData>> refineConfigWithDro({
    required DroInputModel droInput,
  }) async {
    emit(ProcessingDataWithDro());
    final ResponseCallback<DroResponseData> response = await droConfigService.getRefinedConfig(
      droInput: droInput,
      droServerUrl: droServerUrl,
    );
    if (response.success) {
      serviceLocator<ProjectViewModel>().updateDroResponse(response.data!.toJson());
      // autoPopulateWiringDetails(droResponseData: response.data!);
      emit(DroResponseReceived(droResponseData: response.data!));
    } else {
      emit(DroProcessingFailed(message: response.message));
    }
    return response;
  }

  //auto populate the wiring details in the fusion dsp based on the dro response
  Future<void> autoPopulateWiringDetails({
    required DroResponseData droResponseData,
  }) async {
    if (droResponseData.result?.ioPorts != null) {
      for (Map<String, dynamic> ioPort in droResponseData.result!.ioPorts!) {
        final String deviceId = ioPort['device_id'];
        final String ioId = ioPort['io_id'];
        final List<int> portNum = List<int>.from(ioPort['port_nums']);
        final String portType = ioPort['port_type'];
        final HardwareComponent? device = serviceLocator<ProjectViewModel>().getHardware(hardwareId: deviceId);
        final HardwareComponent? ioDevice = serviceLocator<ProjectViewModel>().getHardware(hardwareId: ioId);

        switch (portType) {
          case 'io_in_analog':
            // Call the method to update the input port details in the DSP
            //get the device
            if (device != null && ioDevice != null) {
              final WiringConnectionModel wiringConnection = WiringConnectionModel(
                targetDeviceId: deviceId,
                targetPortId: device.inputPortsData[portNum.first - 1].id,
                deviceId: ioId,
                // This would be determined based on your DSP configuration
                portId: ioDevice.outputPortsData.first.id,
                // This would also be determined based on your DSP configuration
                type: ConnectionType.signal,
              );
              serviceLocator<ProjectViewModel>().addWiringConnection(connection: wiringConnection);
            }
            break;
          case 'io_out_analog':
            // Call the method to update the output port details in the DSP

            break;
          default:
            print('Unknown port type: $portType');
        }
      }
    }
  }

  Future<ResponseCallback<bool>> syncConfigWithFusion({
    required DroResponseData droResponseData,
  }) async {
    emit(SyncingConfigWithDsp());
    final ResponseCallback<bool> response = await fusionConfigSyncService.syncConfigToDsp(
      config: <String, dynamic>{
        "devices": droResponseData.result!.devices,
      },
      vip: vip,
    );
    if (response.success) {
      emit(ConfigSyncedWithDsp());
      // initializeTelemetryData();
    } else {
      emit(DroProcessingFailed(message: response.message));
    }
    return response;
  }

  Future<ResponseCallback<bool>> refineAndSyncDataWithDsp({
    required DroInputModel droInput,
  }) async {
    final ResponseCallback<DroResponseData> droResponse = await refineConfigWithDro(droInput: droInput);
    if (!droResponse.success) {
      return ResponseCallback<bool>.failure(droResponse.message);
    }

    final ResponseCallback<bool> syncResponse = await syncConfigWithFusion(
      droResponseData: droResponse.data!,
    );

    if (!syncResponse.success) {
      return ResponseCallback<bool>.failure(syncResponse.message);
    }

    return ResponseCallback<bool>.success(true);
  }

  //test websocket connection to fusion dsp
  StreamSubscription<ResponseCallback<dynamic>>? _telemetrySubscription;

  Future<void> initializeTelemetryData() async {
    final FusionNetworkClient client = serviceLocator<FusionNetworkClient>();
    final String vip = serviceLocator<ProjectViewModel>().virtualIP ?? "";
    await client.connect(vip: vip);
    //stream telemetry data for testing
    _telemetrySubscription = client.responseMessages.listen(
      (ResponseCallback<dynamic> message) {
        debugPrint("######### Received telemetry message ############: ${message.data}");
      },
      onError: (dynamic error) {
        debugPrint("######### Telemetry error ############: $error");
      },
      onDone: () {
        debugPrint("######### Telemetry stream closed ############");
      },
    );
  }

  void disposeTelemetry() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
  }
}
