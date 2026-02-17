import 'package:fusion_lib/fusion_lib.dart';

abstract class DeviceScanState {}

class DeviceScanInitial extends DeviceScanState {}

class DeviceScanLoading extends DeviceScanState {}

class DeviceScanLoaded extends DeviceScanState {
  final List<MdnsDevice> devices;
  DeviceScanLoaded(this.devices);
}
