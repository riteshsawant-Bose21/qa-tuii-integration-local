import 'dart:ui';

import 'package:flutter/foundation.dart';
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
        SplLoadingState(panelData: const SplPanelData(), listeningAreas: <ListeningArea>[], relativeData: null),
      ) {
    _initialize();
  }

  final SplRangeController splRangeController = SplRangeController();

  Future<void> _initialize() async {
    await IsolatedMaceCalculationManager.instance.start();
    final SplPanelData currentPanelData = splRangeController.getPanelData();
    emit(SplLoadedState(panelData: currentPanelData, listeningAreas: state.listeningAreas, relativeData: state.relativeData));
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

  bool canCalculateSPL() {
    final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
    if (currentFloorIndex == -1) return false;

    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
    final List<ListeningArea> floorListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (floorListeningAreas.isEmpty) return false;

    final List<Speaker> speakers = List<Speaker>.from(
      serviceLocator<ProjectViewModel>().getHardwareInFloorWithPosition(floorId: currentFloor.id).whereType<Speaker>(),
    );
    if (speakers.isEmpty) return false;

    return true;
  }

  Future<void> autoCalculateSpl() async {
    if (state.panelData.autoCalculate) {
      return calculateSPL();
    }
  }

  Future<void> calculateSPL() async {
    // print(
    //   "Calculating SPL with panel data: ${state.panelData}, current listening areas: ${state.listeningAreas.length}",
    // );
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

    final List<ListeningArea> nonZeroAreas = <ListeningArea>[];
    for (final ListeningArea area in surfaces) {
      final Path path = Path()..addPolygon(area.vertices.map((FusionCanvasPoint e) => e.position).toList(), true);

      final Size size = path.getBounds().size;
      if (size.width > 0 && size.height > 0) {
        nonZeroAreas.add(area);
      } else {
        // print("Skipping area with zero size: ${area.id}, size: $size");
      }
    }
    emit(SplLoadingState(listeningAreas: state.listeningAreas, panelData: state.panelData, relativeData: state.relativeData));
    await IsolatedMaceCalculationManager.instance.calculateSpl(
      speakers: speakers,
      surfaces: nonZeroAreas,
      walls: serviceLocator<ProjectViewModel>().getWallsForFloor(floorId: currentFloor.id),
      resolutionSpacing: state.panelData.getResolutionSpacing(),
    );

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
    print("Current Calculations length: ${currentCalcs.length}");
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

    print("Applying SPL data for ${toApply.length} calculations");
    for (final SPLCalculation calc in toApply) {
      final List<Offset> pts = calc.surface.getFieldPoints(
        state.panelData.getResolutionSpacing(),
      );
      // final List<double> relative = await IsolatedMaceCalculationManager.instance.getRelativeSpls(calc.spl);
      // print("Old: ${calc.spl.first}.  New: ${relative.first}");
      floorListeningAreas
          .firstWhere((ListeningArea area) => area.id == calc.surface.id)
          .setSplData(
            pts,
            calc.spl,
          );
    }
    final num average = await compute(
      _calculateAverageSpl,
      floorListeningAreas.map((ListeningArea e) => e.splData?.splValues ?? <double>[]).expand((List<double> e) => e).toList(),
    );
    print("average: $average");
    emit(state.copyWith(listeningAreas: floorListeningAreas, relativeData: SplRelativeData(average: average)));
  }

  @override
  Future<void> close() async {
    await IsolatedMaceCalculationManager.instance.stop();
    return super.close();
  }

  void startLoading() {
    emit(LiveSplState(panelData: state.panelData, listeningAreas: state.listeningAreas, relativeData: state.relativeData));
  }

  void stopLoading() {
    emit(SplLoadedState(panelData: state.panelData, listeningAreas: state.listeningAreas, relativeData: state.relativeData));
  }
}

num _calculateAverageSpl(List<double> splValues) {
  if (splValues.isEmpty) return 0;
  final double sum = splValues.reduce((double a, double b) => a + b);
  return sum / splValues.length;
}

abstract class SplState {
  final SplPanelData panelData;
  final List<ListeningArea> listeningAreas;
  final SplRelativeData? relativeData;

  SplState({required this.panelData, required this.listeningAreas, this.relativeData});

  SplState copyWith({
    SplPanelData? panelData,
    List<ListeningArea>? listeningAreas,
    SplRelativeData? relativeData,
  }) {
    return SplLoadedState(
      panelData: panelData ?? this.panelData,
      listeningAreas: listeningAreas ?? this.listeningAreas,
      relativeData: relativeData ?? this.relativeData,
    );
  }
}

class SplLoadingState extends SplState {
  SplLoadingState({required super.panelData, required super.listeningAreas, required super.relativeData});
}

class SplLoadedState extends SplState {
  SplLoadedState({required super.panelData, required super.listeningAreas, required super.relativeData});
}

class LiveSplState extends SplState {
  LiveSplState({required super.panelData, required super.listeningAreas, required super.relativeData});
}

class SplRelativeData {
  final num average;

  SplRelativeData({required this.average});
}
