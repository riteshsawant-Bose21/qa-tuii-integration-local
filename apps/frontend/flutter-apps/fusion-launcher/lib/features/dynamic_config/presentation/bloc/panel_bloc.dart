import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_logger/logger.dart';

import '../../../../core/service_locator.dart';
import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';
import '../../domain/usecases/dispose_panel_usecase.dart';
import '../../domain/usecases/get_panel_data_usecase.dart';
import '../../domain/usecases/get_panel_entity_usecase.dart';
import '../../domain/usecases/get_panel_stream_usecase.dart';
import '../../domain/usecases/initialize_panel_usecase.dart';
import '../../domain/usecases/reset_fusion_data_usecase.dart';
import '../../domain/usecases/send_widget_data_usecase.dart';
import 'panel_bloc_event.dart';
import 'panel_bloc_state.dart';

class PanelBloc extends Bloc<PanelBlocEvent, PanelBlocState> {
  final GetPanelEntityUseCase getPanelEntityUseCase = serviceLocator<GetPanelEntityUseCase>();
  final GetPanelDataUseCase getPanelDataUseCase = serviceLocator<GetPanelDataUseCase>();
  final DisposePanelUseCase disposePanelUseCase = serviceLocator<DisposePanelUseCase>();
  final InitializePanelUseCase initializePanelUseCase = serviceLocator<InitializePanelUseCase>();
  final GetPanelStreamUseCase getPanelDataStreamUseCase = serviceLocator<GetPanelStreamUseCase>();
  final ResetFusionUseCase resetFusionUseCase = serviceLocator<ResetFusionUseCase>();
  final SendWidgetDataUseCase sendWidgetDataUseCase = serviceLocator<SendWidgetDataUseCase>();

  StreamSubscription<Map<String, dynamic>>? _meterSubscription;
  late String _currentPanelNameID;

  PanelBloc() : super(PanelInitialState()) {
    on<InitializePanel>(_onInitializePanel);
    on<GetAllWidgetsValueInAPanel>(_onGetAllWidgetsValueInAPanel);
    on<UpdateServerWithAudioWidgetValue>(_onUpdateServerWithAudioWidgetValue);
    on<UpdateUIWithNewAudioWidgetValue>(_onUpdateUIWithNewAudioWidgetValue);
    on<DisposePanel>(_onDisposePanel);
  }

  @override
  Future<void> close() {
    disposePanelUseCase.call();
    _meterSubscription?.cancel();
    return super.close();
  }

  void _onDisposePanel(DisposePanel event, Emitter<PanelBlocState> emit) {
    FusionLogger.log(tag: LogTag.panel, message: "Disposing PanelBloc and resetting Fusion data.");
    disposePanelUseCase.call();
    _meterSubscription?.cancel();
    emit(PanelInitialState());
  }

  Future<void> _onInitializePanel(InitializePanel event, Emitter<PanelBlocState> emit) async {
    try {
      emit(PanelLoadingState());
      final PanelEntity panel = await getPanelEntityUseCase.call(event.processingBloc);
      _currentPanelNameID = panel.id;
      add(GetAllWidgetsValueInAPanel(panel));

      await initializePanelUseCase.call();
      _startListeningForUIUpdates();
    } catch (e) {
      emit(PanelErrorState('Failed to fetch panel data _onInitializePanel ${e.toString()}'));
    }
  }

  Future<void> _onGetAllWidgetsValueInAPanel(GetAllWidgetsValueInAPanel event, Emitter<PanelBlocState> emit) async {
    try {
      final PanelEntity panel = await getPanelDataUseCase.call(event.panel);
      debugPrint("Panel data fetched: ${panel.listOfAudioWidgets.length} widgets");
      emit(PanelLoadedState(panel));
    } catch (e) {
      emit(PanelErrorState('Failed to fetch panel data _onGetAllWidgetsValueInAPanel ${e.toString()}'));
    }
  }

  Future<void> _onUpdateServerWithAudioWidgetValue(
    UpdateServerWithAudioWidgetValue event,
    Emitter<PanelBlocState> emit,
  ) async {
    if (state is PanelLoadedState) {
      try {
        final AudioWidgetEntity updatedWidgetData = await sendWidgetDataUseCase.call(
          event.audioWidget,
          event.newValue,
        );

        final List<AudioWidgetEntity> updatedWidgets =
            (state as PanelLoadedState).panel.listOfAudioWidgets.map(
              (AudioWidgetEntity widget) {
                if (widget.id == updatedWidgetData.id && widget.name == updatedWidgetData.name) {
                  return widget.copyWith(value: event.newValue);
                }
                return widget;
              },
            ).toList();

        final PanelEntity updatedPanel = PanelEntity(
          id: (state as PanelLoadedState).panel.id,
          name: (state as PanelLoadedState).panel.name,
          algorithmType: (state as PanelLoadedState).panel.algorithmType,
          listOfAudioWidgets: updatedWidgets,
        );

        //FIXME: updates the UI based on server response but doesn't handle error cases
        emit(PanelLoadedState(updatedPanel));
      } catch (e) {
        emit(
          PanelErrorState('Failed to fetch panel data _onUpdateServerWithAudioWidgetValue ${e.toString()}'),
        );
      }
    } else {
      //TODO://
    }
  }

  void _startListeningForUIUpdates() {
    _meterSubscription = getPanelDataStreamUseCase.call().listen(
      (Map<String, dynamic> message) {
        message.forEach((String uiWidgetID, dynamic value) {
          // print("Received ZMQ message for $uiWidgetID with value: $value current panel Name Id $_currentPanelNameID ${uiWidgetID.startsWith(_currentPanelNameID)}" );
          if (uiWidgetID.startsWith(_currentPanelNameID)) {
            FusionLogger.log(tag: LogTag.panel, message: "Received relevant ZMQ message: $message");
            _interpolateAndUpdateMeter(uiWidgetID, value);
          } else {
            // print("discarding ZMQ message for $message as it doesn't match current panel $_currentPanelNameID");
          }
        });
      },
      onError: (dynamic error) {
        FusionLogger.log(tag: LogTag.panel, message: "Error listening to updates: $error");
      },
      onDone: () {
        FusionLogger.log(tag: LogTag.panel, message: "Update stream completed.");
      },
    );
  }

  final Map<String, double> _previousMeterValues = <String, double>{};

  void _interpolateAndUpdateMeter(String uiWidgetID, dynamic value) {
    uiWidgetID = uiWidgetID.split("#")[1];
    if (value is double) {
      double previousValue = value;
      if (_previousMeterValues.containsKey(uiWidgetID)) {
        previousValue = _previousMeterValues[uiWidgetID]!;
      }

      _previousMeterValues[uiWidgetID] = value;

      double elapsed = 0.0;
      final Duration interpolationDuration = const Duration(milliseconds: 100); // Total interpolation duration

      Timer.periodic(const Duration(milliseconds: 16), (Timer timer) {
        if (isClosed) return; // Avoids updating the widget after the bloc is closed
        elapsed += 16.0;
        final double t = (elapsed / interpolationDuration.inMilliseconds).clamp(0.0, 1.0);
        final double interpolatedValue = previousValue + (value - previousValue) * t;
        add(
          UpdateUIWithNewAudioWidgetValue(
            uiWidgetID,
            AudioWidgetValue.from(interpolatedValue, AudioWidgetValue.floatValue),
          ),
        );
        if (t >= 1.0) {
          timer.cancel();
        }
      });
    } else {
      add(UpdateUIWithNewAudioWidgetValue(uiWidgetID, value));
    }
  }

  Future<void> _onUpdateUIWithNewAudioWidgetValue(
    UpdateUIWithNewAudioWidgetValue event,
    Emitter<PanelBlocState> emit,
  ) async {
    if (state is PanelLoadedState) {
      try {
        final List<AudioWidgetEntity> updatedWidgets =
            (state as PanelLoadedState).panel.listOfAudioWidgets.map((AudioWidgetEntity widget) {
              if (widget.name == event.audioWidgetID) {
                return widget.copyWith(value: event.newValue);
              }
              return widget;
            }).toList();

        final PanelEntity updatedPanel = PanelEntity(
          id: (state as PanelLoadedState).panel.id,
          name: (state as PanelLoadedState).panel.name,
          algorithmType: (state as PanelLoadedState).panel.algorithmType,
          listOfAudioWidgets: updatedWidgets,
        );

        emit(PanelLoadedState(updatedPanel));
      } catch (e) {
        emit(
          PanelErrorState('Failed to fetch panel data _onUpdateUIWithNewAudioWidgetValue ${e.toString()}'),
        );
      }
    }
  }

  void processTelemetryMessage(Map<String, dynamic> message) {
    message.forEach((String uiWidgetID, dynamic value) {
      add(UpdateUIWithNewAudioWidgetValue(uiWidgetID, value));
    });
  }
}
