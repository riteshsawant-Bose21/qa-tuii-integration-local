import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'vip_config_view_model_state.dart';

class VipConfigViewModel extends Cubit<VipConfigViewModelState> {
  VipConfigViewModel() : super(const VipConfigInitial());

  /// Regular expression for a valid IPv4 address (0.0.0.0 – 255.255.255.255).
  static final RegExp ipv4Regex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
    r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  /// Validates the format of an IPv4 address string.
  /// Returns `null` if valid, or an error message if invalid.
  static String? validateIp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IP address is required';
    }
    if (!ipv4Regex.hasMatch(value.trim())) {
      return 'Enter a valid IP address';
    }
    return null;
  }

  /// Validates only the host octet (last part of the IP).
  /// Must be an integer between 1 and 254 (excludes network 0 and broadcast 255).
  static String? validateHostOctet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Host address is required';
    }
    final int? octet = int.tryParse(value.trim());
    if (octet == null || octet < 1 || octet > 254) {
      return 'Enter a value between 1 and 254';
    }
    return null;
  }

  /// Sets the VIP on the target device and then verifies it is reachable.
  ///
  /// 1. POST the VIP to [deviceIp] so the device adopts it.
  /// 2. GET via the new [vip] to confirm it is reachable.
  /// 3. Persist the VIP in [ProjectViewModel] on success.
  Future<void> setVip({required String vip, required String deviceIp}) async {
    emit(const VipConfigVerifying());

    try {
      final FusionNetworkClient networkClient = serviceLocator<FusionNetworkClient>();

      // Step 1 — Tell the device to adopt the VIP.
      final ResponseCallback<dynamic> setResponse = await networkClient.post(
        api: FusionApiEndpoint.fusionDevice,
        baseUrlToOverride: deviceIp,
        additionalPath: "vip/$vip",
        isSecure: false,
      );

      if (!setResponse.success) {
        final String reason = setResponse.message.isNotEmpty ? setResponse.message : 'Device rejected the VIP configuration';
        emit(VipConfigError(reason));
        return;
      }

      // Step 2 — Verify the VIP is reachable.
      final ResponseCallback<dynamic> verifyResponse = await networkClient.get(api: FusionApiEndpoint.fusionDevice, baseUrlToOverride: vip, isSecure: false);

      if (!verifyResponse.success) {
        emit(const VipConfigError('VIP was set but is not reachable. Check your network.'));
        return;
      }

      // Step 3 — All good — persist locally.
      emit(VipConfigSuccess(vip));
    } catch (e) {
      debugPrint('VipConfigViewModel.setVip error: $e');
      emit(VipConfigError('Failed to configure VIP: $e'));
    }
  }

  /// Resets the state so the user can try again.
  void reset() {
    emit(const VipConfigInitial());
  }
}
