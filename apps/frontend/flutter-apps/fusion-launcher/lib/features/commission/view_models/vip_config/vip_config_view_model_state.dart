part of 'vip_config_view_model.dart';

@immutable
sealed class VipConfigViewModelState {
  const VipConfigViewModelState();
}

final class VipConfigInitial extends VipConfigViewModelState {
  const VipConfigInitial();
}

final class VipConfigVerifying extends VipConfigViewModelState {
  const VipConfigVerifying();
}

final class VipConfigSuccess extends VipConfigViewModelState {
  final String vip;
  const VipConfigSuccess(this.vip);
}

final class VipConfigError extends VipConfigViewModelState {
  final String message;
  const VipConfigError(this.message);
}
