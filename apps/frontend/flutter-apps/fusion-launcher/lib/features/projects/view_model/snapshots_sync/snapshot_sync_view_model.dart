import 'package:bloc/bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

part 'snapshot_sync_view_model_state.dart';

class SnapshotSyncViewModel extends Cubit<SnapshotSyncViewModelState> {
  SnapshotSyncViewModel({required this.snapshotActivateService}) : super(SnapshotSyncViewModelInitial());

  final SnapshotActivateService snapshotActivateService;
}
