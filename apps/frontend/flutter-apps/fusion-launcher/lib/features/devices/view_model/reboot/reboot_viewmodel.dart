import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'reboot_viewmodel_state.dart';

class RebootViewmodelCubit extends Cubit<RebootViewmodelState> {
  final FusionDeviceService fusionDeviceService;

  RebootViewmodelCubit({required this.fusionDeviceService}) : super(RebootViewmodelInitial());

  /// Total time to wait for the device to come back online after reboot.
  static const Duration _onlineTimeout = Duration(seconds: 120);

  /// Delay between successive `getAvailableDevicesOnNetwork` polls while waiting
  /// for the device to come back online.
  static const Duration _pollInterval = Duration(seconds: 3);

  /// Initial delay after the reboot API call returns, to give the device time to
  /// actually go offline before we start polling for it.
  static const Duration _initialPollDelay = Duration(seconds: 10);

  /// Triggers a `/cluster/reboot` for the device cluster at [vip] and waits
  /// (up to [_onlineTimeout]) for [deviceId] to reappear in the response of
  /// `getAvailableDevicesOnNetwork`.
  ///
  /// Returns `true` if the device came back online before the timeout, and
  /// `false` otherwise. Also emits [RebootViewmodelLoading], then either
  /// [RebootViewmodelSuccess] or [RebootViewmodelFailure].
  Future<bool> rebootDevice({required String vip, required String deviceId}) async {
    emit(RebootViewmodelLoading(deviceId: deviceId));
    try {
      final ResponseCallback<dynamic> rebootResponse = await fusionDeviceService.rebootCluster(
        vip: vip,
        deviceId: deviceId,
      );
      if (!rebootResponse.success) {
        emit(RebootViewmodelFailure(deviceId: deviceId, message: rebootResponse.message));
        return false;
      }

      final bool backOnline = await _waitForDeviceBackOnline(vip: vip, deviceId: deviceId);
      if (backOnline) {
        emit(RebootViewmodelSuccess(deviceId: deviceId));
        return true;
      }

      emit(
        RebootViewmodelFailure(
          deviceId: deviceId,
          message: 'Device did not come back online within ${_onlineTimeout.inSeconds} seconds.',
        ),
      );
      return false;
    } catch (e) {
      log('RebootViewmodelCubit.rebootDevice error: $e');
      emit(RebootViewmodelFailure(deviceId: deviceId, message: e.toString()));
      return false;
    }
  }

  Future<bool> _waitForDeviceBackOnline({required String vip, required String deviceId}) async {
    // Give the device time to go offline before we start polling.
    final DateTime delayStart = DateTime.now();
    log('RebootViewmodelCubit: starting initial poll delay of ${_initialPollDelay.inSeconds}s for $deviceId at $delayStart');
    await Future<void>.delayed(_initialPollDelay);
    final DateTime delayEnd = DateTime.now();
    final int elapsedMs = delayEnd.difference(delayStart).inMilliseconds;
    log(
      'RebootViewmodelCubit: initial poll delay finished for $deviceId at $delayEnd '
      '(elapsed=${elapsedMs}ms, expected>=${_initialPollDelay.inMilliseconds}ms, '
      'respected=${elapsedMs >= _initialPollDelay.inMilliseconds})',
    );
    assert(
      elapsedMs >= _initialPollDelay.inMilliseconds,
      'Initial poll delay did not honor ${_initialPollDelay.inSeconds}s (elapsed=${elapsedMs}ms)',
    );

    final DateTime deadline = DateTime.now().add(_onlineTimeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(
          ip: vip,
        );
        if (response.success) {
          final List<FusionNetworkDevice> devices = response.data ?? <FusionNetworkDevice>[];
          final bool found = devices.any((FusionNetworkDevice d) => d.id == deviceId);
          if (found) {
            return true;
          }
        }
      } catch (e) {
        log('RebootViewmodelCubit._waitForDeviceBackOnline poll error: $e');
      }
      await Future<void>.delayed(_pollInterval);
    }
    return false;
  }
}
