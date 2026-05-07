import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../software_update/software_update_service.dart';

class SoftwareUpdateCubit extends Cubit<UpdateState> {
  final FusionNetworkClient networkClient;
  final SoftwareUpdateService _svc;
  late final StreamSubscription<UpdateState> _sub;

  factory SoftwareUpdateCubit({required FusionNetworkClient networkClient}) {
    final SoftwareUpdateService svc = _ensureServiceInitialized(networkClient);
    return SoftwareUpdateCubit._(networkClient, svc);
  }

  SoftwareUpdateCubit._(this.networkClient, this._svc) : super(_svc.state) {
    _sub = _svc.stream.listen(emit);
  }

  static SoftwareUpdateService _ensureServiceInitialized(FusionNetworkClient networkClient) {
    try {
      return SoftwareUpdateService.instance;
    } on AssertionError {
      final String virtualIp = serviceLocator<ProjectViewModel>().virtualIP ?? '';

      final SoftwareUpdateConfig config = SoftwareUpdateConfig(
        virtualIp: virtualIp,
        rollbackUrl: null,
      );

      SoftwareUpdateService.init(config, networkClient);
      return SoftwareUpdateService.instance;
    }
  }

  // ── Button actions (thin delegates — zero logic here) ───────────────────────
  Future<void> checkForUpdates() => _svc.checkForUpdates();
  void confirmDownload() => _svc.confirmDownload();
  void confirmInstall() => _svc.confirmInstall();
  void pauseDownload() => _svc.pauseDownload();
  void resumeDownload() => _svc.resumeDownload();
  Future<void> cancel() => _svc.cancel();
  Future<void> retryPhase() => _svc.retryPhase();
  Future<void> rollback() => _svc.rollback();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
