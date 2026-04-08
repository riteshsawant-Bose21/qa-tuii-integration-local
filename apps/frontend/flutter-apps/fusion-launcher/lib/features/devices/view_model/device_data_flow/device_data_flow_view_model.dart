import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

part 'device_data_flow_view_model_state.dart';

class DeviceDataFlowViewModel extends Cubit<DeviceDataFlowViewModelState> {
  DeviceDataFlowViewModel() : super(DeviceDataFlowViewModelInitial());

  List<DeviceConnectionInfo> getSourceConnections({required String dspId}) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    final List<WiringConnectionModel>? connections =
        projectViewModel.getConnectionForDevice(deviceId: dspId)?.where((WiringConnectionModel connection) => connection.type.inDspInputSection).toList();

    if (connections == null) {
      return <DeviceConnectionInfo>[];
    }

    return connections
        .map((WiringConnectionModel connection) {
          final HardwareComponent? sourceDevice = projectViewModel.getHardware(
            hardwareId: connection.deviceId == dspId ? connection.targetDeviceId : connection.deviceId,
          );
          final HardwareComponent? dsp = projectViewModel.getHardware(hardwareId: dspId);
          if (sourceDevice == null) {
            return null;
          }

          PortData? dspPort = dsp?.inputPortsData.firstWhereOrNull(
            (PortData port) => (port.id == connection.portId) || (port.id == connection.targetPortId),
          );

          dspPort ??= dsp?.communicationPorts.firstWhereOrNull(
            (PortData port) => (port.id == connection.portId) || (port.id == connection.targetPortId),
          );

          if (dspPort == null) {
            return null;
          }

          return DeviceConnectionInfo(
            deviceId: sourceDevice.id,
            deviceName: sourceDevice.name,
            connectedPortName: connection.type == ConnectionType.dsp ? "Line in ${dspPort.name}" : dspPort.name,
            connectionType: connection.type,
          );
        })
        .whereType<DeviceConnectionInfo>()
        .toList();
  }

  List<DeviceConnectionInfo> getOutputConnects({required String dspId}) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    final List<WiringConnectionModel>? connections =
        projectViewModel.getConnectionForDevice(deviceId: dspId)?.where((WiringConnectionModel connection) => connection.type.inDspOutputSection).toList();

    if (connections == null) {
      return <DeviceConnectionInfo>[];
    }

    return connections
        .map((WiringConnectionModel connection) {
          final HardwareComponent? amplifier = projectViewModel.getHardware(
            hardwareId: connection.deviceId == dspId ? connection.targetDeviceId : connection.deviceId,
          );

          if (amplifier == null) {
            return null;
          }

          final PortData? matchedAmpPort = amplifier.inputPortsData.firstWhereOrNull(
            (PortData port) => (port.id == connection.portId || port.id == connection.targetPortId),
          );
          if (matchedAmpPort == null) {
            return null;
          }
          final int portNum = matchedAmpPort.portNumber;

          final List<PortData> outPutPorts = amplifier.outputPortsData;

          final PortData? ampOutputPort = outPutPorts.firstWhereOrNull(
            (PortData port) => (port.portNumber == portNum),
          );

          if (ampOutputPort == null) {
            return null;
          }

          final List<WiringConnectionModel>? amplifierConnections = projectViewModel.getConnectionForDevice(deviceId: amplifier.id);

          if (amplifierConnections == null) {
            return null;
          }

          final WiringConnectionModel? circuitConnection = amplifierConnections.firstWhereOrNull(
            (WiringConnectionModel conn) => conn.type == ConnectionType.circuit && (conn.portId == ampOutputPort.id || conn.targetPortId == ampOutputPort.id),
          );

          if (circuitConnection == null) {
            return null;
          }
          final String circuitId = circuitConnection.deviceId == amplifier.id ? circuitConnection.targetDeviceId : circuitConnection.deviceId;

          final CircuitModel? targetCircuit = projectViewModel.getCircuitById(
            circuitId: circuitId,
          );
          final HardwareComponent? dsp = projectViewModel.getHardware(hardwareId: dspId);

          if (targetCircuit == null) {
            return null;
          }

          PortData? dspPort = dsp?.outputPortsData.firstWhereOrNull(
            (PortData port) => (port.id == connection.portId) || (port.id == connection.targetPortId),
          );

          dspPort ??= dsp?.communicationPorts.firstWhereOrNull(
            (PortData port) => (port.id == connection.portId) || (port.id == connection.targetPortId),
          );

          if (dspPort == null) {
            return null;
          }

          return DeviceConnectionInfo(
            deviceId: targetCircuit.id,
            deviceName: targetCircuit.name,
            connectedPortName: "Line out ${dspPort.name}",
            connectionType: connection.type,
          );
        })
        .whereType<DeviceConnectionInfo>()
        .toList();
  }
}

class DeviceConnectionInfo {
  final String deviceId;
  final String deviceName;
  final String connectedPortName;
  final ConnectionType connectionType;

  DeviceConnectionInfo({
    required this.deviceId,
    required this.deviceName,
    required this.connectedPortName,
    required this.connectionType,
  });
}
