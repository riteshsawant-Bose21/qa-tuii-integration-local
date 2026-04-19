import 'package:bloc/bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

part 'snapshot_sync_view_model_state.dart';

class SnapshotSyncViewModel extends Cubit<SnapshotSyncViewModelState> {
  SnapshotSyncViewModel({required this.snapshotActivateService}) : super(SnapshotSyncViewModelInitial());

  final SnapshotActivateService snapshotActivateService;

  Future<ResponseCallback<bool>> updateSnapshotAndSceneSet() async {
    try {
      final String vip = serviceLocator<ProjectViewModel>().virtualIP ?? "";
      final SnapshotsRequestDto? snapshotList = serviceLocator<ProjectViewModel>().getSnapshotsRequestDtoData();
      final SceneSetRequestDto? sceneSetList = serviceLocator<ProjectViewModel>().getSceneSetRequestDtoData();

      return await snapshotActivateService.updateSnapshotAndSceneSet(
        vip: vip,
        snapshotList: snapshotList,
        sceneSetList: sceneSetList,
      );
    } catch (e) {
      return ResponseCallback<bool>.failure('Failed to update snapshot and scene set: $e');
    }
  }
}
