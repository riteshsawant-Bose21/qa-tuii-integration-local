import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/spl_calculation/ffi_constants.dart';
import 'package:fusion_launcher/core/spl_calculation/isolate_mace_calculation_manager.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/spl_calculation/mace_calculation_manager.dart';

class SplViewModel extends Cubit<SplState> {
  SplViewModel()
    : super(
        SplState(panelData: const SplPanelData(), listeningAreas: <ListeningArea>[]),
      ) {
    _initialize();
  }

  final SplRangeController splRangeController = SplRangeController();

  Future<void> _initialize() async {
    await IsolatedMaceCalculationManager.instance.start();
    final SplPanelData currentPanelData = splRangeController.getPanelData();
    emit(state.copyWith(panelData: currentPanelData));
    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: currentPanelData.splLowerDb, autoSave: false);
    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: currentPanelData.splUpperDb, autoSave: false);
  }

  void _updateSPLFromPanelData() {
    final SplPanelData currentPanelData = splRangeController.getPanelData();
    final SplPanelData lastPanelData = state.panelData;
    if (lastPanelData != currentPanelData) {
      // if resolution changed, need to recalculate all SPLs
      if (lastPanelData.resolution != currentPanelData.resolution) {
        emit(state.copyWith(panelData: currentPanelData));
        calculateSPL();
        return;
      }
      emit(state.copyWith(panelData: currentPanelData));
      final Bandwidth maceBandwidth = _mapToMaceBandwidth(currentPanelData.bandwidth);
      final double frequency = currentPanelData.frequency.frequencyValue.toDouble();
      final Weighting weighting = _mapToMaceWeighting(currentPanelData.weighting);
      serviceLocator<ProjectViewModel>().setMinSPL(minSPL: currentPanelData.splLowerDb);
      serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: currentPanelData.splUpperDb);
      updateSpl(maceBandwidth, frequency, weighting, currentPanelData.relative);
    }
  }

  void updatePanelData(SplPanelData value) {
    FusionLogger.log(tag: LogTag.panel, message: value.toString());
    splRangeController.onMappingDataChanged(value);
    _updateSPLFromPanelData();
  }

  Future<void> calculateSPL() async {
    // if (_engine == null) {
    //   debugPrint('calculateSPL: _engine is null');
    //   return;
    // }
    // if (!_floorCanvasController.isShowingSpl.value) {
    //   debugPrint('calculateSPL: isShowingSpl is false');
    //   return;
    // }

    final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
    if (currentFloorIndex == -1) return;

    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];

    final List<ListeningArea> floorListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (floorListeningAreas.isEmpty) return;
    // for (ListeningArea e in floorListeningAreas) {
    //   e.clearSplData();
    // }
    final List<Speaker> speakers = List<Speaker>.from(
      serviceLocator<ProjectViewModel>().getHardwareInFloorWithPosition(floorId: currentFloor.id).whereType<Speaker>(),
    );
    final List<ListeningArea> surfaces = serviceLocator<ProjectViewModel>().getAllDrawnListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    // if (!useIsolateEngine) {
    //   await SPLCalculationManager.calculateSpl(
    //     _engine!,
    //     speakers,
    //     surfaces,
    //     _lastPanelData!.getResolutionSpacing(),
    //   );
    // } else {
    await IsolatedMaceCalculationManager.instance.calculateSpl(
      speakers: speakers,
      surfaces: surfaces,
      resolutionSpacing: state.panelData.getResolutionSpacing(),
    );
    // }

    final SplPanelData currentPanelData = splRangeController.getPanelData();
    final Bandwidth maceBandwidth = _mapToMaceBandwidth(
      currentPanelData.bandwidth,
    );
    final Weighting weighting = _mapToMaceWeighting(currentPanelData.weighting);
    final double frequency = currentPanelData.frequency.frequencyValue.toDouble();
    await updateSpl(
      maceBandwidth,
      frequency,
      weighting,
      currentPanelData.relative,
    );
  }

  Weighting _mapToMaceWeighting(SplWeighting w) {
    switch (w) {
      case SplWeighting.aWeighted:
        return Weighting.a;
      case SplWeighting.cWeighted:
        return Weighting.c;
      case SplWeighting.zWeighted:
        return Weighting.z;
    }
  }

  Bandwidth _mapToMaceBandwidth(SplBandwidth b) {
    switch (b) {
      case SplBandwidth.oneThirdOctave:
        return Bandwidth.oneThirdOctave;
      case SplBandwidth.oneOctave:
        return Bandwidth.oneOctave;
      case SplBandwidth.vocal:
        return Bandwidth.vocalBands;
      case SplBandwidth.allBands:
        return Bandwidth.allBands;
    }
  }

  Future<void> updateSpl(
    Bandwidth bw,
    double frequency,
    Weighting weighting,
    bool relative,
  ) async {
    final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
    if (currentFloorIndex == -1) return;

    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
    final List<ListeningArea> floorListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (floorListeningAreas.isEmpty) return;

    final List<SPLCalculation> toApply = <SPLCalculation>[];

    final Iterable<SPLCalculation> currentCalcs = await IsolatedMaceCalculationManager.instance.currentCalculations();

    for (final SPLCalculation sc in currentCalcs) {
      if (!floorListeningAreas.any((ListeningArea area) => area.id == sc.surface.id)) continue;
      final List<SPLCalculation> updated = await IsolatedMaceCalculationManager.instance.getSplAt(
        fph: sc.fphHandle,
        bandwidth: bw,
        freqHz: (bw == Bandwidth.oneThirdOctave || bw == Bandwidth.oneOctave) ? frequency : 2000,
        weighting: weighting,
        relative: relative,
        resolutionSpacing: state.panelData.getResolutionSpacing(),
      );

      print("[isolate] updateSpl: updated length ${updated.map((SPLCalculation e) => e.spl.length)}");
      toApply.addAll(updated);
    }

    for (final SPLCalculation calc in toApply) {
      final List<Offset> pts = calc.surface.getFieldPoints(
        state.panelData.getResolutionSpacing(),
      );
      floorListeningAreas.firstWhere((ListeningArea area) => area.id == calc.surface.id).setSplData(pts, calc.spl);
    }
    emit(state.copyWith(listeningAreas: floorListeningAreas));
  }

  @override
  Future<void> close() async {
    await IsolatedMaceCalculationManager.instance.stop();
    return super.close();
  }
}

class SplState {
  final SplPanelData panelData;
  final List<ListeningArea> listeningAreas;

  SplState({required this.panelData, required this.listeningAreas});

  SplState copyWith({
    SplPanelData? panelData,
    List<ListeningArea>? listeningAreas,
  }) {
    return SplState(
      panelData: panelData ?? this.panelData,
      listeningAreas: listeningAreas ?? this.listeningAreas,
    );
  }
}
