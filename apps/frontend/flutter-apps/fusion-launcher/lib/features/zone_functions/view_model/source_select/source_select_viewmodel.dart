import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../projects/view_model/block_data/block_data_viewmodel.dart';

part 'source_select_viewmodel_state.dart';

class SourceSelectViewmodel extends Cubit<SourceSelectViewmodelState> {
  SourceSelectViewmodel() : super(SourceSelectViewmodelInitial());

  StreamSubscription<Map<String, dynamic>?>? _blockDataSubscription;

  // ── WebSocket block-data subscription ──────────────────────────────────────

  /// Subscribes to [BlockDataViewmodel] for live WebSocket updates.
  /// Only processes updates whose blockId matches [functionId] — ignores
  /// unrelated blocks entirely (the `.map` + `.distinct` ensures this).
  void subscribeToBlockData({
    required String functionId,
    required String zoneId,
  }) {
    _blockDataSubscription?.cancel();
    final BlockDataViewmodel blockDataVM = serviceLocator<BlockDataViewmodel>();

    _blockDataSubscription = blockDataVM.stream.map((BlockDataState s) => s.allBlockData[functionId]).distinct().listen((Map<String, dynamic>? blockData) {
      if (blockData == null || isClosed) return;
      _applyBlockDataToProject(
        functionId: functionId,
        zoneId: zoneId,
        data: blockData,
      );
    });
  }

  /// Unsubscribes from [BlockDataViewmodel].
  void unsubscribeFromBlockData() {
    _blockDataSubscription?.cancel();
    _blockDataSubscription = null;
  }

  /// Applies incoming block-data to the local project model.
  /// Handles the `input` parameter which indicates the 1-based selected source.
  void _applyBlockDataToProject({
    required String functionId,
    required String zoneId,
    required Map<String, dynamic> data,
  }) {
    try {
      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
      final ZoneFunctions? function = projectVM.getFunctionById(functionId: functionId);
      if (function == null) return;

      final dynamic rawInput = data['input'];
      if (rawInput == null) return;

      // final int serverInput = (rawInput is num) ? rawInput.toInt() : int.tryParse(rawInput.toString()) ?? -1;
      // if (serverInput < 1) return;
      //
      // final List<Source> sources = projectVM.getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);
      // if (sources.isEmpty) return;
      //
      // final int sourceIdx = serverInput - 1; // server is 1-based
      // if (sourceIdx < 0 || sourceIdx >= sources.length) return;
      //
      // final String resolvedSourceId = sources[sourceIdx].id;
      // if (function.selectedSourceId != resolvedSourceId) {
      //   projectVM.selectSourceForFunction(
      //     functionId: functionId,
      //     sourceId: resolvedSourceId,
      //   );
      // }
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Error applying source-select block data: $e',
      );
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  /// Sends the selected input to the server and updates the local project.
  Future<void> updateInputSelection({
    required ZoneFunctions function,
    required String sourceId,
  }) async {
    try {
      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();

      final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 0;

      if (projectVM.isInControlMode && projectVM.virtualIP != null) {
        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.id,
          parameter: 'input',
          value: index + 1, // server expects 1-based index
        );
      }

      projectVM.selectSourceForFunction(
        functionId: function.id,
        sourceId: sourceId,
      );
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Error updating input selection: $e',
      );
    }
  }

  /// Fetches the latest block data from the server (or WebSocket cache) and
  /// patches the local project model so the UI shows server-authoritative
  /// values on first load.
  Future<void> getSelectedInputInServer({
    required ZoneFunctions function,
    required String zoneId,
  }) async {
    try {
      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
      if (!projectVM.isInControlMode || projectVM.virtualIP == null) return;

      final Map<String, dynamic>? data = await serviceLocator<BlockDataViewmodel>().getBlockData(blockId: function.id);
      if (data == null) return;

      _applyBlockDataToProject(
        functionId: function.id,
        zoneId: zoneId,
        data: data,
      );
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Error fetching selected input from server: $e',
      );
    }
  }

  @override
  Future<void> close() {
    unsubscribeFromBlockData();
    return super.close();
  }
}
