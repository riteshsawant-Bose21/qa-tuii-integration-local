import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fusion_lib.dart';

class GuideShowCaseControllerTexts {
  static const String storageKey = 'is_guide_showcase_step_completed';

  static const String errorLoadingGuideStatusPrefix = 'Error loading guide status:';
  static const String errorSavingGuideStatusPrefix = 'Error saving guide status:';

  static const String uploadFloorPlan = 'A floor plan provides the spatial layout for your audio system. Tap here to upload a floor plan image';
  static const String configureAcousticSettings =
      'Acoustics mode lets you design your audio layout by defining listening areas and speaker placement. Switch to this mode to configure your acoustic settings';
  static const String drawListeningArea =
      'Listening areas define where people will be positioned to hear audio. Draw listening areas on the canvas using this drawing tool';
  static const String addAcousticZones = 'Acoustic zones group listening areas with similar audio requirements. Add acoustic zones to organize your layout';
  static const String selectSpeakersTool = 'Speakers provide audio coverage to your listening areas. Tap here to add speakers to the layout';
  static const String addSpeakers = 'Pick a speaker model and place it on the floor plan';
  static const String selectListeningArea =
      'Each listening area can be configured individually for optimal audio experience. Select a listening area to configure it';

  static const String myProjects = 'Tap here to create a new project';
  static const String showFloorPickCalibration =
      'Calibration ensures accurate measurements and distances in your floor plan. Draw two reference points to calibrate your floor plan';
  static const String confirmFloorCalibrated = 'Confirm your floor plan calibration to proceed';
  static const String acousticMode = 'Acoustics mode focuses on audio design and speaker placement';
  static const String systemMode = 'Switch to System mode to configure other hardware components like sources, endpoints, and more';
  static const String systemModeTabs = 'Tap here to add a source';
  static const String addZone = 'A zone is where the same audio is played. Tap here to add a new zone';
  static const String showListeningAreaSelectionArea = 'Zones need listening areas to define where audio will be heard. Choose listening areas for this zone';
  static const String confirmSelectListeningArea = 'Confirm your selected listening areas';
}

enum GuideShowCaseSteps {
  myProjects,
  uploadFloorPlan,
  showFloorPickCalibration,
  confirmFloorCalibrated,
  acousticMode,
  drawListeningArea,
  selectSpeakersTool,
  addSpeakers,
  systemMode,
  systemModeTabs,
  addZone,
  selectListeningArea,
  showListeningAreaSelectionArea,
  confirmSelectListeningArea,
}

class GuideShowCaseController extends Cubit<GuideShowCaseState> {
  final BuildContext context;

  GuideShowCaseController(this.context) : super(GuideShowCaseState.initial()) {
    // _initialize();
  }

  bool shouldShowStep(GuideShowCaseSteps step) {
    return false;
    // if (state.isGuideCompleted) return false;
    // return state.currentStep == step && !state.completedSteps.contains(step);
  }

  Future<void> guideNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear saved state
    await prefs.remove(GuideShowCaseControllerTexts.storageKey);

    emit(
      state.copyWith(
        completedSteps: {},
        isGuideCompleted: false,
        currentStep: null,
      ),
    );

    final nextStep = _findNextStep({});
    emit(state.copyWith(currentStep: nextStep));
    // Notify UI (Cubit emit handles reactivity)
  }

  bool isStepCompleted(GuideShowCaseSteps step) => state.completedSteps.contains(step);

  Future<void> completeStep(GuideShowCaseSteps step) async {
    if (state.isGuideCompleted) return;

    // Ignore if null or already completed
    if (state.completedSteps.contains(step)) return;

    final updated = Set<GuideShowCaseSteps>.from(state.completedSteps)..add(step);

    // If last step reached → mark completed
    if (step == GuideShowCaseSteps.values.last) {
      await _saveGuideStatus();
      // ignore: use_build_context_synchronously
      GuideShowcaseWrapper.showGuideCompletedDialog(context);

      emit(
        state.copyWith(
          completedSteps: updated,
          isGuideCompleted: true,
          currentStep: null,
        ),
      );
      return;
    }

    // Move to next step automatically (optional)
    final nextStep = _findNextStep(updated);

    emit(
      state.copyWith(
        completedSteps: updated,
        currentStep: nextStep,
      ),
    );
  }

  /// Skip the entire guide
  Future<void> endGuide() async {
    final allSteps = Set<GuideShowCaseSteps>.from(GuideShowCaseSteps.values);
    await _saveGuideStatus();
    emit(
      state.copyWith(
        completedSteps: allSteps,
        isGuideCompleted: true,
        currentStep: null,
      ),
    );
  }

  Future<void> _initialize() async {
    await _loadGuideStatus();

    if (state.isGuideCompleted) {
      emit(
        state.copyWith(
          currentStep: null,
          isInitialized: true,
        ),
      );
    } else {
      final nextStep = _findNextStep(state.completedSteps);
      emit(
        state.copyWith(
          currentStep: nextStep,
          isInitialized: true,
        ),
      );
    }
  }

  Future<void> _loadGuideStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(GuideShowCaseControllerTexts.storageKey) ?? false;
      emit(state.copyWith(isGuideCompleted: isCompleted));
    } catch (e) {
      log('${GuideShowCaseControllerTexts.errorLoadingGuideStatusPrefix} $e');
    }
  }

  Future<void> _saveGuideStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GuideShowCaseControllerTexts.storageKey, true);
    } catch (e) {
      log('${GuideShowCaseControllerTexts.errorSavingGuideStatusPrefix} $e');
    }
  }

  GuideShowCaseSteps? _findNextStep(Set<GuideShowCaseSteps> completed) {
    for (final step in GuideShowCaseSteps.values) {
      if (!completed.contains(step)) return step;
    }
    return null;
  }
}

/// --- STATE CLASS ---
class GuideShowCaseState {
  final GuideShowCaseSteps? currentStep;
  final bool isInitialized;
  final bool isGuideCompleted;
  final Set<GuideShowCaseSteps> completedSteps;

  const GuideShowCaseState({
    required this.currentStep,
    required this.isInitialized,
    required this.isGuideCompleted,
    required this.completedSteps,
  });

  factory GuideShowCaseState.initial() => const GuideShowCaseState(
    currentStep: null,
    isInitialized: false,
    isGuideCompleted: false,
    completedSteps: {},
  );

  GuideShowCaseState copyWith({
    GuideShowCaseSteps? currentStep,
    bool? isInitialized,
    bool? isGuideCompleted,
    Set<GuideShowCaseSteps>? completedSteps,
  }) {
    return GuideShowCaseState(
      currentStep: currentStep ?? this.currentStep,
      isInitialized: isInitialized ?? this.isInitialized,
      isGuideCompleted: isGuideCompleted ?? this.isGuideCompleted,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

/// Extension to get user-friendly names for steps
extension GuideShowCaseStepsExtension on GuideShowCaseSteps {
  String get description {
    switch (this) {
      case GuideShowCaseSteps.myProjects:
        return GuideShowCaseControllerTexts.myProjects;
      case GuideShowCaseSteps.uploadFloorPlan:
        return GuideShowCaseControllerTexts.uploadFloorPlan;
      case GuideShowCaseSteps.showFloorPickCalibration:
        return GuideShowCaseControllerTexts.showFloorPickCalibration;
      case GuideShowCaseSteps.confirmFloorCalibrated:
        return GuideShowCaseControllerTexts.confirmFloorCalibrated;
      case GuideShowCaseSteps.acousticMode:
        return GuideShowCaseControllerTexts.acousticMode;
      case GuideShowCaseSteps.drawListeningArea:
        return GuideShowCaseControllerTexts.drawListeningArea;
      case GuideShowCaseSteps.selectSpeakersTool:
        return GuideShowCaseControllerTexts.selectSpeakersTool;
      case GuideShowCaseSteps.addSpeakers:
        return GuideShowCaseControllerTexts.addSpeakers;
      case GuideShowCaseSteps.systemMode:
        return GuideShowCaseControllerTexts.systemMode;
      case GuideShowCaseSteps.systemModeTabs:
        return GuideShowCaseControllerTexts.systemModeTabs;
      case GuideShowCaseSteps.addZone:
        return GuideShowCaseControllerTexts.addZone;
      case GuideShowCaseSteps.selectListeningArea:
        return GuideShowCaseControllerTexts.selectListeningArea;
      case GuideShowCaseSteps.showListeningAreaSelectionArea:
        return GuideShowCaseControllerTexts.showListeningAreaSelectionArea;
      case GuideShowCaseSteps.confirmSelectListeningArea:
        return GuideShowCaseControllerTexts.confirmSelectListeningArea;
    }
  }
}
